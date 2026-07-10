import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:pdf_letter_signer/features/document_picker/domain/document_source_picker.dart';
import 'package:pdf_letter_signer/features/pdf_editor/domain/entities/signature_placement.dart';
import 'package:pdf_letter_signer/features/pdf_editor/domain/usecases/export_signed_pdf.dart';

part 'pdf_editor_event.dart';
part 'pdf_editor_state.dart';

class PdfEditorBloc extends Bloc<PdfEditorEvent, PdfEditorState> {
  PdfEditorBloc(this._exportSignedPdf) : super(const PdfEditorInitial()) {
    on<PdfEditorDocumentOpened>(_onOpened);
    on<PdfEditorSignaturePlaced>(_onPlaced);
    on<PdfEditorSignatureMoved>(_onMoved);
    on<PdfEditorPageChanged>(_onPageChanged);
    on<PdfEditorExportRequested>(_onExportRequested);
    on<PdfEditorExportConsumed>(_onExportConsumed);
  }

  final ExportSignedPdf _exportSignedPdf;

  void _onOpened(PdfEditorDocumentOpened event, Emitter<PdfEditorState> emit) {
    emit(PdfEditorReady(document: event.document));
  }

  void _onPlaced(PdfEditorSignaturePlaced event, Emitter<PdfEditorState> emit) {
    final current = state;
    if (current is! PdfEditorReady) return;
    emit(current.copyWith(signature: event.placement, clearExport: true));
  }

  void _onMoved(PdfEditorSignatureMoved event, Emitter<PdfEditorState> emit) {
    final current = state;
    if (current is! PdfEditorReady || current.signature == null) return;
    emit(current.copyWith(
      signature: current.signature!.copyWith(x: event.x, y: event.y),
      clearExport: true,
    ));
  }

  void _onPageChanged(PdfEditorPageChanged event, Emitter<PdfEditorState> emit) {
    final current = state;
    if (current is! PdfEditorReady) return;
    emit(current.copyWith(currentPageIndex: event.pageIndex));
  }

  Future<void> _onExportRequested(
    PdfEditorExportRequested event,
    Emitter<PdfEditorState> emit,
  ) async {
    final current = state;
    if (current is! PdfEditorReady || current.signature == null) return;
    emit(current.copyWith(isExporting: true, clearError: true));
    try {
      final bytes = await _exportSignedPdf(
        sourcePdf: current.document.bytes,
        placement: current.signature!,
      );
      emit(current.copyWith(isExporting: false, exportedBytes: bytes));
    } catch (error) {
      emit(current.copyWith(isExporting: false, errorMessage: error.toString()));
    }
  }

  void _onExportConsumed(
    PdfEditorExportConsumed event,
    Emitter<PdfEditorState> emit,
  ) {
    final current = state;
    if (current is PdfEditorReady) emit(current.copyWith(clearExport: true));
  }
}
