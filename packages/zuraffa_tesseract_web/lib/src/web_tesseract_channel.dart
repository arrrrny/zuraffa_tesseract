import 'package:zuraffa_tesseract_platform/zuraffa_tesseract_platform.dart';

import 'web_tesseract_exception.dart';

/// The web channel: the shared [TesseractPlatformEnvelope] machinery with the
/// plugin's own error taxonomy as a pure data set.
///
/// The web plugin answers `extractText` with a bare string rather than a map,
/// so [callText] unwraps that shape before the envelope's map contract is
/// applied to it.
class WebTesseractChannel {
  /// Native codes the plugin reports that a retry may clear.
  static const Set<String> recoverableCodes = <String>{
    'OCR_TIMEOUT',
    'OCR_PROCESS_ERROR',
    'timeout',
  };

  final ChannelInvoke invoke;
  final Duration timeout;

  const WebTesseractChannel({
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
        // The web plugin returns the text itself, not a payload map.
        if (raw is String) return <String, Object?>{'text': raw};
        return raw;
      },
      timeout: timeout,
      onTyped: WebTesseractException.new,
      mapNativeError: _mapNativeError,
      isTypedError: (Object error) => error is WebTesseractException,
    ).call(method, args);
    return result?['text'] as String?;
  }

  static Exception _mapNativeError(String code, String message) =>
      WebTesseractException(
        code,
        message,
        recoverable: recoverableCodes.contains(code),
      );
}