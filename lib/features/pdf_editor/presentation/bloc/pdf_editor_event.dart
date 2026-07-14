part of 'pdf_editor_bloc.dart';

sealed class PdfEditorEvent extends Equatable {
  const PdfEditorEvent();
  @override
  List<Object?> get props => [];
}

final class PdfEditorDocumentOpened extends PdfEditorEvent {
  const PdfEditorDocumentOpened(this.document);
  final PickedPdfDocument document;
  @override
  List<Object?> get props => [document];
}

final class PdfEditorDocumentUpdated extends PdfEditorEvent {
  const PdfEditorDocumentUpdated(this.document);
  final PickedPdfDocument document;
  @override
  List<Object?> get props => [document];
}

final class PdfEditorSignaturePlaced extends PdfEditorEvent {
  const PdfEditorSignaturePlaced(this.placement);
  final SignaturePlacement placement;
  @override
  List<Object?> get props => [placement];
}

final class PdfEditorSignatureMoved extends PdfEditorEvent {
  const PdfEditorSignatureMoved({required this.x, required this.y});
  final double x;
  final double y;
  @override
  List<Object?> get props => [x, y];
}

final class PdfEditorSignatureTransformed extends PdfEditorEvent {
  const PdfEditorSignatureTransformed({
    required this.pageIndex,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final int pageIndex;
  final double x;
  final double y;
  final double width;
  final double height;

  @override
  List<Object?> get props => [pageIndex, x, y, width, height];
}

final class PdfEditorPageChanged extends PdfEditorEvent {
  const PdfEditorPageChanged(this.pageIndex);
  final int pageIndex;
  @override
  List<Object?> get props => [pageIndex];
}

final class PdfEditorExportRequested extends PdfEditorEvent {
  const PdfEditorExportRequested();
}

final class PdfEditorPrintRequested extends PdfEditorEvent {
  const PdfEditorPrintRequested();
}

final class PdfEditorExportConsumed extends PdfEditorEvent {
  const PdfEditorExportConsumed();
}
