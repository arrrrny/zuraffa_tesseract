import 'package:flutter/services.dart';
import 'package:zuraffa/zuraffa.dart';
import 'package:zuraffa_tesseract/zuraffa_tesseract.dart';

import 'darwin_tesseract_channel.dart';
import 'darwin_tesseract_exception.dart';
import 'darwin_tesseract_port.dart';

/// The method channel the native Darwin plugin registers itself on.
const MethodChannel darwinTesseractMethodChannel = MethodChannel(
  'tesseract_ocr',
);

/// Builds a channel over the default method-channel transport.
DarwinTesseractChannel darwinTesseractChannel({Duration? timeout}) {
  return DarwinTesseractChannel(
    invoke: (String method, Map<String, Object?> args) async =>
        darwinTesseractMethodChannel.invokeMethod<Object?>(method, args),
    timeout: timeout ?? const Duration(seconds: 30),
  );
}

/// Registers the Darwin adapter on [getIt]: the [TesseractPort] over the
/// injected channel. An injected [timeout] is applied to the wired channel.
/// Without a channel every call surfaces the typed `channel_not_wired`
/// failure.
void registerDarwinTesseractDependencies(
  GetIt getIt, {
  DarwinTesseractChannel? channel,
  Duration? timeout,
}) {
  final wired = channel ??
      ((timeout == null)
          ? null
          : darwinTesseractChannel(timeout: timeout));
  getIt.registerLazySingleton<TesseractPort>(
    () => DarwinTesseractPort(
      channel: wired ??
          DarwinTesseractChannel(
            invoke: (_, __) => throw const DarwinTesseractException(
              'channel_not_wired',
              'No Darwin channel was injected — pass one to '
              'registerDarwinTesseractDependencies.',
              recoverable: false,
            ),
          ),
    ),
  );
}