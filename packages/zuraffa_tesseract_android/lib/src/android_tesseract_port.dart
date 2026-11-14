import 'dart:typed_data';

import 'package:zuraffa_tesseract/zuraffa_tesseract.dart';

import 'android_tesseract_channel.dart';
import 'android_tesseract_exception.dart';

/// The Android [TesseractPort] over the typed [AndroidTesseractChannel].
///
/// Tesseract4Android loads its language data from the app's assets, so
/// `loadModel` is bookkeeping — it validates the traineddata and tracks the
/// id to keep the core's load/unload contract honest.
class AndroidTesseractPort implements TesseractPort {
  final AndroidTesseractChannel channel;

  const AndroidTesseractPort({required this.channel});

  /// The Java plugin exposes no `isSupported` method: Tesseract4Android is
  /// always present on a Flutter Android build, so support is unconditional
  /// and a missing traineddata surfaces at recognition time.
  @override
  Future<bool> isSupported() async => true;

  @override
  Future<TesseractModel> loadModel({
    required String id,
    required Uint8List bytes,
  }) async {
    if (bytes.isEmpty) {
      throw const AndroidTesseractException(
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
    final text = await channel.callText('extractText', request.encode());
    return TesseractText(text ?? '');
  }

  @override
  Future<void> unloadModel({required String id}) async {
    // Nothing to release: the engine holds no per-id state.
  }
}