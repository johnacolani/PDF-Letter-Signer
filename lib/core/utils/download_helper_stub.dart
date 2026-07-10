import 'dart:typed_data';

Future<void> downloadBytes({
  required Uint8List bytes,
  required String fileName,
}) async {
  throw UnsupportedError('Browser download is available only on Flutter Web.');
}
