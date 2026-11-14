import 'package:flutter/services.dart';
import 'package:zuraffa/zuraffa.dart';
import 'package:zuraffa_tesseract/zuraffa_tesseract.dart';

import 'android_tesseract_channel.dart';
import 'android_tesseract_exception.dart';
import 'android_tesseract_port.dart';

/// The method channel the native Android plugin registers itself on.
const MethodChannel androidTesseractMethodChannel = MethodChannel(
  'tesseract_ocr',
);

/// Builds a channel over the default method-channel transport.
AndroidTesseractChannel androidTesseractChannel({Duration? timeout}) {
  return AndroidTesseractChannel(
    invoke: (String method, Map<String, Object?> args) async =>
        androidTesseractMethodChannel.invokeMethod<Object?>(method, args),
    timeout: timeout ?? const Duration(seconds: 30),
  );
}

/// Registers the Android adapter on [getIt]: the [TesseractPort] over the
/// injected channel. An injected [timeout] is applied to the wired channel.
/// Without a channel every call surfaces the typed `channel_not_wired`
/// failure.
void registerAndroidTesseractDependencies(
  GetIt getIt, {
  AndroidTesseractChannel? channel,
  Duration? timeout,
}) {
  final wired = channel ??
      (timeout == null ? null : androidTesseractChannel(timeout: timeout));
  getIt.registerLazySingleton<TesseractPort>(
    () => AndroidTesseractPort(
      channel: wired ??
          AndroidTesseractChannel(
            invoke: (_, __) => throw const AndroidTesseractException(
              'channel_not_wired',
              'No Android channel was injected — pass one to '
              'registerAndroidTesseractDependencies.',
              recoverable: false,
            ),
          ),
    ),
  );
}