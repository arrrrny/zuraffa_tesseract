# zuraffa_tesseract

Tesseract OCR for the Zuraffa ecosystem — a federated plugin covering
Android, iOS, macOS, Web, and Linux.

The package is an **abstraction**: a pure-Dart port (`TesseractPort`), a facade
(`TesseractService`) that owns the loaded-model registry, typed failures, and
DI registration. The actual OCR work happens in platform adapters, each of
which implements the port over an injected channel.

## Packages

| Package | Role | Status |
|---|---|---|
| `zuraffa_tesseract` | Pure-Dart port, facade, typed exceptions, DI | ✅ |
| `zuraffa_tesseract_platform` | Shared channel envelope (timeout, error taxonomy, single-completion) | ✅ |
| `zuraffa_tesseract_darwin` | iOS + macOS adapter (SwiftyTesseract 4.0.1+ via SPM) | ✅ |
| `zuraffa_tesseract_android` | Android adapter (Tesseract4Android) | ✅ |
| `zuraffa_tesseract_web` | Web adapter (tesseract.js WebAssembly) | ✅ |
| `zuraffa_tesseract_linux` | Linux adapter (system tesseract via C++ interop) | ✅ |

## Contract

```dart
abstract class TesseractPort {
  Future<bool> isSupported();
  Future<TesseractModel> loadModel({required String id, required Uint8List bytes});
  Future<TesseractText> recognize({
    required String modelId,
    required TesseractRequest request,
  });
  Future<void> unloadModel({required String id});
}
```

`TesseractRequest` carries the image reference (a path, or a
`blob:`/`data:`/`http(s)` URL on web), the language codes (`eng`, `eng+tur`),
the raw Tesseract variables, and an optional tessdata override.

`TesseractService` adds the lifecycle rules the platform cannot be trusted to
enforce: a double `loadModel` is `already_loaded`, a `recognize` before its
load is `not_loaded`, and both fail before the channel is touched.

## Usage

```dart
import 'package:zuraffa/zuraffa.dart';
import 'package:zuraffa_tesseract/zuraffa_tesseract.dart';
import 'package:zuraffa_tesseract_darwin/zuraffa_tesseract_darwin.dart';

// Wire the adapter for the running platform once, at startup
// (…_android / …_web / …_linux are the other three).
registerDarwinTesseractDependencies(getIt);

final ocr = getIt<TesseractService>();
await ocr.loadModel(id: 'eng', bytes: engTrainedData);
final text = await ocr.recognize(
  modelId: 'eng',
  request: const TesseractRequest(image: '/tmp/shot.png', language: 'eng'),
);
```

Without a wired adapter every call raises a typed `port_not_wired` failure
rather than a null dereference.

## Design notes

- **One completion, exactly once.** Recognition is a timeout race: the engine
  can finish as the deadline fires. `TesseractPlatformEnvelope` serialises the
  result so the channel answers once, and turns the overrun into a
  recoverable `timeout`.
- **The core invents no exception types.** Each adapter supplies its own
  factory and taxonomy hook, so a caller catches `TesseractException` without
  knowing which platform produced it.
- **Fix at the package layer.** A defect in an adapter is fixed in that
  adapter, not patched around in a consumer app.

## Testing

```sh
dart test -j 2                    # core + platform envelope
flutter test --concurrency=2      # each adapter package
```

Concurrency is capped at 2 — this repo is developed on the shared pool host.

## License

BSD 3-Clause. See [LICENSE](../LICENSE).