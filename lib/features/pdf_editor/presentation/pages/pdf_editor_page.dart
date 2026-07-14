import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf_letter_signer/core/design_system/app_colors.dart';
import 'package:pdf_letter_signer/core/location/country_subdivision_service.dart';
import 'package:pdf_letter_signer/core/pdf/pdf_thumbnail_renderer.dart';
import 'package:pdf_letter_signer/core/utils/autosave_pdf_helper.dart';
import 'package:pdf_letter_signer/core/utils/save_pdf_helper.dart';
import 'package:pdf_letter_signer/features/document_picker/domain/document_source_picker.dart';
import 'package:pdf_letter_signer/features/pdf_editor/domain/entities/signature_placement.dart';
import 'package:pdf_letter_signer/features/pdf_editor/presentation/bloc/pdf_editor_bloc.dart';
import 'package:pdf_letter_signer/features/pdf_editor/presentation/widgets/draggable_signature_overlay.dart';
import 'package:pdf_letter_signer/features/pdf_editor/presentation/widgets/pdf_viewer_section.dart';
import 'package:pdf_letter_signer/features/signature/presentation/bloc/signature_cubit.dart';
import 'package:pdf_letter_signer/features/signature/presentation/widgets/signature_dialog.dart';
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfEditorPage extends StatefulWidget {
  const PdfEditorPage({super.key});

  @override
  State<PdfEditorPage> createState() => _PdfEditorPageState();
}

class _PdfEditorPageState extends State<PdfEditorPage> {
  final PdfViewerController _viewerController = PdfViewerController();
  final CountrySubdivisionService _subdivisionService =
      CountrySubdivisionService();
  Timer? _loadingTimer;
  Timer? _autosaveTimer;
  Uint8List? _viewerBytes;
  Future<PdfThumbnailRenderer>? _thumbnailRenderer;
  final Map<int, Future<ui.Image?>> _thumbnailCache = {};
  int _viewerRevision = 0;
  final ValueNotifier<double?> _loadingProgress = ValueNotifier(0.05);
  final ValueNotifier<int> _currentPageIndex = ValueNotifier(0);
  final ValueNotifier<_AutosaveStatus> _autosaveStatus = ValueNotifier(
    const _AutosaveStatus(),
  );
  bool _isUpdatingSubdivisions = false;
  bool _autosaveInProgress = false;
  bool _autosavePending = false;
  bool _showPageNavigator = false;
  bool _isPrecisePlacementMode = false;
  PdfPageLayoutMode _pageLayoutMode = PdfPageLayoutMode.continuous;
  final List<Size> _pdfPageSizes = [];
  String? _lastBirthCountry;

  @override
  void initState() {
    super.initState();
    _startLoadingProgress();
  }

