import 'dart:typed_data';

import 'package:zuraffa_tesseract/zuraffa_tesseract.dart';

import 'linux_tesseract_channel.dart';
import 'linux_tesseract_exception.dart';

/// The Linux [TesseractPort] over the typed [LinuxTesseractChannel].
///
/// As on Darwin, `loadModel` is bookkeeping: the native plugin resolves its
/// tessdata directory itself (probing the distro's install locations), so the
/// model id is tracked here to keep the core's load/unload contract honest.
class LinuxTesseractPort implements TesseractPort {
  final LinuxTesseractChannel channel;

  const LinuxTesseractPort({required this.channel});

  @override
  Future<bool> isSupported() async {
    final result =
        await channel.call('isSupported', const <String, Object?>{});
    return result?['supported'] == true;
  }

  @override
  Future<TesseractModel> loadModel({
    required String id,
    required Uint8List bytes,
  }) async {
    if (bytes.isEmpty) {
      throw const LinuxTesseractException(
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
    final result = await channel.call('extractText', request.encode());
    return TesseractText.decode(result?['text']);
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
      'Linux.',
    );
  }

  @override
  Future<void> unloadModel({required String id}) async {
    // Nothing to release natively: the engine holds no per-id state.
  }
}