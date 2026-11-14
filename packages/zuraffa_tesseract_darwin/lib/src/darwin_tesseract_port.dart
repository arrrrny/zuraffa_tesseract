import 'dart:typed_data';

import 'package:zuraffa_tesseract/zuraffa_tesseract.dart';

import 'darwin_tesseract_channel.dart';
import 'darwin_tesseract_exception.dart';

/// The Darwin [TesseractPort] over the typed [DarwinTesseractChannel].
///
/// The native plugin exposes `extractText` as its recognition entry point, so
/// `loadModel` is bookkeeping only: the `.traineddata` files are Flutter
/// assets the engine resolves itself, and the model id is tracked here to keep
/// the core's load/unload contract honest.
class DarwinTesseractPort implements TesseractPort {
  final DarwinTesseractChannel channel;

  const DarwinTesseractPort({required this.channel});

  @override
  Future<bool> isSupported() async {
    final result = await channel.call('isSupported', const <String, Object?>{});
    return result?['supported'] == true;
  }

  @override
  Future<TesseractModel> loadModel({
    required String id,
    required Uint8List bytes,
  }) async {
    // The engine takes its language data from the app's tessdata assets, so
    // the bytes are accepted for contract symmetry and validated only.
    if (bytes.isEmpty) {
      throw const DarwinTesseractException(
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
    final result = await channel.call('extractText', request.encode());
    return TesseractText.decode(result?['text']);
  }

  @override
  Future<void> unloadModel({required String id}) async {
    // Nothing to release natively: the engine holds no per-id state.
  }
}