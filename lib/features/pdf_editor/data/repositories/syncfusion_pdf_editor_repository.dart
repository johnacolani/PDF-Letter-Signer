import 'dart:typed_data';
import 'dart:ui';

import 'package:pdf_letter_signer/features/pdf_editor/domain/entities/signature_placement.dart';
import 'package:pdf_letter_signer/features/pdf_editor/domain/repositories/pdf_editor_repository.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class SyncfusionPdfEditorRepository implements PdfEditorRepository {
  @override
  Future<Uint8List> exportSignedPdf({
    required Uint8List sourcePdf,
    required SignaturePlacement placement,
  }) async {
    final document = PdfDocument(inputBytes: sourcePdf);
    try {
      if (placement.pageIndex < 0 || placement.pageIndex >= document.pages.count) {
        throw RangeError('The selected PDF page does not exist.');
      }

      final page = document.pages[placement.pageIndex];
      final pageSize = page.getClientSize();
      final left = placement.x.clamp(0.0, 1.0) * pageSize.width;
      final top = placement.y.clamp(0.0, 1.0) * pageSize.height;
      final width = placement.width.clamp(0.01, 1.0) * pageSize.width;
      final height = placement.height.clamp(0.01, 1.0) * pageSize.height;

      page.graphics.drawImage(
        PdfBitmap(placement.pngBytes),
        Rect.fromLTWH(left, top, width, height),
      );
      return Uint8List.fromList(await document.save());
    } finally {
      document.dispose();
    }
  }
}
