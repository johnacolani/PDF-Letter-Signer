# PDF Letter Signer

A cross-platform Flutter starter for opening, signing, and exporting PDF letters.

## Architecture

- Feature-first Clean Architecture
- BLoC/Cubit for presentation state
- GetIt for dependency injection
- Syncfusion PDF Viewer and PDF engine behind a repository abstraction
- Dedicated colors, fonts, spacing, radius, and theme classes
- Domain entities remain plain Dart and do not depend on Flutter UI classes

## Implemented milestone

- Pick a PDF on supported platforms
- Display the PDF from memory
- Draw a handwritten signature
- Place and drag the signature overlay
- Store placement using normalized coordinates
- Stamp the signature into the selected PDF page
- Export a new `_signed.pdf` file
- Responsive mobile/desktop editor shell
- Light/dark theme state
- Example domain use-case test

## Important current limitation

The editor overlay is positioned relative to the visible viewer viewport. This starter demonstrates the complete data flow and export operation, but production precision requires measuring the exact rendered PDF page rectangle, zoom, rotation, and scroll offset. Implement that coordinate adapter before claiming pixel-perfect placement at every zoom level.

Other future work: text boxes, dates, checkmarks, resizing, undo/redo, multiple signatures, page thumbnails, form fields, OCR, encryption, redaction, and certificate-based digital signatures.

## Generate native platform folders

The ZIP intentionally contains the maintainable Flutter source rather than generated platform build folders. From the project root, run:

```bash
flutter create . --platforms=android,ios,web,windows,macos,linux
flutter pub get
```

Then run one target:

```bash
flutter run -d windows
flutter run -d macos
flutter run -d chrome
flutter run -d android
flutter run -d ios
flutter run -d linux
```

## Syncfusion license

Syncfusion packages require an appropriate Syncfusion license. Confirm whether the Community License applies to you, and register the license key during startup when required by your account/license terms.

## Suggested production phases

1. Exact page-coordinate adapter and page-rectangle tracking
2. Resize/rotate handles and element selection
3. Undo/redo command history
4. Text, date, initials, checkmarks, and images
5. Save project state separately from flattened PDF export
6. Recent documents and autosave recovery
7. Form filling and annotation import/export
8. Security review and certificate-based signatures

## Verification

Verified with Flutter 3.44.0 and Dart 3.12.0:

- `flutter analyze`
- `flutter test`
- `flutter build windows --release`
- `flutter build web --release`
