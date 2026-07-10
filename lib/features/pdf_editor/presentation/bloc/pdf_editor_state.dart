part of 'pdf_editor_bloc.dart';

sealed class PdfEditorState extends Equatable {
  const PdfEditorState();
  @override
  List<Object?> get props => [];
}

final class PdfEditorInitial extends PdfEditorState {
  const PdfEditorInitial();
}

final class PdfEditorReady extends PdfEditorState {
  const PdfEditorReady({
    required this.document,
    this.signature,
    this.currentPageIndex = 0,
    this.isExporting = false,
    this.exportedBytes,
    this.errorMessage,
  });

  final PickedPdfDocument document;
  final SignaturePlacement? signature;
  final int currentPageIndex;
  final bool isExporting;
  final Uint8List? exportedBytes;
  final String? errorMessage;

  PdfEditorReady copyWith({
    PickedPdfDocument? document,
    SignaturePlacement? signature,
    int? currentPageIndex,
    bool? isExporting,
    Uint8List? exportedBytes,
    String? errorMessage,
    bool clearExport = false,
    bool clearError = false,
  }) {
    return PdfEditorReady(
      document: document ?? this.document,
      signature: signature ?? this.signature,
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
      isExporting: isExporting ?? this.isExporting,
      exportedBytes: clearExport ? null : exportedBytes ?? this.exportedBytes,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    document,
    signature,
    currentPageIndex,
    isExporting,
    exportedBytes,
    errorMessage,
  ];
}
