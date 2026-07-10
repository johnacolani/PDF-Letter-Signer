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
import 'package:pdf_letter_signer/features/signature/presentation/bloc/signature_cubit.dart';
import 'package:pdf_letter_signer/features/signature/presentation/widgets/signature_dialog.dart';
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
  double _loadingProgress = 0.05;
  bool _isDocumentLoading = true;
  bool _isUpdatingSubdivisions = false;
  bool _isAutosaving = false;
  DateTime? _lastAutosavedAt;
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
    _loadingProgress = 0.05;
    _isDocumentLoading = true;
    _loadingTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (!mounted || !_isDocumentLoading || _loadingProgress >= 0.90) return;
      setState(() {
        final remaining = 0.90 - _loadingProgress;
        _loadingProgress += remaining.clamp(0.01, 0.06);
      });
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
    setState(() => _loadingProgress = 1);
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _isDocumentLoading = false);
    });
  }

  void _onDocumentLoadFailed(PdfDocumentLoadFailedDetails details) {
    _loadingTimer?.cancel();
    if (!mounted) return;
    setState(() => _isDocumentLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Unable to open PDF: ${details.description}')),
    );
  }

  void _changeZoom(double amount) {
    final nextZoom = (_viewerController.zoomLevel + amount).clamp(1.0, 3.0);
    _viewerController.zoomLevel = nextZoom;
    setState(() {});
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
    setState(_startLoadingProgress);
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
      setState(() {
        _viewerBytes = updatedBytes;
        _viewerRevision++;
      });
    } catch (error) {
      if (!mounted) return;
      _loadingTimer?.cancel();
      setState(() => _isDocumentLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load provinces: $error')),
      );
    } finally {
      _isUpdatingSubdivisions = false;
    }
  }

  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(milliseconds: 900), _performAutosave);
  }

  Future<void> _performAutosave() async {
    if (!mounted) return;
    if (_isUpdatingSubdivisions || _isDocumentLoading) {
      _scheduleAutosave();
      return;
    }

    final state = context.read<PdfEditorBloc>().state;
    if (state is! PdfEditorReady || state.document.path == null) return;
    setState(() => _isAutosaving = true);
    try {
      final bytes = Uint8List.fromList(await _viewerController.saveDocument());
      await autosavePdfBytes(bytes: bytes, sourcePath: state.document.path);
      if (mounted) setState(() => _lastAutosavedAt = DateTime.now());
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Autosave failed: $error')));
      }
    } finally {
      if (mounted) setState(() => _isAutosaving = false);
    }
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
    final savedViewerBytes = Uint8List.fromList(
      await _viewerController.saveDocument(),
    );
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

  Future<ui.Image?> _renderThumbnail(int pageNumber) async {
    final renderer = await _thumbnailRenderer!;
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
    return completer.future;
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
          pageIndex: state.currentPageIndex,
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
          _saveExport(state);
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
        _thumbnailRenderer ??= PdfThumbnailRenderer.open(
          _viewerBytes ?? state.document.bytes,
        );
        return Scaffold(
          appBar: AppBar(
            title: Text(state.document.name),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Tooltip(
                  message:
                      _isAutosaving
                          ? 'Autosaving changes'
                          : _lastAutosavedAt == null
                          ? 'Changes autosave after typing'
                          : 'Changes autosaved',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isAutosaving)
                        const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(
                          _lastAutosavedAt == null
                              ? Icons.cloud_queue_outlined
                              : Icons.cloud_done_outlined,
                          size: 20,
                        ),
                      const SizedBox(width: 5),
                      Text(_isAutosaving ? 'Saving' : 'Autosave'),
                    ],
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
                                final selected =
                                    pageNumber == state.currentPageIndex + 1;
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
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            boxShadow: const [
                                              BoxShadow(
                                                blurRadius: 3,
                                                color: Color(0x22000000),
                                                offset: Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                          child: FutureBuilder<ui.Image?>(
                                            future: _thumbnailCache.putIfAbsent(
                                              pageNumber,
                                              () =>
                                                  _renderThumbnail(pageNumber),
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
                                                  Icons.broken_image_outlined,
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
                      SfPdfViewer.memory(
                        _viewerBytes ?? state.document.bytes,
                        key: ValueKey(_viewerRevision),
                        controller: _viewerController,
                        canShowScrollHead: true,
                        canShowPaginationDialog: true,
                        pageLayoutMode: _pageLayoutMode,
                        onDocumentLoaded: _onDocumentLoaded,
                        onDocumentLoadFailed: _onDocumentLoadFailed,
                        onFormFieldValueChanged: _onFormFieldValueChanged,
                        onTap: (details) {
                          _placeSignaturePrecisely(details, signature);
                        },
                        onPageChanged: (details) {
                          context.read<PdfEditorBloc>().add(
                            PdfEditorPageChanged(details.newPageNumber - 1),
                          );
                        },
                      ),
                      if (signature != null &&
                          signature.pageIndex == state.currentPageIndex)
                        DraggableSignatureOverlay(
                          placement: signature,
                          onChanged: (x, y, width, height) {
                            context.read<PdfEditorBloc>().add(
                              PdfEditorSignatureTransformed(
                                pageIndex: signature.pageIndex,
                                x: x,
                                y: y,
                                width: width,
                                height: height,
                              ),
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
                      if (_isDocumentLoading)
                        ColoredBox(
                          color: Theme.of(
                            context,
                          ).colorScheme.surface.withValues(alpha: 0.92),
                          child: Center(
                            child: Semantics(
                              label: 'Opening PDF',
                              value:
                                  '${(_loadingProgress * 100).round()} percent',
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox.square(
                                    dimension: 72,
                                    child: CircularProgressIndicator(
                                      value: _loadingProgress,
                                      strokeWidth: 7,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    'Opening PDF',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${(_loadingProgress * 100).round()}%',
                                    style:
                                        Theme.of(
                                          context,
                                        ).textTheme.headlineSmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
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
                          Text('Page ${state.currentPageIndex + 1}'),
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
