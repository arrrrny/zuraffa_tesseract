/// zuraffa_tesseract — Tesseract OCR support for the Zuraffa ecosystem.
///
/// A pure-Dart port (`TesseractPort`), a facade (`TesseractService`),
/// typed failures, and DI registration. Platform adapters implement the port
/// over an injected platform channel — the shared envelope machinery lives in
/// `zuraffa_tesseract_platform`.
library;

export 'src/tesseract_exception.dart';
export 'src/tesseract_model.dart';
export 'src/tesseract_port.dart';
export 'src/tesseract_service.dart';
export 'src/tesseract_value.dart';