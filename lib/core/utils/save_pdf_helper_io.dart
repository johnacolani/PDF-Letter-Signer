import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<bool> savePdfBytes({
  required Uint8List bytes,
  required String suggestedName,
}) async {
  final path = await FilePicker.platform.saveFile(
    dialogTitle: 'Save signed PDF',
    fileName: suggestedName,
    type: FileType.custom,
    allowedExtensions: const ['pdf'],
  );
  if (path == null) return false;
  await File(path).writeAsBytes(bytes, flush: true);
  return true;
}
