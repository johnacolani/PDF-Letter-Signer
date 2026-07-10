import 'package:file_picker/file_picker.dart';
import 'package:pdf_letter_signer/features/document_picker/domain/document_source_picker.dart';

class FilePickerService implements DocumentSourcePicker {
  @override
  Future<PickedPdfDocument?> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      throw StateError('The selected PDF could not be loaded into memory.');
    }
    return PickedPdfDocument(name: file.name, bytes: bytes, path: file.path);
  }
}
