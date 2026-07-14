# Flutter App Icons Guide

This guide explains the icon problem fixed in **PDF Letter Signer** and how to
set app icons correctly on Windows, web, Android, iOS, macOS, and Linux.

## Why the icon I added did not appear

Flutter app icons are **native platform resources**. Adding a PNG under
`assets/`, mentioning it in `pubspec.yaml`, or showing it with `Image.asset()`
only makes the image available inside the Flutter UI. It does not replace the
icon used by Windows Explorer, a browser tab, an installed web app, Android,
iOS, macOS, or a Linux desktop launcher.

Two separate problems existed in this project:

### Windows

`windows/runner/Runner.rc` was already configured to compile this file:

```text
windows/runner/resources/app_icon.ico
```

However, that `.ico` file still contained Flutter's default icon. The custom
PNG elsewhere in the project was never used by the Windows resource compiler.

The fix was:

1. Convert the custom artwork to a real, multi-resolution ICO containing
   16, 20, 24, 32, 40, 48, 64, 128, and 256 pixel images.
2. Replace `windows/runner/resources/app_icon.ico`.
3. Keep this resource mapping in `windows/runner/Runner.rc`:

   ```rc
   IDI_APP_ICON ICON "resources\\app_icon.ico"
   ```

4. Load that resource as both the large and small window icon in
   `windows/runner/win32_window.cpp`. This project now sets `hIcon`, `hIconSm`,
   `WM_SETICON/ICON_BIG`, and `WM_SETICON/ICON_SMALL`.
5. Clean and rebuild the Windows executable.

The current Windows icon files/wiring are:

```text
windows/runner/resources/app_icon.ico
windows/runner/Runner.rc
windows/runner/resource.h
windows/runner/win32_window.cpp
```

### Web

A web app uses more than one icon. The browser tab/favicon comes from
`web/index.html`, while installable/PWA icons come from `web/manifest.json`.
Previously, the custom files and the filenames referenced by those files did
not consistently match. Web paths and filename capitalization must be exact,
especially after deployment to a case-sensitive server.

The fix was to wire these files explicitly:

```text
web/icons/favicon.ico
web/icons/apple-touch-icon.png
web/icons/Icon-192.png
web/icons/Icon-512.png
web/icons/Icon-maskable-192.png
web/icons/Icon-maskable-512.png
```

`web/index.html` now contains the favicon, PNG icon, Apple touch icon, and
manifest links. `web/manifest.json` now references the matching 192, 512, and
maskable PNG files. A clean web build then copied them into `build/web/icons/`.

## Recommended source artwork

Keep one master image, for example:

```text
assets/branding/app_icon_1024.png
```

Recommended properties:

- 1024 x 1024 pixels or larger
- square canvas
- PNG format
- important artwork away from the edges
- transparent background only where the target platform supports it
- no tiny text, because launcher icons are often displayed at 16–48 pixels

Do not resize a small image upward. Start with the largest clean original.

## Windows

Required file:

```text
windows/runner/resources/app_icon.ico
```

An ICO should contain multiple resolutions, not merely be a renamed PNG.
Confirm `windows/runner/Runner.rc` points to it. Then rebuild:

```powershell
flutter clean
flutter pub get
flutter build windows
```

The built executable is normally under:

```text
build/windows/x64/runner/Release/<app_name>.exe
```

If the old icon remains:

1. Close the running app.
2. Unpin its old taskbar shortcut.
3. Delete old desktop/Start Menu shortcuts.
4. Build again and launch the newly built executable directly.
5. Pin the new executable again.

Explorer may cache executable icons. Restarting Windows Explorer or signing out
can refresh that cache, but first verify that you are launching the new `.exe`
and not an older copy.

## Web and PWA

Use at least:

```text
web/icons/favicon.ico
web/icons/apple-touch-icon.png
web/icons/Icon-192.png
web/icons/Icon-512.png
web/icons/Icon-maskable-192.png
web/icons/Icon-maskable-512.png
```

In `web/index.html`, wire the browser and Apple icons:

```html
<link rel="apple-touch-icon" href="icons/apple-touch-icon.png">
<link rel="icon" type="image/x-icon" href="icons/favicon.ico">
<link rel="icon" type="image/png" sizes="192x192" href="icons/Icon-192.png">
<link rel="manifest" href="manifest.json">
```

In `web/manifest.json`, wire the installable app icons:

```json
"icons": [
  {
    "src": "icons/Icon-192.png",
    "sizes": "192x192",
    "type": "image/png"
  },
  {
    "src": "icons/Icon-512.png",
    "sizes": "512x512",
    "type": "image/png"
  },
  {
    "src": "icons/Icon-maskable-192.png",
    "sizes": "192x192",
    "type": "image/png",
    "purpose": "maskable"
  },
  {
    "src": "icons/Icon-maskable-512.png",
    "sizes": "512x512",
    "type": "image/png",
    "purpose": "maskable"
  }
]
```

Build and verify:

