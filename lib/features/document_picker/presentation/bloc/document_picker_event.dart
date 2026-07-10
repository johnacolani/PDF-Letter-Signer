part of 'document_picker_bloc.dart';

sealed class DocumentPickerEvent extends Equatable {
  const DocumentPickerEvent();

  @override
  List<Object?> get props => [];
}

final class DocumentPickerRequested extends DocumentPickerEvent {
  const DocumentPickerRequested();
}
