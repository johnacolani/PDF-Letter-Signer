import 'dart:typed_data';

class PickedPdfDocument {
  const PickedPdfDocument({required this.name, required this.bytes, this.path});

  final String name;
  final Uint8List bytes;
  final String? path;
}

abstract interface class DocumentSourcePicker {
  Future<PickedPdfDocument?> pickPdf();
}
