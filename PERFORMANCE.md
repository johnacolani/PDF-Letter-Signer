# PDF Editor Performance Architecture

## Root causes fixed

The editor previously placed `SfPdfViewer.memory` inside a broad
`BlocConsumer`. Signature drag and resize gestures emitted a BLoC state for
every pointer delta, so the scaffold, viewer, thumbnails, toolbar, and overlays
were all rebuilt many times per second. Page changes also emitted BLoC state,
and loading/autosave timers called page-level `setState`.

Autosave serialized the complete PDF only 900 milliseconds after each form
change and did not coordinate overlapping saves. Thumbnail rendering was
started during the main editor build and was not reset when PDF bytes changed.

## Current state ownership

Application/committed state remains in `PdfEditorBloc`:

- loaded and deliberately replaced PDF document;
- committed signature bytes, page, position, and size;
- export lifecycle, exported bytes, and major errors.

Temporary high-frequency UI state is local:

- signature movement and resize use a notifier inside
  `DraggableSignatureOverlay` and commit once on pointer release;
- current visible page uses a `ValueNotifier<int>`;
- loading progress uses a `ValueNotifier<double?>`;
- autosave display state uses a focused notifier;
- navigator visibility, precise-placement mode, and layout mode remain small
  editor UI settings.

## Viewer rebuild contract

`PdfViewerSection` retains the same `SfPdfViewer` widget instance across parent
rebuilds. The expensive viewer widget is recreated only when:

- the PDF byte-list identity changes;
- the explicit document revision changes; or
- the PDF page layout mode changes.

Dragging/resizing a signature, changing the visible page, updating loading or
autosave progress, selecting a thumbnail, export progress, and error messages
do not recreate the viewer.

In debug mode, a guarded diagnostic prints:

```text
PdfViewerSection expensive rebuild #N
```

It is inside `assert`, so it is removed from profile and release builds.

## Autosave behavior

Autosave now waits four seconds after editing stops. Only one save can run at a
time. Changes arriving during a save set a pending flag and schedule one more
debounced save. Status changes rebuild only the toolbar indicator. Export first
serializes the current form data and writes the final autosave before export.

Debug-only timing records autosave duration.

## Thumbnail behavior

Thumbnails are requested lazily by `ListView.builder`, only when the page
navigator is visible and items are built. Each page future is cached, preventing
duplicate render requests. Images are rendered at thumbnail dimensions.

When PDF bytes are deliberately replaced, the renderer is closed, decoded
images are disposed, and the cache is recreated for the new document. Bounds
checks prevent stale or invalid page requests. Debug-only timing records each
thumbnail render duration.

## Work that remains inherently expensive

Syncfusion viewer loading, `PdfViewerController.saveDocument()`, platform PDF
page rendering, and Syncfusion PDF serialization still process the complete
document. They are now invoked less often and no longer triggered by pointer
movement.

The viewer controller and thumbnail renderer use plugin/platform state and
cannot safely cross isolate boundaries. Syncfusion `PdfDocument` objects also
cannot be transferred to another isolate. A byte-only PDF rewrite could
potentially be wrapped in an isolate on native targets, but doing that across
web and desktop requires a separately tested conditional implementation; it was
not introduced here because correctness of interactive form data takes priority.

Changing the birthplace country must rebuild the province combo-box options
inside the PDF. Syncfusion requires saving the current form, modifying the PDF,
serializing it, and deliberately reloading the viewer. Identical country values
are ignored, and the loading indicator is isolated while this unavoidable
reload runs.

## Profiling

Use Flutter DevTools Performance view with Track Widget Builds enabled. During
a signature drag, `PdfViewerSection expensive rebuild` must not increment.

On each supported host, run:

```bash
flutter run -d windows --profile
flutter run -d chrome --profile
flutter run -d macos --profile
```

Release builds:

```bash
flutter build windows --release
flutter build web --release
flutter build macos --release
```

macOS commands must be run on macOS with Xcode installed. Windows cannot build
or launch a macOS target.
