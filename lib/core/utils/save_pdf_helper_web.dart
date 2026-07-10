import 'dart:typed_data';

import 'package:pdf_letter_signer/core/utils/download_helper.dart';

Future<bool> savePdfBytes({
  required Uint8List bytes,
  required String suggestedName,
}) async {
  await downloadBytes(bytes: bytes, fileName: suggestedName);
  return true;
}
