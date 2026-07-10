# Setup checklist

1. Install the latest stable Flutter SDK.
2. Run `flutter doctor -v` and resolve the target-platform requirements.
3. Run `flutter create . --platforms=android,ios,web,windows,macos,linux`.
4. Run `flutter pub get`.
5. Add the Syncfusion license registration if required.
6. Run `flutter analyze`.
7. Run `flutter test`.
8. Launch one platform and verify open → sign → drag → export.

## Platform notes

- iOS/macOS builds require Xcode on macOS.
- Windows builds require Visual Studio with Desktop development with C++.
- Linux builds require the Flutter Linux desktop prerequisites.
- Browser saving downloads the generated PDF.
- Native platforms display a Save As dialog.
