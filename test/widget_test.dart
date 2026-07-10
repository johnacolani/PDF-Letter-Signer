import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_letter_signer/app/app.dart';
import 'package:pdf_letter_signer/app/di/injection_container.dart';

void main() {
  setUp(() async {
    await getIt.reset();
    configureDependencies();
  });

  tearDown(() => getIt.reset());

  testWidgets('shows the PDF picker home screen', (tester) async {
    await tester.pumpWidget(const PdfLetterSignerApp());

    expect(find.text('PDF Letter Signer'), findsOneWidget);
    expect(find.text('Edit and sign PDF letters'), findsOneWidget);
    expect(find.text('Open PDF'), findsOneWidget);
  });
}
