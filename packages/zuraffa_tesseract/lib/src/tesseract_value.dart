import 'tesseract_exception.dart';

/// A recognized text result crossing the platform boundary.
///
/// The channel transports the text as a single string value; this wrapper
/// keeps the empty-result case explicit so an adapter can tell "the engine
/// ran and found nothing" from "the engine failed".
class TesseractText {
  final String text;

  const TesseractText(this.text);

  /// Whether the engine produced no text at all.
  bool get isEmpty => text.isEmpty;

  /// Decodes a channel payload into a [TesseractText].
  static TesseractText decode(Object? raw) {
    if (raw == null) return const TesseractText('');
    if (raw is String) return TesseractText(raw);
    throw TesseractException(
      'malformed_value',
      'Cannot decode "$raw" into a TesseractText.',
      recoverable: false,
    );
  }

  /// Encodes this result into the primitive representation transported
  /// over the platform channel.
  Object encode() => text;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TesseractText && text == other.text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'TesseractText(${text.length} chars)';
}