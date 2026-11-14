import 'package:zuraffa_tesseract/zuraffa_tesseract.dart';

/// The adapter's own typed failure: the shared core never invents one, so
/// every error the envelope builds is a [TesseractException] subclass the
/// caller can catch without knowing which platform produced it.
class WebTesseractException extends TesseractException {
  const WebTesseractException(
    String code,
    String message, {
    bool recoverable = false,
  }) : super(code, message, recoverable: recoverable);
}