import 'dart:typed_data';

import 'package:pdf_letter_signer/features/pdf_editor/domain/entities/signature_placement.dart';

abstract interface class PdfEditorRepository {
  Future<Uint8List> exportSignedPdf({
    required Uint8List sourcePdf,
    SignaturePlacement? placement,
  });
}
