import 'dart:io';
import 'dart:typed_data';

Future<String?> autosavePdfBytes({
  required Uint8List bytes,
  required String? sourcePath,
}) async {
  if (sourcePath == null || sourcePath.trim().isEmpty) return null;

  final extensionIndex = sourcePath.toLowerCase().lastIndexOf('.pdf');
  final basePath =
      extensionIndex == sourcePath.length - 4
          ? sourcePath.substring(0, extensionIndex)
          : sourcePath;
  final autosavePath = '${basePath}_autosave.pdf';
  final temporaryPath = '$autosavePath.tmp';
  final temporaryFile = File(temporaryPath);
  await temporaryFile.writeAsBytes(bytes, flush: true);

  final autosaveFile = File(autosavePath);
  if (await autosaveFile.exists()) await autosaveFile.delete();
  await temporaryFile.rename(autosavePath);
  return autosavePath;
}