```powershell
flutter clean
flutter pub get
flutter build web
Get-ChildItem build\web\icons
```

Browsers aggressively cache favicons, manifests, service workers, and PWA
icons. If the old icon remains:

- hard refresh the page;
- clear site data/cache in browser developer tools;
- unregister the old service worker;
- uninstall and reinstall the PWA if it was already installed;
- confirm the deployed server contains the newly built `build/web` files;
- confirm filename capitalization matches exactly.

## Android

Android launcher icons normally live under density-specific resource folders:

```text
android/app/src/main/res/mipmap-mdpi/
android/app/src/main/res/mipmap-hdpi/
android/app/src/main/res/mipmap-xhdpi/
android/app/src/main/res/mipmap-xxhdpi/
android/app/src/main/res/mipmap-xxxhdpi/
android/app/src/main/res/mipmap-anydpi-v26/
```

`android/app/src/main/AndroidManifest.xml` should reference the launcher icon:

```xml
<application android:icon="@mipmap/ic_launcher" ...>
```

Modern Android supports adaptive icons with foreground, background, and
optional monochrome layers. Generate all density files; do not replace only
one `ic_launcher.png`.

After changing them:

```powershell
flutter clean
flutter pub get
flutter build apk
```

If a device still shows the old icon, uninstall the old app before reinstalling
the new APK. Some launchers cache icons.

## iOS and iPadOS

Icons are defined by the asset catalog:

```text
ios/Runner/Assets.xcassets/AppIcon.appiconset/
ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json
```

Every filename declared in `Contents.json` must exist at its required size.
Use opaque PNGs for the main iOS app icon; Apple app icons should not rely on
transparency.

Build from macOS with Xcode installed:

```bash
flutter clean
flutter pub get
flutter build ios
```

If the simulator/device caches the old icon, delete the installed app and
install it again.

## macOS

The macOS icon asset catalog is:

```text
macos/Runner/Assets.xcassets/AppIcon.appiconset/
macos/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json
```

Keep all sizes referenced by `Contents.json`. The Xcode project selects the
asset set named `AppIcon`.

Build from macOS:

```bash
flutter clean
flutter pub get
flutter build macos
```

Finder and the Dock may cache icons. Quit the old app, remove its old Dock
entry, and open the newly built `.app` before pinning it again.

## Linux

Flutter's Linux runner does not provide one universal embedded launcher-icon
file. Linux desktop environments normally get the icon from the application
package and a `.desktop` launcher file.

For packaging, install a PNG or SVG using a stable icon name, for example:

```text
/usr/share/icons/hicolor/256x256/apps/pdf-letter-signer.png
```

Create/install a launcher such as:

```ini
[Desktop Entry]
Type=Application
Name=PDF Letter Signer
Comment=Open, complete, sign, and export PDF letters
Exec=/opt/pdf-letter-signer/pdf_letter_signer
Icon=pdf-letter-signer
Terminal=false
Categories=Office;
```

The `Icon` value is the icon name without `.png`, when installed into the
system icon theme. For a local development launcher, it can instead be an
absolute path to a PNG.

Typical package contents are:

```text
/opt/pdf-letter-signer/                       application bundle
/usr/share/applications/pdf-letter-signer.desktop
/usr/share/icons/hicolor/256x256/apps/pdf-letter-signer.png
```

Build the Flutter bundle with:

```bash
flutter clean
flutter pub get
flutter build linux
```

The raw Flutter build creates the application bundle, but desktop menu
integration is normally completed by a `.deb`, RPM, AppImage, Snap, Flatpak,
or an installer script. After installing a new icon, the desktop environment
may require logout/login or an icon-cache refresh.

## Optional: generate most icons automatically

The `flutter_launcher_icons` development package can generate Android, iOS,
web, Windows, and macOS icon resources from one source PNG. Check the package's
current documentation before selecting a version or configuration options.
Linux desktop launcher/package integration still needs to be handled by the
Linux packaging method you choose.

A typical configuration concept is:

```yaml
dev_dependencies:
  flutter_launcher_icons: <current-version>

flutter_launcher_icons:
  image_path: assets/branding/app_icon_1024.png
  android: true
  ios: true
  web:
    generate: true
  windows:
    generate: true
  macos:
    generate: true
```

Then run the command specified by the package's current documentation. Always
inspect the generated native files and perform clean platform builds afterward.

## Checklist for every icon update

- [ ] Start from a square 1024 x 1024 master image.
- [ ] Generate every size required by each target platform.
- [ ] Confirm native files were replaced, not only Flutter assets.
- [ ] Confirm all manifest/resource filenames and capitalization match.
- [ ] Run `flutter clean` and `flutter pub get`.
- [ ] Build each target platform again.
- [ ] Inspect the new executable/app/build output, not an older installed copy.
- [ ] Remove old shortcuts or installed apps when testing.
- [ ] Clear browser/PWA/desktop icon caches if necessary.
- [ ] For Linux, package both the icon and `.desktop` launcher.

