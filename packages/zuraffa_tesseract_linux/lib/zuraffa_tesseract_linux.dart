/// zuraffa_tesseract_linux — Tesseract OCR adapter for Linux.
///
/// Bridges [TesseractPort] to the `tesseract_ocr` Linux plugin (system
/// tesseract via C++ interop) over a typed method channel.
library;

export 'src/linux_tesseract_channel.dart';
export 'src/linux_tesseract_exception.dart';
export 'src/linux_tesseract_port.dart';
export 'src/register.dart';