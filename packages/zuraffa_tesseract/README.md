# zuraffa_tesseract

Pure-Dart Tesseract OCR contract, model lifecycle facade, and typed failure taxonomy for the Zuraffa ecosystem.

## Usage

```dart
import 'package:zuraffa/zuraffa.dart';
import 'package:zuraffa_tesseract/zuraffa_tesseract.dart';
import 'package:zuraffa_tesseract_darwin/zuraffa_tesseract_darwin.dart';

registerDarwinTesseractDependencies(getIt);

final ocr = getIt<TesseractService>();
await ocr.loadModel(id: 'eng', bytes: engTrainedData);
final text = await ocr.recognize(
  modelId: 'eng',
  request: const TesseractRequest(image: '/tmp/shot.png', language: 'eng'),
);
```