import 'package:zuraffa_tesseract_platform/zuraffa_tesseract_platform.dart';

import 'android_tesseract_exception.dart';

/// The Android channel: the shared [TesseractPlatformEnvelope] machinery with
/// the plugin's own error taxonomy as a pure data set.
///
/// The Java plugin answers `extractText` with a bare string rather than a map,
/// so [callText] unwraps that shape before the envelope's map contract is
/// applied to it.
class AndroidTesseractChannel {
  /// Native codes the plugin reports that a retry may clear.
  static const Set<String> recoverableCodes = <String>{
    'OCR_TIMEOUT',
    'OCR_PROCESS_ERROR',
    'timeout',
  };

  final ChannelInvoke invoke;
  final Duration timeout;

  const AndroidTesseractChannel({
    required this.invoke,
    this.timeout = const Duration(seconds: 30),
  });

  /// Recognizes [args] and returns the extracted text, or null when the
  /// engine produced nothing.
  Future<String?> callText(
    String method,
    Map<String, Object?> args,
  ) async {
    final result = await TesseractPlatformEnvelope(
      invoke: (String m, Map<String, Object?> a) async {
        final Object? raw = await invoke(m, a);
        // The plugin returns the text itself, not a payload map.
        if (raw is String) return <String, Object?>{'text': raw};
        return raw;
      },
      timeout: timeout,
      onTyped: AndroidTesseractException.new,
      mapNativeError: _mapNativeError,
      isTypedError: (Object error) => error is AndroidTesseractException,
    ).call(method, args);
    return result?['text'] as String?;
  }

  static Exception _mapNativeError(String code, String message) {
    // `INIT_ERROR` and `INVALID_ARGUMENT` both mean the caller must change
    // something (bundle traineddata, pass a path) — neither is a retry.
    return AndroidTesseractException(
      code,
      message,
      recoverable: recoverableCodes.contains(code),
    );
  }
}