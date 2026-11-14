/// zuraffa_tesseract — Tesseract OCR support for the Zuraffa ecosystem.
///
/// A pure-Dart port (`OcrPort`), a facade (`OcrService`),
/// typed failures, and DI registration. Platform adapters implement the
/// port over an injected platform channel — the shared envelope machinery
/// lives in `zuraffa_tesseract_platform`.
library;

export 'src/tesseract_exception.dart';
export 'src/tesseract_module.dart';
export 'src/tesseract_module.dart';
export 'src/ocr_port.dart';
export 'src/ocr_service.dart';
export 'src/ocr_value.dart';