  void _startLoadingProgress() {
    _loadingTimer?.cancel();
    _loadingProgress.value = 0.05;
    _loadingTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      final progress = _loadingProgress.value;
      if (!mounted || progress == null || progress >= 0.90) return;
      final remaining = 0.90 - progress;
      _loadingProgress.value = progress + remaining.clamp(0.01, 0.06);
    });
  }

  void _onDocumentLoaded(PdfDocumentLoadedDetails details) {
    _loadingTimer?.cancel();
    if (!mounted) return;
    _pdfPageSizes
      ..clear()
      ..addAll(
        List<Size>.generate(
          details.document.pages.count,
          (index) => details.document.pages[index].getClientSize(),
        ),
      );
    _loadingProgress.value = 1;
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _loadingProgress.value = null;
    });
  }

  void _onDocumentLoadFailed(PdfDocumentLoadFailedDetails details) {
    _loadingTimer?.cancel();
    if (!mounted) return;
    _loadingProgress.value = null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Unable to open PDF: ${details.description}')),
    );
  }

  void _changeZoom(double amount) {
    final nextZoom = (_viewerController.zoomLevel + amount).clamp(1.0, 3.0);
    _viewerController.zoomLevel = nextZoom;
  }

  void _fitOnePage() {
    final page = _viewerController.pageNumber;
    setState(() => _pageLayoutMode = PdfPageLayoutMode.single);
    _viewerController.zoomLevel = 1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && page > 0) _viewerController.jumpToPage(page);
    });
  }

  void _showContinuousPages() {
    final page = _viewerController.pageNumber;
    setState(() => _pageLayoutMode = PdfPageLayoutMode.continuous);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && page > 0) _viewerController.jumpToPage(page);
    });
  }

  void _placeSignaturePrecisely(
    PdfGestureDetails details,
    SignaturePlacement? signature,
  ) {
    if (!_isPrecisePlacementMode ||
        signature == null ||
        details.pageNumber < 1 ||
        details.pageNumber > _pdfPageSizes.length) {
      return;
    }
    final pageIndex = details.pageNumber - 1;
    final pageSize = _pdfPageSizes[pageIndex];
    final x = (details.pagePosition.dx / pageSize.width - signature.width / 2)
        .clamp(0.0, 1.0 - signature.width);
    final y = (details.pagePosition.dy / pageSize.height - signature.height / 2)
        .clamp(0.0, 1.0 - signature.height);
    context.read<PdfEditorBloc>().add(
      PdfEditorSignatureTransformed(
        pageIndex: pageIndex,
        x: x,
        y: y,
        width: signature.width,
        height: signature.height,
      ),
    );
    setState(() => _isPrecisePlacementMode = false);
  }

  Future<void> _onFormFieldValueChanged(
    PdfFormFieldValueChangedDetails details,
  ) async {
    _scheduleAutosave();
    if (details.formField.name != 'birthCountry[0]' ||
        _isUpdatingSubdivisions) {
      return;
    }
    final country = details.newValue?.toString().trim() ?? '';
    if (country.isEmpty || country == _lastBirthCountry) return;

    _lastBirthCountry = country;
    _isUpdatingSubdivisions = true;
    _startLoadingProgress();
    try {
      final currentBytes = Uint8List.fromList(
        await _viewerController.saveDocument(),
      );
      final subdivisions = await _subdivisionService.subdivisionsFor(country);
      final updatedBytes = await _replaceBirthSubdivisionOptions(
        currentBytes,
        subdivisions,
      );
      if (!mounted) return;

      final current = context.read<PdfEditorBloc>().state;
      await _replaceViewerDocument(updatedBytes);
      if (!mounted) return;
      if (current is PdfEditorReady) {
        context.read<PdfEditorBloc>().add(
          PdfEditorDocumentUpdated(
            PickedPdfDocument(
              name: current.document.name,
              bytes: updatedBytes,
              path: current.document.path,
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      _loadingTimer?.cancel();
      _loadingProgress.value = null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load provinces: $error')),
      );
    } finally {
      _isUpdatingSubdivisions = false;
    }
  }

  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    if (_autosaveInProgress) _autosavePending = true;
    _autosaveStatus.value = _autosaveStatus.value.copyWith(hasChanges: true);
    _autosaveTimer = Timer(const Duration(seconds: 4), _performAutosave);
  }

  Future<void> _performAutosave({bool force = false}) async {
    if (!mounted) return;
    if (_autosaveInProgress) {
      _autosavePending = true;
      return;
    }
    if (!force && (_isUpdatingSubdivisions || _loadingProgress.value != null)) {
      _scheduleAutosave();
      return;
    }

    final state = context.read<PdfEditorBloc>().state;
    if (state is! PdfEditorReady || state.document.path == null) return;
    _autosaveInProgress = true;
    _autosavePending = false;
    _autosaveStatus.value = _autosaveStatus.value.copyWith(isSaving: true);
    final stopwatch = Stopwatch()..start();
    try {
      final bytes = Uint8List.fromList(await _viewerController.saveDocument());
      await autosavePdfBytes(bytes: bytes, sourcePath: state.document.path);
      if (mounted) {
        _autosaveStatus.value = _AutosaveStatus(lastSavedAt: DateTime.now());
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Autosave failed: $error')));
      }
    } finally {
      stopwatch.stop();
      assert(() {
        debugPrint('Autosave completed in ${stopwatch.elapsedMilliseconds} ms');
        return true;
      }());
      _autosaveInProgress = false;
      if (mounted && _autosaveStatus.value.isSaving) {
        _autosaveStatus.value = _autosaveStatus.value.copyWith(isSaving: false);
      }
      if (_autosavePending && mounted) {
        _autosavePending = false;
        _scheduleAutosave();
      }
    }
  }

  Future<void> _replaceViewerDocument(Uint8List bytes) async {
    final oldRenderer = _thumbnailRenderer;
    _thumbnailRenderer = null;
    final oldImages = _thumbnailCache.values.toList(growable: false);
    _thumbnailCache.clear();
    if (oldRenderer != null) {
      oldRenderer.then((renderer) => renderer.close());
    }
    for (final image in oldImages) {
      image.then((value) => value?.dispose());
    }
    if (!mounted) return;
    setState(() {
      _viewerBytes = bytes;
      _viewerRevision++;
    });
  }

  Future<Uint8List> _replaceBirthSubdivisionOptions(
    Uint8List bytes,
    List<String> subdivisions,
  ) async {
    final document = PdfDocument(inputBytes: bytes);
    try {
      final fields = document.form.fields;
      for (var index = 0; index < fields.count; index++) {
        final field = fields[index];
        if (field.name != 'birthState[0]' || field is! PdfComboBoxField) {
          continue;
        }
        field.items.clear();
        final options =
            subdivisions.isEmpty ? const ['Not applicable'] : subdivisions;
        for (final option in options) {
          field.items.add(PdfListFieldItem(option, option));
        }
        field.selectedIndex = -1;
        break;
      }
      return Uint8List.fromList(await document.save());
    } finally {
      document.dispose();
    }
  }

  Future<void> _requestExport(PdfEditorReady state) async {
    _autosaveTimer?.cancel();
    final savedViewerBytes = Uint8List.fromList(
      await _viewerController.saveDocument(),
    );
    if (state.document.path != null) {
      await autosavePdfBytes(
        bytes: savedViewerBytes,
        sourcePath: state.document.path,
      );
    }
    if (!mounted) return;
    context.read<PdfEditorBloc>()
      ..add(
        PdfEditorDocumentUpdated(
          PickedPdfDocument(
            name: state.document.name,
            bytes: savedViewerBytes,
            path: state.document.path,
          ),
        ),
      )
      ..add(const PdfEditorExportRequested());
  }

  Future<void> _requestPrint(PdfEditorReady state) async {
    _autosaveTimer?.cancel();
    final currentBytes = Uint8List.fromList(
      await _viewerController.saveDocument(),
    );
    if (state.document.path != null) {
      await autosavePdfBytes(
        bytes: currentBytes,
        sourcePath: state.document.path,
      );
    }
    if (!mounted) return;
    context.read<PdfEditorBloc>()
      ..add(
        PdfEditorDocumentUpdated(
          PickedPdfDocument(
            name: state.document.name,
            bytes: currentBytes,
            path: state.document.path,
          ),
        ),
      )
      ..add(const PdfEditorPrintRequested());
  }

  Future<ui.Image?> _renderThumbnail(int pageNumber) async {
    final state = context.read<PdfEditorBloc>().state;
    if (state is! PdfEditorReady) return null;
    final rendererFuture =
        _thumbnailRenderer ??= PdfThumbnailRenderer.open(
          _viewerBytes ?? state.document.bytes,
        );
    final stopwatch = Stopwatch()..start();
    final renderer = await rendererFuture;
    final thumbnail = await renderer.render(pageNumber);
    if (thumbnail == null) return null;

    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      thumbnail.pixels,
      thumbnail.width,
      thumbnail.height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    final image = await completer.future;
    stopwatch.stop();
    assert(() {
      debugPrint(
        'Thumbnail $pageNumber rendered in '
        '${stopwatch.elapsedMilliseconds} ms',
      );
      return true;
    }());
    return image;
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _autosaveTimer?.cancel();
    final thumbnailRenderer = _thumbnailRenderer;
    if (thumbnailRenderer != null) {
      thumbnailRenderer.then((renderer) => renderer.close());
    }
    for (final imageFuture in _thumbnailCache.values) {
      imageFuture.then((image) => image?.dispose());
    }
    _viewerController.dispose();
    _loadingProgress.dispose();
    _currentPageIndex.dispose();
    _autosaveStatus.dispose();
    super.dispose();
  }

  Future<void> _drawSignature(PdfEditorReady state) async {
    final bytes = await showDialog<Uint8List>(
      context: context,
      builder: (_) => const SignatureDialog(),
    );
    if (bytes == null || !mounted) return;

    context.read<SignatureCubit>().save(bytes);
    context.read<PdfEditorBloc>().add(
      PdfEditorSignaturePlaced(
        SignaturePlacement(
          pageIndex: _currentPageIndex.value,
          x: 0.58,
          y: 0.70,
          width: 0.30,
          height: 0.10,
          pngBytes: bytes,
        ),
      ),
    );
  }

  Future<void> _saveExport(PdfEditorReady state) async {
    final bytes = state.exportedBytes;
    if (bytes == null) return;
    final original =
        state.document.name.toLowerCase().endsWith('.pdf')
            ? state.document.name.substring(0, state.document.name.length - 4)
            : state.document.name;
    final saved = await savePdfBytes(
      bytes: bytes,
      suggestedName: '${original}_signed.pdf',
    );
    if (!mounted) return;
    context.read<PdfEditorBloc>().add(const PdfEditorExportConsumed());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(saved ? 'Signed PDF saved.' : 'Save cancelled.')),
    );
  }

  Future<void> _printExport(PdfEditorReady state) async {
    final bytes = state.exportedBytes;
    if (bytes == null) return;
    try {
      await Printing.layoutPdf(
        name: state.document.name,
        dynamicLayout: false,
        windowsModernDialog: true,
        onLayout: (_) async => bytes,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Printing failed: $error')));
      }
    } finally {
      if (mounted) {
        context.read<PdfEditorBloc>().add(const PdfEditorExportConsumed());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PdfEditorBloc, PdfEditorState>(
      listenWhen: (previous, current) {
        if (current is! PdfEditorReady) return false;
        final previousReady = previous is PdfEditorReady ? previous : null;
        return (current.exportedBytes != null &&
                current.exportedBytes != previousReady?.exportedBytes) ||
            (current.errorMessage != null &&
                current.errorMessage != previousReady?.errorMessage);
      },
      listener: (context, state) {
        if (state case PdfEditorReady(
          exportedBytes: final bytes?,
        ) when bytes.isNotEmpty) {
          if (state.outputAction == PdfEditorOutputAction.print) {
            _printExport(state);
          } else {
            _saveExport(state);
          }
        } else if (state case PdfEditorReady(errorMessage: final message?)) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      },
      builder: (context, state) {
        if (state is! PdfEditorReady) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final signature = state.signature;
        return Scaffold(
          appBar: AppBar(
            title: Text(state.document.name),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: ValueListenableBuilder<_AutosaveStatus>(
                  valueListenable: _autosaveStatus,
                  builder:
                      (context, status, _) => Tooltip(
                        message:
                            status.isSaving
                                ? 'Autosaving changes'
                                : status.hasChanges
                                ? 'Changes autosave after typing'
                                : status.lastSavedAt == null
                                ? 'Changes autosave after typing'
                                : 'Changes autosaved',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (status.isSaving)
                              const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            else
                              Icon(
                                status.lastSavedAt == null
                                    ? Icons.cloud_queue_outlined
                                    : Icons.cloud_done_outlined,
                                size: 20,
                              ),
                            const SizedBox(width: 5),
                            Text(status.isSaving ? 'Saving' : 'Autosave'),
                          ],
                        ),
                      ),
                ),
              ),
              IconButton(
                tooltip: 'Zoom out',
                onPressed: () => _changeZoom(-0.25),
                icon: const Icon(Icons.zoom_out),
              ),
              IconButton(
                tooltip: 'Zoom in',
                onPressed: () => _changeZoom(0.25),
                icon: const Icon(Icons.zoom_in),
              ),
              IconButton(
                tooltip:
                    _showPageNavigator ? 'Hide all pages' : 'Show all pages',
                onPressed: () {
                  setState(() => _showPageNavigator = !_showPageNavigator);
                },
                icon: Icon(
                  _showPageNavigator
                      ? Icons.view_sidebar
                      : Icons.view_sidebar_outlined,
                ),
              ),
              IconButton(
                tooltip:
                    _pageLayoutMode == PdfPageLayoutMode.single
                        ? 'Show continuous pages'
                        : 'Fit one page',
                onPressed:
                    _pageLayoutMode == PdfPageLayoutMode.single
                        ? _showContinuousPages
                        : _fitOnePage,
                icon: Icon(
                  _pageLayoutMode == PdfPageLayoutMode.single
                      ? Icons.view_stream_outlined
                      : Icons.fit_screen_outlined,
                ),
              ),
              IconButton(
                tooltip: 'Draw signature',
                onPressed: () => _drawSignature(state),
                icon: const Icon(Icons.draw_outlined),
              ),
              if (signature != null)
                IconButton(
                  tooltip:
                      _isPrecisePlacementMode
                          ? 'Cancel precise placement'
                          : 'Place signature precisely',
                  onPressed: () {
                    setState(() {
                      _isPrecisePlacementMode = !_isPrecisePlacementMode;
                    });
                  },
                  icon: Icon(
                    _isPrecisePlacementMode
                        ? Icons.location_disabled_outlined
                        : Icons.my_location,
                  ),
                ),
              IconButton(
                tooltip: 'Print document',
                onPressed:
                    state.isExporting ? null : () => _requestPrint(state),
                icon: const Icon(Icons.print_outlined),
              ),
              const SizedBox(width: 4),
              FilledButton.icon(
                onPressed:
                    signature == null || state.isExporting
                        ? null
                        : () => _requestExport(state),
                icon:
                    state.isExporting
                        ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.save_outlined),
                label: const Text('Export'),
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: ColoredBox(
            color: AppColors.canvas,
            child: Row(
              children: [
                if (MediaQuery.sizeOf(context).width >= 900)
                  NavigationRail(
                    selectedIndex: 0,
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.description_outlined),
                        selectedIcon: Icon(Icons.description),
                        label: Text('Document'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.draw_outlined),
                        selectedIcon: Icon(Icons.draw),
                        label: Text('Sign'),
                      ),
                    ],
                  ),
                if (_showPageNavigator)
                  SizedBox(
                    width: 174,
                    child: Material(
                      color: Theme.of(context).colorScheme.surface,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'All pages',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Close pages',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () {
                                    setState(() => _showPageNavigator = false);
                                  },
                                  icon: const Icon(Icons.close, size: 18),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _viewerController.pageCount,
                              itemBuilder: (context, index) {
                                final pageNumber = index + 1;
                                return ValueListenableBuilder<int>(
                                  valueListenable: _currentPageIndex,
                                  builder: (context, currentPageIndex, _) {
                                    final selected =
                                        pageNumber == currentPageIndex + 1;
                                    return InkWell(
                                      onTap:
                                          () => _viewerController.jumpToPage(
                                            pageNumber,
                                          ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        child: Column(
                                          children: [
                                            AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 150,
                                              ),
                                              width: 132,
                                              height: 150,
                                              padding: const EdgeInsets.all(3),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                border: Border.all(
                                                  color:
                                                      selected
                                                          ? Theme.of(
                                                            context,
                                                          ).colorScheme.primary
                                                          : Theme.of(context)
                                                              .colorScheme
                                                              .outlineVariant,
                                                  width: selected ? 3 : 1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                boxShadow: const [
                                                  BoxShadow(
                                                    blurRadius: 3,
                                                    color: Color(0x22000000),
                                                    offset: Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                              child: FutureBuilder<ui.Image?>(
                                                future: _thumbnailCache
                                                    .putIfAbsent(
                                                      pageNumber,
                                                      () => _renderThumbnail(
                                                        pageNumber,
                                                      ),
                                                    ),
                                                builder: (context, snapshot) {
                                                  if (snapshot.hasData) {
                                                    return RawImage(
                                                      image: snapshot.data,
                                                      fit: BoxFit.contain,
                                                    );
                                                  }
                                                  if (snapshot.hasError) {
                                                    return const Icon(
                                                      Icons
                                                          .broken_image_outlined,
                                                    );
                                                  }
                                                  return const Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  );
                                                },
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              'Page $pageNumber',
                                              style: TextStyle(
                                                fontWeight:
                                                    selected
                                                        ? FontWeight.w600
                                                        : FontWeight.normal,
                                                color:
                                                    selected
                                                        ? Theme.of(
                                                          context,
                                                        ).colorScheme.primary
                                                        : null,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      PdfViewerSection(
                        bytes: _viewerBytes ?? state.document.bytes,
                        revision: _viewerRevision,
                        controller: _viewerController,
                        pageLayoutMode: _pageLayoutMode,
                        onDocumentLoaded: _onDocumentLoaded,
                        onDocumentLoadFailed: _onDocumentLoadFailed,
                        onFormFieldValueChanged: _onFormFieldValueChanged,
                        onTap: (details) {
                          _placeSignaturePrecisely(details, signature);
                        },
                        onPageChanged: (details) {
                          final nextIndex = details.newPageNumber - 1;
                          if (_currentPageIndex.value != nextIndex) {
                            _currentPageIndex.value = nextIndex;
                          }
                        },
                      ),
                      if (signature != null)
                        ValueListenableBuilder<int>(
                          valueListenable: _currentPageIndex,
                          builder: (context, currentPageIndex, _) {
                            if (signature.pageIndex != currentPageIndex) {
                              return const SizedBox.shrink();
                            }
                            return DraggableSignatureOverlay(
                              placement: signature,
                              onCommitted: (placement) {
                                context.read<PdfEditorBloc>().add(
                                  PdfEditorSignatureTransformed(
                                    pageIndex: placement.pageIndex,
                                    x: placement.x,
                                    y: placement.y,
                                    width: placement.width,
                                    height: placement.height,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      if (_isPrecisePlacementMode)
                        Positioned(
                          top: 16,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Material(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(24),
                              elevation: 4,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                                child: Text(
                                  'Click the exact signature location',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ValueListenableBuilder<double?>(
                        valueListenable: _loadingProgress,
                        builder: (context, progress, _) {
                          if (progress == null) return const SizedBox.shrink();
                          return _LoadingOverlay(progress: progress);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar:
              MediaQuery.sizeOf(context).width < 900
                  ? SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton.icon(
                            onPressed: () => _drawSignature(state),
                            icon: const Icon(Icons.draw),
                            label: const Text('Signature'),
                          ),
                          ValueListenableBuilder<int>(
                            valueListenable: _currentPageIndex,
                            builder:
                                (context, pageIndex, _) =>
                                    Text('Page ${pageIndex + 1}'),
                          ),
                          IconButton(
                            tooltip: 'Print document',
                            onPressed:
                                state.isExporting
                                    ? null
                                    : () => _requestPrint(state),
                            icon: const Icon(Icons.print_outlined),
                          ),
                          TextButton.icon(
                            onPressed:
                                signature == null || state.isExporting
                                    ? null
                                    : () => _requestExport(state),
                            icon: const Icon(Icons.save_outlined),
                            label: const Text('Export'),
                          ),
                        ],
                      ),
                    ),
                  )
                  : null,
        );
      },
    );
  }
}

@immutable
class _AutosaveStatus {
  const _AutosaveStatus({
    this.isSaving = false,
    this.hasChanges = false,
    this.lastSavedAt,
  });

  final bool isSaving;
  final bool hasChanges;
  final DateTime? lastSavedAt;

  _AutosaveStatus copyWith({
    bool? isSaving,
    bool? hasChanges,
    DateTime? lastSavedAt,
  }) {
    return _AutosaveStatus(
      isSaving: isSaving ?? this.isSaving,
      hasChanges: hasChanges ?? this.hasChanges,
      lastSavedAt: lastSavedAt ?? this.lastSavedAt,
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final percentage = (progress * 100).round();
    return RepaintBoundary(
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
        child: Center(
          child: Semantics(
            label: 'Opening PDF',
            value: '$percentage percent',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(
                  dimension: 72,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 7,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Opening PDF',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  '$percentage%',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
