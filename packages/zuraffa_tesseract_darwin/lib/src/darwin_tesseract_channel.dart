import 'package:zuraffa_tesseract_platform/zuraffa_tesseract_platform.dart';

import 'darwin_tesseract_exception.dart';

/// The Darwin channel: the shared [TesseractPlatformEnvelope] machinery with
/// the plugin's own error taxonomy as a pure data set.
///
/// The envelope owns the timeout and the "call the Flutter result exactly
/// once" rule, so no adapter can double-complete a recognition.
class DarwinTesseractChannel {
  /// Native codes the plugin reports that a retry may clear.
  static const Set<String> recoverableCodes = <String>{
    'OCR_TIMEOUT',
    'OCR_PROCESS_ERROR',
    'timeout',
  };

  final ChannelInvoke invoke;
  final Duration timeout;

  const DarwinTesseractChannel({
    required this.invoke,
    this.timeout = const Duration(seconds: 30),
  });

  Future<Map<String, Object?>?> call(
    String method,
    Map<String, Object?> args,
  ) =>
      TesseractPlatformEnvelope(
        invoke: invoke,
        timeout: timeout,
        onTyped: DarwinTesseractException.new,
        mapNativeError: _mapNativeError,
        isTypedError: (Object error) => error is DarwinTesseractException,
      ).call(method, args);

  static Exception _mapNativeError(String code, String message) =>
      DarwinTesseractException(
        code,
        message,
        recoverable: recoverableCodes.contains(code),
      );
}