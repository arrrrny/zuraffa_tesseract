import 'tesseract_exception.dart';

/// Which OCR engine a [TesseractRequest] asks for.
///
/// The plugin's own `OCREngine` enum is mirrored here rather than imported:
/// the core is pure Dart and must not depend on a platform plugin package.
enum TesseractEngine {
  /// Apple Vision — iOS only. Requesting it anywhere else is a typed
  /// [TesseractEngineException], raised before the channel is touched.
  vision('vision'),

  /// Tesseract (LSTM + legacy) — every platform.
  tesseract('tesseract'),

  /// The platform default: Vision on iOS, Tesseract elsewhere.
  defaultEngine('defaultEngine');

  /// The wire value the native plugin reads.
  final String wireValue;

  const TesseractEngine(this.wireValue);

  /// Parses a wire value, accepting the enum name and the legacy spelling
  /// `default`. Returns null for anything unknown so the caller can reject
  /// it rather than silently defaulting.
  static TesseractEngine? tryParse(Object? raw) {
    if (raw is TesseractEngine) return raw;
    if (raw is! String) return null;
    final normalized = raw.trim().toLowerCase();
    for (final engine in values) {
      if (engine.wireValue.toLowerCase() == normalized) return engine;
      if (engine.name.toLowerCase() == normalized) return engine;
    }
    // The Dart enum's default case renders as `defaultEngine`; accept the
    // bare `default` too, which is how it appears in hand-written config.
    if (normalized == 'default') return TesseractEngine.defaultEngine;
    return null;
  }

  @override
  String toString() => wireValue;
}

/// Raised when an engine cannot run on the current platform.
class TesseractEngineException extends TesseractException {
  const TesseractEngineException(String code, String message)
      : super(code, message, recoverable: false);
}