import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:pdf_letter_signer/features/document_picker/domain/document_source_picker.dart';
import 'package:pdf_letter_signer/features/pdf_editor/domain/entities/signature_placement.dart';
import 'package:pdf_letter_signer/features/pdf_editor/domain/usecases/export_signed_pdf.dart';

part 'pdf_editor_event.dart';
part 'pdf_editor_state.dart';

enum PdfEditorOutputAction { save, print }

class PdfEditorBloc extends Bloc<PdfEditorEvent, PdfEditorState> {
  PdfEditorBloc(this._exportSignedPdf) : super(const PdfEditorInitial()) {
    on<PdfEditorDocumentOpened>(_onOpened);
    on<PdfEditorDocumentUpdated>(_onDocumentUpdated);
    on<PdfEditorSignaturePlaced>(_onPlaced);
    on<PdfEditorSignatureMoved>(_onMoved);
    on<PdfEditorSignatureTransformed>(_onTransformed);
    on<PdfEditorPageChanged>(_onPageChanged);
    on<PdfEditorExportRequested>(_onExportRequested);
    on<PdfEditorPrintRequested>(_onPrintRequested);
    on<PdfEditorExportConsumed>(_onExportConsumed);
  }

  final ExportSignedPdf _exportSignedPdf;

  void _onOpened(PdfEditorDocumentOpened event, Emitter<PdfEditorState> emit) {
    emit(PdfEditorReady(document: event.document));
  }

  void _onDocumentUpdated(
    PdfEditorDocumentUpdated event,
    Emitter<PdfEditorState> emit,
  ) {
    final current = state;
    if (current is! PdfEditorReady) return;
    if (identical(current.document.bytes, event.document.bytes) &&
        current.document.name == event.document.name &&
        current.document.path == event.document.path) {
      return;
    }
    emit(current.copyWith(document: event.document, clearExport: true));
  }

  void _onPlaced(PdfEditorSignaturePlaced event, Emitter<PdfEditorState> emit) {
    final current = state;
    if (current is! PdfEditorReady) return;
    if (current.signature == event.placement) return;
    emit(current.copyWith(signature: event.placement, clearExport: true));
  }

  void _onMoved(PdfEditorSignatureMoved event, Emitter<PdfEditorState> emit) {
    final current = state;
    if (current is! PdfEditorReady || current.signature == null) return;
    if (current.signature!.x == event.x && current.signature!.y == event.y) {
      return;
    }
    emit(
      current.copyWith(
        signature: current.signature!.copyWith(x: event.x, y: event.y),
        clearExport: true,
      ),
    );
  }

  void _onTransformed(
    PdfEditorSignatureTransformed event,
    Emitter<PdfEditorState> emit,
  ) {
    final current = state;
    if (current is! PdfEditorReady || current.signature == null) return;
    final signature = current.signature!;
    if (signature.pageIndex == event.pageIndex &&
        signature.x == event.x &&
        signature.y == event.y &&
        signature.width == event.width &&
        signature.height == event.height) {
      return;
    }
    emit(
      current.copyWith(
        signature: current.signature!.copyWith(
          pageIndex: event.pageIndex,
          x: event.x,
          y: event.y,
          width: event.width,
          height: event.height,
        ),
        clearExport: true,
      ),
    );
  }

  void _onPageChanged(
    PdfEditorPageChanged event,
    Emitter<PdfEditorState> emit,
  ) {
    final current = state;
    if (current is! PdfEditorReady) return;
    if (current.currentPageIndex == event.pageIndex) return;
    emit(current.copyWith(currentPageIndex: event.pageIndex));
  }

  Future<void> _onExportRequested(
    PdfEditorExportRequested event,
    Emitter<PdfEditorState> emit,
  ) async {
    final current = state;
    if (current is! PdfEditorReady || current.signature == null) return;
    await _createOutput(PdfEditorOutputAction.save, current, emit);
  }

  Future<void> _onPrintRequested(
    PdfEditorPrintRequested event,
    Emitter<PdfEditorState> emit,
  ) async {
    final current = state;
    if (current is! PdfEditorReady) return;
    await _createOutput(PdfEditorOutputAction.print, current, emit);
  }

  Future<void> _createOutput(
    PdfEditorOutputAction action,
    PdfEditorReady current,
    Emitter<PdfEditorState> emit,
  ) async {
    emit(current.copyWith(isExporting: true, clearError: true));
    try {
      final bytes = await _exportSignedPdf(
        sourcePdf: current.document.bytes,
        placement: current.signature,
      );
      emit(
        current.copyWith(
          isExporting: false,
          exportedBytes: bytes,
          outputAction: action,
        ),
      );
    } catch (error) {
      emit(
        current.copyWith(isExporting: false, errorMessage: error.toString()),
      );
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
