import 'dart:typed_data';

Future<bool> savePdfBytes({
  required Uint8List bytes,
  required String suggestedName,
}) async {
  throw UnsupportedError('Saving files is not supported on this platform.');
}
