/// zuraffa_tesseract_web — Tesseract OCR adapter for Web.
///
/// Bridges [TesseractPort] to the `tesseract_ocr` Web plugin (system
/// tesseract via C++ interop) over a typed method channel.
library;

export 'src/web_tesseract_channel.dart';
export 'src/web_tesseract_exception.dart';
export 'src/web_tesseract_port.dart';
export 'src/register.dart';