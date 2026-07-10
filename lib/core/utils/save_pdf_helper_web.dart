import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<bool> savePdfBytes({
  required Uint8List bytes,
  required String suggestedName,
}) async {
  await FilePicker.saveFile(fileName: suggestedName, bytes: bytes);
  return true;
}
