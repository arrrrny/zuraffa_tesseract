import 'tesseract_engine.dart';
import 'tesseract_exception.dart';

/// A Tesseract language model loaded into the engine, bound to [id] until
/// unloaded. Immutable value object — the service owns the registry.
class TesseractModel {
  final String id;
  final int byteLength;

  const TesseractModel({required this.id, required this.byteLength});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TesseractModel &&
          id == other.id &&
          byteLength == other.byteLength;

  @override
  int get hashCode => id.hashCode ^ byteLength.hashCode;

  @override
  String toString() => 'TesseractModel($id, $byteLength bytes)';
}

/// A single OCR request: the image to read plus the recognition settings
/// that apply to it.
class TesseractRequest {
  /// A file path, `blob:`/`data:`/`http(s)` URL (web), or any string the
  /// platform adapter can resolve to image bytes.
  final String image;

  /// Language codes joined with `+` (e.g. `eng`, `eng+tur`).
  final String language;

  /// Which engine to use. Defaults to the platform default — Vision on iOS,
  /// Tesseract elsewhere.
  final TesseractEngine engine;

  /// Tesseract variables passed straight through to the engine
  /// (`preserve_interword_spaces`, `tessedit_pageseg_mode`, …). Ignored when
  /// [engine] is [TesseractEngine.vision].
  final Map<String, String> options;

  /// Directory holding the `.traineddata` files. Null lets the adapter
  /// resolve its platform default (bundled assets, system tessdata).
  final String? tessDataPath;

  const TesseractRequest({
    required this.image,
    this.language = 'eng',
    this.engine = TesseractEngine.defaultEngine,
    this.options = const <String, String>{},
    this.tessDataPath,
  });

  /// Whether this request asks for Apple Vision.
  bool get usesVision => engine == TesseractEngine.vision;

  /// Encodes this request into the channel argument map.
  ///
  /// `engine` goes at the top level because that is where the native plugins
  /// read it; the Tesseract variables stay under `options`.
  Map<String, Object?> encode() => <String, Object?>{
        'imagePath': image,
        'language': language,
        'engine': engine.wireValue,
        if (tessDataPath != null) 'tessData': tessDataPath,
        if (options.isNotEmpty) 'options': options,
      };

  @override
  String toString() => 'TesseractRequest($image, '
      'engine: ${engine.wireValue}, lang: $language, '
      '${options.length} options)';
}

/// Exception thrown when the requested language model is not usable.
class TesseractLanguageException extends TesseractException {
  const TesseractLanguageException(
    String code,
    String message, {
    bool recoverable = false,
  }) : super(code, message, recoverable: recoverable);
}