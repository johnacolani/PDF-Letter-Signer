import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// A stable boundary around Syncfusion's expensive viewer subtree.
///
/// The same [SfPdfViewer] widget instance is retained across unrelated parent
/// rebuilds. It is recreated only when bytes, revision, or layout mode changes.
class PdfViewerSection extends StatefulWidget {
  const PdfViewerSection({
    required this.bytes,
    required this.revision,
    required this.controller,
    required this.pageLayoutMode,
    required this.onDocumentLoaded,
    required this.onDocumentLoadFailed,
    required this.onFormFieldValueChanged,
    required this.onTap,
    required this.onPageChanged,
    super.key,
  });

  final Uint8List bytes;
  final int revision;
  final PdfViewerController controller;
  final PdfPageLayoutMode pageLayoutMode;
  final void Function(PdfDocumentLoadedDetails) onDocumentLoaded;
  final void Function(PdfDocumentLoadFailedDetails) onDocumentLoadFailed;
  final void Function(PdfFormFieldValueChangedDetails) onFormFieldValueChanged;
  final void Function(PdfGestureDetails) onTap;
  final void Function(PdfPageChangedDetails) onPageChanged;

  @override
  State<PdfViewerSection> createState() => _PdfViewerSectionState();
}

class _PdfViewerSectionState extends State<PdfViewerSection> {
  late Widget _viewer;
  int _rebuildCount = 0;

  @override
  void initState() {
    super.initState();
    _viewer = _createViewer();
  }

  @override
  void didUpdateWidget(covariant PdfViewerSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.bytes, widget.bytes) ||
        oldWidget.revision != widget.revision ||
        oldWidget.pageLayoutMode != widget.pageLayoutMode) {
      _viewer = _createViewer();
    }
  }

  Widget _createViewer() {
    assert(() {
      _rebuildCount++;
      debugPrint('PdfViewerSection expensive rebuild #$_rebuildCount');
      return true;
    }());
    return SfPdfViewer.memory(
      widget.bytes,
      key: ValueKey(widget.revision),
      controller: widget.controller,
      canShowScrollHead: true,
      canShowPaginationDialog: true,
      pageLayoutMode: widget.pageLayoutMode,
      onDocumentLoaded: (details) => widget.onDocumentLoaded(details),
      onDocumentLoadFailed: (details) => widget.onDocumentLoadFailed(details),
      onFormFieldValueChanged:
          (details) => widget.onFormFieldValueChanged(details),
      onTap: (details) => widget.onTap(details),
      onPageChanged: (details) => widget.onPageChanged(details),
    );
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(child: _viewer);
}
