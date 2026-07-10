import 'package:flutter/widgets.dart';
import 'package:pdf_letter_signer/app/app.dart';
import 'package:pdf_letter_signer/app/di/injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  runApp(const PdfLetterSignerApp());
}
