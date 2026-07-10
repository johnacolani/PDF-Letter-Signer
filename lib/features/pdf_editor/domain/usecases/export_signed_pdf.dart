import 'dart:typed_data';

import 'package:pdf_letter_signer/features/pdf_editor/domain/entities/signature_placement.dart';
import 'package:pdf_letter_signer/features/pdf_editor/domain/repositories/pdf_editor_repository.dart';

class ExportSignedPdf {
  const ExportSignedPdf(this._repository);

  final PdfEditorRepository _repository;

  Future<Uint8List> call({
    required Uint8List sourcePdf,
    required SignaturePlacement placement,
  }) {
    return _repository.exportSignedPdf(
      sourcePdf: sourcePdf,
      placement: placement,
    );
  }
}
