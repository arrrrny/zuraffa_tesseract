import 'dart:typed_data';

import 'package:zuraffa_tesseract/zuraffa_tesseract.dart';

import 'web_tesseract_channel.dart';
import 'web_tesseract_exception.dart';

/// The web [TesseractPort] over the typed [WebTesseractChannel].
///
/// A browser has no method channel: the transport is the plugin's own JS
/// interop, injected as [WebTesseractChannel.invoke]. As on the other
/// platforms, `loadModel` is bookkeeping — the plugin resolves the bundled
/// `.traineddata` assets and the CDN-hosted tesseract.js itself.
class WebTesseractPort implements TesseractPort {
  final WebTesseractChannel channel;

  const WebTesseractPort({required this.channel});

  /// The web plugin has no `isSupported` method: support is a property of the
  /// page (WebAssembly + a reachable tesseract.js), so this reports the
  /// platform as available and lets the first recognition surface a real
  /// failure if the runtime cannot load the engine.
  @override
  Future<bool> isSupported() async => true;

  @override
  Future<TesseractModel> loadModel({
    required String id,
    required Uint8List bytes,
  }) async {
    if (bytes.isEmpty) {
      throw const WebTesseractException(
        'empty_model',
        'A language model must carry at least one byte of traineddata.',
        recoverable: false,
      );
    }
    return TesseractModel(id: id, byteLength: bytes.lengthInBytes);
  }

  @override
  Future<TesseractText> recognize({
    required String modelId,
    required TesseractRequest request,
  }) async {
    _rejectUnsupportedEngine(request);
    final text = await channel.callText('extractText', request.encode());
    return TesseractText(text ?? '');
  }

  /// Apple Vision ships only in the iOS plugin, so asking for it here is a
  /// caller error — fail before the channel rather than letting the native
  /// side silently fall back to Tesseract.
  void _rejectUnsupportedEngine(TesseractRequest request) {
    if (!request.usesVision) return;
    throw TesseractEngineException(
      'unsupported_engine',
      'OCREngine.vision is only supported on iOS. '
      'Use TesseractEngine.tesseract or TesseractEngine.defaultEngine on '
      'the web.',
    );
  }

  @override
  Future<void> unloadModel({required String id}) async {
    // Nothing to release: the plugin terminates its worker per recognition.
  }
}