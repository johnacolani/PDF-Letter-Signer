import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:pdf_letter_signer/features/document_picker/domain/document_source_picker.dart';

part 'document_picker_event.dart';
part 'document_picker_state.dart';

class DocumentPickerBloc
    extends Bloc<DocumentPickerEvent, DocumentPickerState> {
  DocumentPickerBloc(this._picker) : super(const DocumentPickerInitial()) {
    on<DocumentPickerRequested>(_onRequested);
  }

  final DocumentSourcePicker _picker;

  Future<void> _onRequested(
    DocumentPickerRequested event,
    Emitter<DocumentPickerState> emit,
  ) async {
    emit(const DocumentPickerLoading());
    try {
      final document = await _picker.pickPdf();
      emit(
        document == null
            ? const DocumentPickerInitial()
            : DocumentPickerSuccess(document),
      );
    } catch (error) {
      emit(DocumentPickerFailure(error.toString()));
    }
  }
}
