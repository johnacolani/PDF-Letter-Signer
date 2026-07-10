import 'package:file_picker/file_picker.dart';
import 'package:pdf_letter_signer/features/document_picker/domain/document_source_picker.dart';

class FilePickerService implements DocumentSourcePicker {
  @override
  Future<PickedPdfDocument?> pickPdf() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    return PickedPdfDocument(name: file.name, bytes: bytes, path: file.path);
  }
}
