import 'tesseract_exception.dart';

/// A compiled Tesseract module held by [OcrService].
///
/// Modules are immutable value objects — the service owns the registry,
/// this class just carries the metadata the caller needs to reason about
/// what is loaded.
class TesseractModule {
  final String id;
  final int byteLength;

  const TesseractModule({
    required this.id,
    required this.byteLength,
  });

  @override
  String toString() => 'TesseractModule($id, $byteLength bytes)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TesseractModule &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          byteLength == other.byteLength;

  @override
  int get hashCode => id.hashCode ^ byteLength.hashCode;
}

/// Exception thrown when a module operation fails.
class TesseractModuleException extends TesseractException {
  const TesseractModuleException(
    String code,
    String message, {
    bool recoverable = false,
  }) : super(code, message, recoverable: recoverable);
}