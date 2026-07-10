part of 'document_picker_bloc.dart';

sealed class DocumentPickerState extends Equatable {
  const DocumentPickerState();

  @override
  List<Object?> get props => [];
}

final class DocumentPickerInitial extends DocumentPickerState {
  const DocumentPickerInitial();
}

final class DocumentPickerLoading extends DocumentPickerState {
  const DocumentPickerLoading();
}

final class DocumentPickerSuccess extends DocumentPickerState {
  const DocumentPickerSuccess(this.document);
  final PickedPdfDocument document;

  @override
  List<Object?> get props => [document.name, document.bytes.length];
}

final class DocumentPickerFailure extends DocumentPickerState {
  const DocumentPickerFailure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
