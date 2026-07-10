import 'dart:typed_data';

import 'package:equatable/equatable.dart';

class SignatureDraft extends Equatable {
  const SignatureDraft(this.pngBytes);
  final Uint8List pngBytes;

  @override
  List<Object?> get props => [pngBytes.length];
}
