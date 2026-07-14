import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdf_letter_signer/features/document_picker/domain/document_source_picker.dart';
import 'package:pdf_letter_signer/features/pdf_editor/domain/entities/signature_placement.dart';
import 'package:pdf_letter_signer/features/pdf_editor/domain/repositories/pdf_editor_repository.dart';
import 'package:pdf_letter_signer/features/pdf_editor/domain/usecases/export_signed_pdf.dart';
import 'package:pdf_letter_signer/features/pdf_editor/presentation/bloc/pdf_editor_bloc.dart';

class _MockPdfEditorRepository extends Mock implements PdfEditorRepository {}

void main() {
  late PdfEditorBloc bloc;
  late PickedPdfDocument document;
  late SignaturePlacement placement;

  setUp(() {
    bloc = PdfEditorBloc(ExportSignedPdf(_MockPdfEditorRepository()));
    document = PickedPdfDocument(
      name: 'form.pdf',
      bytes: Uint8List.fromList([1, 2, 3]),
    );
    placement = SignaturePlacement(
      pageIndex: 0,
      x: 0.2,
      y: 0.3,
      width: 0.25,
      height: 0.1,
      pngBytes: Uint8List.fromList([4]),
    );
  });

  tearDown(() => bloc.close());

  blocTest<PdfEditorBloc, PdfEditorState>(
    'does not emit for an unchanged page index',
    build: () => bloc,
    act:
        (bloc) =>
            bloc
              ..add(PdfEditorDocumentOpened(document))
              ..add(const PdfEditorPageChanged(0)),
    expect: () => [PdfEditorReady(document: document)],
  );

  blocTest<PdfEditorBloc, PdfEditorState>(
    'does not emit for an unchanged committed signature transform',
    build: () => bloc,
    act:
        (bloc) =>
            bloc
              ..add(PdfEditorDocumentOpened(document))
              ..add(PdfEditorSignaturePlaced(placement))
              ..add(
                PdfEditorSignatureTransformed(
                  pageIndex: placement.pageIndex,
                  x: placement.x,
                  y: placement.y,
                  width: placement.width,
                  height: placement.height,
                ),
              ),
    expect:
        () => [
          PdfEditorReady(document: document),
          PdfEditorReady(document: document, signature: placement),
        ],
  );
}
