import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf_letter_signer/core/design_system/app_colors.dart';
import 'package:pdf_letter_signer/core/utils/save_pdf_helper.dart';
import 'package:pdf_letter_signer/features/pdf_editor/domain/entities/signature_placement.dart';
import 'package:pdf_letter_signer/features/pdf_editor/presentation/bloc/pdf_editor_bloc.dart';
import 'package:pdf_letter_signer/features/pdf_editor/presentation/widgets/draggable_signature_overlay.dart';
import 'package:pdf_letter_signer/features/signature/presentation/bloc/signature_cubit.dart';
import 'package:pdf_letter_signer/features/signature/presentation/widgets/signature_dialog.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfEditorPage extends StatefulWidget {
  const PdfEditorPage({super.key});

  @override
  State<PdfEditorPage> createState() => _PdfEditorPageState();
}

class _PdfEditorPageState extends State<PdfEditorPage> {
  final PdfViewerController _viewerController = PdfViewerController();

  @override
  void dispose() {
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
    final original = state.document.name.toLowerCase().endsWith('.pdf')
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
        return current is PdfEditorReady &&
            (current.exportedBytes != null || current.errorMessage != null);
      },
      listener: (context, state) {
        if (state case PdfEditorReady(exportedBytes: final bytes?) when bytes.isNotEmpty) {
          _saveExport(state);
        } else if (state case PdfEditorReady(errorMessage: final message?)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      },
      builder: (context, state) {
        if (state is! PdfEditorReady) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final signature = state.signature;
        return Scaffold(
          appBar: AppBar(
            title: Text(state.document.name),
            actions: [
              IconButton(
                tooltip: 'Draw signature',
                onPressed: () => _drawSignature(state),
                icon: const Icon(Icons.draw_outlined),
              ),
              const SizedBox(width: 4),
              FilledButton.icon(
                onPressed: signature == null || state.isExporting
                    ? null
                    : () => context
                        .read<PdfEditorBloc>()
                        .add(const PdfEditorExportRequested()),
                icon: state.isExporting
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
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      SfPdfViewer.memory(
                        state.document.bytes,
                        controller: _viewerController,
                        canShowScrollHead: true,
                        canShowPaginationDialog: true,
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
                          onMoved: (x, y) {
                            context.read<PdfEditorBloc>().add(
                                  PdfEditorSignatureMoved(x: x, y: y),
                                );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: MediaQuery.sizeOf(context).width < 900
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
                          onPressed: signature == null || state.isExporting
                              ? null
                              : () => context
                                  .read<PdfEditorBloc>()
                                  .add(const PdfEditorExportRequested()),
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
