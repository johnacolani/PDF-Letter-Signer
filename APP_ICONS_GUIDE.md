# Flutter App Icons Guide

A simple guide to correctly set application icons for **Flutter** on Windows, Android, iOS, macOS, Web, and Linux.

---

# Why my icon did not appear

Placing an image inside:

```text
assets/
```

does **not** automatically make it the application icon.

Images inside `assets/` are only used inside your Flutter UI, for example:

```dart
Image.asset('assets/images/my_icon.png')
```

Every platform (Windows, Android, iOS, Web, macOS, Linux) manages its application icon separately.

The easiest solution is to keep **one high-quality PNG** and let Flutter generate all required icon formats automatically.

---

# Recommended Workflow

## Step 1 – Create one master icon

Use your best icon from IconKitchen (or any design tool).

Recommended properties:

- 1024 × 1024 pixels
- PNG
- Square
- High quality
- Keep important artwork away from the edges
- Avoid tiny text

Rename it:

```text
app_icon.png
```

Create this folder:

```text
assets/
└── branding/
    └── app_icon.png
```

Your project should look like:

```text
your_flutter_project/
├── android/
├── ios/
├── lib/
├── web/
├── windows/
├── macos/
├── linux/
├── assets/
│   └── branding/
│       └── app_icon.png
└── pubspec.yaml
```

> **You only need this single PNG.**
> Do **not** manually create `.ico` files or dozens of PNG sizes.

---

# Step 2 – Install flutter_launcher_icons

Run:

```bash
flutter pub add --dev flutter_launcher_icons
```

---

# Step 3 – Configure pubspec.yaml

Open:

```text
pubspec.yaml
```

Add this **at the bottom of the file** (not inside the `flutter:` section):

```yaml
flutter_launcher_icons:
  image_path: "assets/branding/app_icon.png"

  android: true

  ios: true
  remove_alpha_ios: true
  background_color_ios: "#FFFFFF"

  web:
    generate: true
    image_path: "assets/branding/app_icon.png"
    background_color: "#FFFFFF"
    theme_color: "#FFFFFF"

  windows:
    generate: true
    image_path: "assets/branding/app_icon.png"
    icon_size: 256

  macos:
    generate: true
    image_path: "assets/branding/app_icon.png"
```

A simplified `pubspec.yaml`:

```yaml
name: pdf_letter_signer

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter

  flutter_launcher_icons: ^0.14.4

flutter:
  uses-material-design: true

flutter_launcher_icons:
  image_path: "assets/branding/app_icon.png"

  android: true

  ios: true
  remove_alpha_ios: true
  background_color_ios: "#FFFFFF"

  web:
    generate: true
    image_path: "assets/branding/app_icon.png"
    background_color: "#FFFFFF"
    theme_color: "#FFFFFF"

  windows:
    generate: true
    image_path: "assets/branding/app_icon.png"
    icon_size: 256

  macos:
    generate: true
    image_path: "assets/branding/app_icon.png"
```

---

# Step 4 – Generate platform icons

Run:

```bash
flutter pub get
dart run flutter_launcher_icons
```

The package automatically creates:

- Android launcher icons
- iOS AppIcon assets
- Windows `.ico`
- Web icons
- macOS icons

You **do not** need to manually generate:

- `.ico`
- `16×16`
- `32×32`
- `48×48`
- `192×192`
- `512×512`
- Android mipmap folders
- iOS AppIcon files

---

# Step 5 – Clean and rebuild

```bash
flutter clean
flutter pub get
```

---

## Windows

```bash
flutter build windows
```

or

```bash
flutter run -d windows
```

---

## Android

```bash
flutter build apk
```

or

```bash
flutter run -d android
```

---

## Web

```bash
flutter build web
```

or

```bash
flutter run -d chrome
```

---

## iOS

```bash
flutter build ios
```

or

```bash
flutter run -d ios
```

---

## macOS

```bash
flutter build macos
```

or

```bash
flutter run -d macos
```

---

# If the old icon still appears

The icon was probably generated correctly.

The operating system is usually showing a cached version.

---

## Windows

1. Close the application.
2. Open the newly built executable:

```
build/windows/x64/runner/Release/
```

3. Remove old desktop shortcuts.
4. Unpin the old taskbar shortcut.
5. Pin the new executable again.

If necessary, restart **Windows Explorer** from Task Manager.

---

## Android

Uninstall the existing app before reinstalling.

Many launchers cache icons.

---

## Web

Browsers cache:

- favicon
- manifest
- service worker
- PWA icons

Try:

- Hard refresh
- Clear site data
- Clear browser cache
- Unregister the service worker
- Reinstall the PWA

---

## iOS / macOS

Delete the installed app and reinstall it.

macOS may also cache the Dock icon.

---

# About IconKitchen

IconKitchen usually gives you a ZIP file containing many folders.

You have two choices.

---

## Recommended

Take the **1024×1024 PNG** and save it as:

```
assets/branding/app_icon.png
```

Run:

```bash
dart run flutter_launcher_icons
```

Done.

---

## Manual

You can manually copy files into:

- Android mipmap folders
- iOS AppIcon
- Windows ICO
- Web icons
- macOS AppIcon

This works, but it is much easier to make mistakes.

---

# Android Adaptive Icons (Optional)

If IconKitchen provides:

```
foreground.png
background.png
monochrome.png
```

you can configure:

```yaml
flutter_launcher_icons:
  image_path: assets/branding/app_icon.png

  android: true

  adaptive_icon_background: "#FFFFFF"

  adaptive_icon_foreground: assets/branding/app_icon_foreground.png

  adaptive_icon_monochrome: assets/branding/app_icon_monochrome.png

  ios: true

  web:
    generate: true

  windows:
    generate: true

  macos:
    generate: true
```

If you do not have these files, ignore this section.

The standard configuration is perfectly fine.

---

# Linux

Flutter can build Linux applications:

```bash
flutter build linux
```

However, Linux desktop launchers require additional packaging.

Usually you also need:

- `.desktop` launcher
- PNG or SVG icon
- AppImage, Flatpak, Snap, `.deb`, or RPM package

This is separate from Flutter icon generation.

---

# Final Checklist

- ✅ Create `assets/branding/app_icon.png`
- ✅ Use a **1024×1024** PNG
- ✅ Configure `flutter_launcher_icons`
- ✅ Run:

```bash
flutter pub get
dart run flutter_launcher_icons
flutter clean
flutter pub get
```

- ✅ Rebuild the application
- ✅ Test the **newly built executable**, not an old copy
- ✅ Remove cached shortcuts if necessary

---

# Most Important Command

```bash
dart run flutter_launcher_icons
```

This single command generates almost every platform-specific icon automatically from your master PNG.
