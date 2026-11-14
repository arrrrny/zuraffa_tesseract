import 'dart:typed_data';

import 'tesseract_model.dart';
import 'tesseract_value.dart';

/// The platform-neutral port every adapter implements. Pure Dart — the
/// transport is injected behind the platform envelope, so tests run offline
/// with fake channels.
abstract class TesseractPort {
  const TesseractPort();

  /// Whether the host platform can run OCR at all.
  Future<bool> isSupported();

  /// Loads the language model [bytes] and binds it to [id].
  Future<TesseractModel> loadModel({
    required String id,
    required Uint8List bytes,
  });

  /// Runs OCR for [request] against the model bound to [modelId].
  Future<TesseractText> recognize({
    required String modelId,
    required TesseractRequest request,
  });

  /// Releases the model bound to [id].
  Future<void> unloadModel({required String id});
}