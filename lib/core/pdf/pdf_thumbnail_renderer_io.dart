import 'dart:io';
import 'dart:typed_data';

import 'package:syncfusion_pdfviewer_platform_interface/pdfviewer_platform_interface.dart';
import 'package:uuid/uuid.dart';

class PdfThumbnailRenderer {
  PdfThumbnailRenderer._({
    required String documentId,
    required Directory temporaryDirectory,
    required List<dynamic> pageWidths,
    required List<dynamic> pageHeights,
  }) : _documentId = documentId,
       _temporaryDirectory = temporaryDirectory,
       _pageWidths = pageWidths,
       _pageHeights = pageHeights;

  final String _documentId;
  final Directory _temporaryDirectory;
  final List<dynamic> _pageWidths;
  final List<dynamic> _pageHeights;

  static Future<PdfThumbnailRenderer> open(Uint8List bytes) async {
    final documentId = const Uuid().v4();
    final directory = await Directory.systemTemp.createTemp('pdf_thumbnails_');
    final file = File(
      '${directory.path}${Platform.pathSeparator}$documentId.pdf',
    );
    await file.writeAsBytes(bytes, flush: true);
    await PdfViewerPlatform.instance.loadPdfFromFile(file.path, documentId);
    final widths = await PdfViewerPlatform.instance.getPagesWidth(documentId);
    final heights = await PdfViewerPlatform.instance.getPagesHeight(documentId);
    return PdfThumbnailRenderer._(
      documentId: documentId,
      temporaryDirectory: directory,
      pageWidths: widths ?? const [],
      pageHeights: heights ?? const [],
    );
  }

  Future<PdfThumbnailData?> render(int pageNumber, {int width = 124}) async {
    final index = pageNumber - 1;
    final sourceWidth = (_pageWidths[index] as num).toDouble();
    final sourceHeight = (_pageHeights[index] as num).toDouble();
    final height = (width * sourceHeight / sourceWidth).round();
    final pixels = await PdfViewerPlatform.instance.getPage(
      pageNumber,
      width,
      height,
      _documentId,
    );
    if (pixels == null) return null;
    return PdfThumbnailData(pixels: pixels, width: width, height: height);
  }

  Future<void> close() async {
    await PdfViewerPlatform.instance.closeDocument(_documentId);
    if (await _temporaryDirectory.exists()) {
      await _temporaryDirectory.delete(recursive: true);
    }
  }
}

class PdfThumbnailData {
  const PdfThumbnailData({
    required this.pixels,
    required this.width,
    required this.height,
  });

  final Uint8List pixels;
  final int width;
  final int height;
}
