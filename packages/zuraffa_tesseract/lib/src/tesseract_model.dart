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

  /// Tesseract variables passed straight through to the engine
  /// (`preserve_interword_spaces`, `tessedit_pageseg_mode`, …).
  final Map<String, String> options;

  /// Directory holding the `.traineddata` files. Null lets the adapter
  /// resolve its platform default (bundled assets, system tessdata).
  final String? tessDataPath;

  const TesseractRequest({
    required this.image,
    this.language = 'eng',
    this.options = const <String, String>{},
    this.tessDataPath,
  });

  /// Encodes this request into the channel argument map.
  Map<String, Object?> encode() => <String, Object?>{
        'imagePath': image,
        'language': language,
        if (tessDataPath != null) 'tessData': tessDataPath,
        if (options.isNotEmpty) 'options': options,
      };

  @override
  String toString() =>
      'TesseractRequest($image, lang: $language, ${options.length} options)';
}

/// Exception thrown when the requested language model is not usable.
class TesseractLanguageException extends TesseractException {
  const TesseractLanguageException(
    String code,
    String message, {
    bool recoverable = false,
  }) : super(code, message, recoverable: recoverable);
}