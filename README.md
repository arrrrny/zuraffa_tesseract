# zuraffa_tesseract

Tesseract OCR implementation for the Zuraffa ecosystem.

A federated plugin that provides OCR capabilities across all platforms (Android, iOS, macOS, Web, Linux) using Tesseract.

## Packages

- `zuraffa_tesseract` - Pure Dart core with typed exceptions and lifecycle management
- `zuraffa_tesseract_platform` - Platform interface and shared envelope
- `zuraffa_tesseract_android` - Android implementation (Tesseract4Android)
- `zuraffa_tesseract_ios` - iOS implementation (SwiftyTesseract via SPM)
- `zuraffa_tesseract_macos` - macOS implementation (SwiftyTesseract via SPM)
- `zuraffa_tesseract_web` - Web implementation (tesseract.js)
- `zuraffa_tesseract_linux` - Linux implementation (system tesseract via C++)

## Architecture

This package follows the same federated architecture as `zuraffa_ocr`:

- **Pure Dart core** (`OcrPort`, `OcrService`) - platform-agnostic
- **WASM-style lifecycle** - compile/invoke/unload modules
- **Typed exceptions** - error handling with recovery hints
- **Zuraffa DI integration** - works with GetIt

## Installation

```yaml
dependencies:
  zuraffa_tesseract: ^1.0.0
  # Platform adapter (automatically selected)
  zuraffa_tesseract_android: ^1.0.0  # or ios, macos, web, linux
```

## Usage

```dart
import 'package:zuraffa_tesseract/zuraffa_tesseract.dart';

// Get the service from DI
final ocrService = getIt<OcrService>();

// Compile a Tesseract module
final module = await ocrService.compile(
  id: 'tesseract',
  bytes: tesseractWasmBytes,
);

// Perform OCR
final result = await ocrService.call(
  id: 'tesseract',
  export: 'recognize',
  args: [OcrValue.string(imagePath)],
);

// Cleanup
await ocrService.unload(id: 'tesseract');
```

## Platform Support

| Platform | Implementation | Status |
|----------|---------------|--------|
| Android | Tesseract4Android | ✅ Ready |
| iOS | SwiftyTesseract 4.0.1+ (SPM) | ✅ Ready |
| macOS | SwiftyTesseract 4.0.1+ (SPM) | ✅ Ready |
| Web | tesseract.js 6.0.1 | ✅ Ready |
| Linux | System tesseract (C++) | ✅ Ready |

## License

BSD 3-Clause License