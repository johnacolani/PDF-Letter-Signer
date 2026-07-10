import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:pdf_letter_signer/features/signature/domain/entities/signature_draft.dart';

class SignatureCubit extends Cubit<SignatureDraft?> {
  SignatureCubit() : super(null);

  void save(Uint8List bytes) => emit(SignatureDraft(bytes));
  void clear() => emit(null);
}
