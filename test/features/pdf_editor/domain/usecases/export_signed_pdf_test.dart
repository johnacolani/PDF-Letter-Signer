import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdf_letter_signer/features/pdf_editor/domain/entities/signature_placement.dart';
import 'package:pdf_letter_signer/features/pdf_editor/domain/repositories/pdf_editor_repository.dart';
import 'package:pdf_letter_signer/features/pdf_editor/domain/usecases/export_signed_pdf.dart';

class MockPdfEditorRepository extends Mock implements PdfEditorRepository {}

void main() {
  late MockPdfEditorRepository repository;
  late ExportSignedPdf usecase;

  setUp(() {
    repository = MockPdfEditorRepository();
    usecase = ExportSignedPdf(repository);
  });

  test('delegates export to the repository', () async {
    final source = Uint8List.fromList([1, 2, 3]);
    final output = Uint8List.fromList([4, 5, 6]);
    final placement = SignaturePlacement(
      pageIndex: 0,
      x: .2,
      y: .3,
      width: .25,
      height: .1,
      pngBytes: Uint8List.fromList([7]),
    );

    when(() => repository.exportSignedPdf(
          sourcePdf: source,
          placement: placement,
        )).thenAnswer((_) async => output);

    final result = await usecase(sourcePdf: source, placement: placement);

    expect(result, output);
    verify(() => repository.exportSignedPdf(
          sourcePdf: source,
          placement: placement,
        )).called(1);
  });
}
