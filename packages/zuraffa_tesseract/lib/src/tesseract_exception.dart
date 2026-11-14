/// Base exception for all zuraffa_tesseract errors.
///
/// Every typed failure carries a machine-readable [code], a human-readable
/// [message], and a [recoverable] hint — the UI layer uses it to decide
/// whether a retry is worth offering.
class TesseractException implements Exception {
  final String code;
  final String message;
  final bool recoverable;

  const TesseractException(
    this.code,
    this.message, {
    this.recoverable = false,
  });

  @override
  String toString() =>
      'TesseractException($code, recoverable: $recoverable): $message';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TesseractException &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          message == other.message &&
          recoverable == other.recoverable;

  @override
  int get hashCode => code.hashCode ^ message.hashCode ^ recoverable.hashCode;
}