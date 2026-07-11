# PDF Letter Signer

> A modern, cross-platform PDF editor built with Flutter that allows users to view, edit, annotate, fill, and sign PDF documents with a clean, intuitive interface.

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2.svg)
![Platforms](https://img.shields.io/badge/Platforms-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Windows%20%7C%20macOS%20%7C%20Linux-success)
![Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture-orange)
![State Management](https://img.shields.io/badge/State-BLoC-blueviolet)
![License](https://img.shields.io/badge/License-MIT-green)

---

## 📖 Overview

PDF Letter Signer is a professional PDF editing application built entirely with **Flutter** using **Clean Architecture**, **BLoC**, and **GetIt**.

The goal of this project is to provide a modern, lightweight, and cross-platform alternative for viewing, editing, annotating, filling, and signing PDF documents while maintaining a clean, scalable, and maintainable codebase.

Designed from the ground up with software engineering best practices, the project separates presentation, business logic, and data layers to ensure long-term maintainability and testability.
<img width="1254" height="1254" alt="image" src="https://github.com/user-attachments/assets/bff7d71a-9350-4d6e-9504-b9aa8fd499b8" />


---

# ✨ Features

## 📄 PDF Viewer

- Open PDF documents
- Smooth page navigation
- Pinch-to-zoom
- Page thumbnails
- Continuous scrolling
- Jump to specific pages
- Search within PDF
- Dark mode support

---

## ✍️ PDF Editing

- Add text anywhere
- Edit inserted text
- Move text
- Resize text
- Rotate text
- Delete text
- Change fonts
- Change text color
- Change font size

---

## 🖊 Sign Documents

- Draw handwritten signatures
- Type signatures
- Import signature images
- Save reusable signatures
- Create initials
- Change pen thickness
- Change ink color
- Place signatures anywhere
- Resize signatures
- Rotate signatures

---

## 📝 Annotation Tools

- Freehand drawing
- Highlight
- Underline
- Strike-through
- Notes
- Shapes
- Checkmarks
- Date stamps
- Image stamps

---

## 📑 Forms

- Fill PDF forms
- Text fields
- Checkboxes
- Radio buttons
- Dropdown menus
- Date fields
- Signature fields

---

## 📂 Document Management

- Recent documents
- Favorites
- Rename
- Duplicate
- Share
- Print
- Export
- Save As
- Password protection

---

## 📚 Page Management

- Add pages
- Delete pages
- Rotate pages
- Rearrange pages
- Merge PDFs
- Split PDFs
- Extract pages

---

## 🔒 Security

- Password-protected PDFs
- Encryption support
- Secure local storage
- No unnecessary cloud dependency
- Offline-first design

---

# 🚀 Roadmap

## Version 1.0

- PDF Viewer
- Signature Tool
- Text Tool
- Save Edited PDF
- Undo / Redo
- Multi-platform Support

---

## Version 1.5

- Form Filling
- Highlighting
- Drawing
- Images
- Stamps

---

## Version 2.0

- OCR
- Merge PDFs
- Split PDFs
- Cloud Storage
- Digital Certificates
- Digital Signature Verification

---

# 🏗 Architecture

The project follows **Feature-First Clean Architecture**.

```
Presentation
     │
     ▼
Domain
     │
     ▼
Data
```

Each feature is completely isolated.

```
lib/
│
├── app/
│
├── core/
│
├── features/
│   ├── pdf_viewer/
│   ├── pdf_editor/
│   ├── signature/
│   ├── export/
│   ├── settings/
│   └── recent_documents/
│
└── main.dart
```

---

# 📐 Design Principles

- Clean Architecture
- SOLID Principles
- Feature-first structure
- Dependency Injection
- Repository Pattern
- Use Cases
- Immutable State
- Testable Business Logic
- Platform Independence

---

# 🧠 State Management

The application uses **flutter_bloc**.

Every major feature owns its own BLoC.

Example:

```
PdfViewerBloc
PdfEditorBloc
SignatureBloc
ExportBloc
SettingsBloc
RecentDocumentsBloc
ThemeBloc
```

---

# 💉 Dependency Injection

Dependency Injection is implemented using **GetIt**.

Benefits include:

- Loose coupling
- Easy testing
- Scalable architecture
- Centralized dependency management

---

# 🎨 Design System

A complete design system is included.

```
core/
└── design_system/
    ├── colors/
    ├── typography/
    ├── spacing/
    ├── radius/
    ├── icons/
    └── theme/
```

Includes:

- Color Manager
- Theme Manager
- Font Manager
- Text Styles
- Spacing
- Border Radius
- Icon Definitions
- Material 3 Theme

---

# 📦 Project Structure

```
lib/
│
├── app/
│
├── core/
│
│   ├── constants/
│   ├── design_system/
│   ├── error/
│   ├── services/
│   ├── storage/
│   ├── utils/
│   └── widgets/
│
├── features/
│
│   ├── pdf_viewer/
│   ├── pdf_editor/
│   ├── signature/
│   ├── export/
│   ├── settings/
│   └── recent_documents/
│
└── main.dart
```

---

# ⚙ Technologies

- Flutter
- Dart
- BLoC
- GetIt
- Equatable
- Syncfusion PDF
- Syncfusion PDF Viewer
- File Picker
- Path Provider
- Printing
- Share Plus

---

# 📱 Supported Platforms

- ✅ Android
- ✅ iOS
- ✅ Windows
- ✅ macOS
- ✅ Linux
- ✅ Web

---

# 🎯 Project Goals

The primary goals of this project are:

- Professional PDF editing
- Cross-platform compatibility
- High performance
- Clean codebase
- Easy maintenance
- Scalable architecture
- Excellent user experience

---

# 🔄 Future Enhancements

- AI document summarization
- AI text extraction
- AI handwriting recognition
- OCR scanning
- Cloud synchronization
- Real-time collaboration
- Digital certificates
- Electronic signature verification
- Document templates
- Watermarks
- Batch processing
- Multi-window editing

---

# 🧪 Testing

The architecture is designed to support:

- Unit Tests
- Widget Tests
- Integration Tests
- Repository Tests
- Use Case Tests
- BLoC Tests

---

# 🤝 Contributing

Contributions are welcome!

If you'd like to improve the project:

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to your branch
5. Open a Pull Request

Please follow the existing architecture and coding conventions.

---

# 📜 License

This project is licensed under the MIT License.

---

# ❤️ Acknowledgements

Special thanks to the Flutter community and the open-source ecosystem for providing the tools and libraries that make this project possible.

---

# ⭐ Support

If you find this project useful, please consider giving it a ⭐ on GitHub.

It helps others discover the project and motivates future development.

---

## 📬 Contact

Feel free to open an Issue or submit a Pull Request if you have suggestions, bug reports, or feature requests.

---

**Built with ❤️ using Flutter**
