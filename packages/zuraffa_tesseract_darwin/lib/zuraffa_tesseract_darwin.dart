/// zuraffa_tesseract_darwin — Tesseract OCR adapter for iOS and macOS.
///
/// Bridges [TesseractPort] to the `tesseract_ocr` Darwin plugin
/// (SwiftyTesseract 4.0.1+ via Swift Package Manager) over a typed method
/// channel.
library;

export 'src/darwin_tesseract_channel.dart';
export 'src/darwin_tesseract_exception.dart';
export 'src/darwin_tesseract_port.dart';
export 'src/register.dart';