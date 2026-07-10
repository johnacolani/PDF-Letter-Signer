import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<bool> savePdfBytes({
  required Uint8List bytes,
  required String suggestedName,
}) async {
  final path = await FilePicker.saveFile(
    dialogTitle: 'Save signed PDF',
    fileName: suggestedName,
    type: FileType.custom,
    allowedExtensions: const ['pdf'],
    bytes: bytes,
  );
  if (path == null) return false;
  return true;
}
