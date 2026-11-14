import 'package:flutter/services.dart';
import 'package:zuraffa/zuraffa.dart';
import 'package:zuraffa_tesseract/zuraffa_tesseract.dart';

import 'linux_tesseract_channel.dart';
import 'linux_tesseract_exception.dart';
import 'linux_tesseract_port.dart';

/// The method channel the native Linux plugin registers itself on.
const MethodChannel linuxTesseractMethodChannel = MethodChannel(
  'tesseract_ocr',
);

/// Builds a channel over the default method-channel transport.
LinuxTesseractChannel linuxTesseractChannel({Duration? timeout}) {
  return LinuxTesseractChannel(
    invoke: (String method, Map<String, Object?> args) async =>
        linuxTesseractMethodChannel.invokeMethod<Object?>(method, args),
    timeout: timeout ?? const Duration(seconds: 30),
  );
}

/// Registers the Linux adapter on [getIt]: the [TesseractPort] over the
/// injected channel. An injected [timeout] is applied to the wired channel.
/// Without a channel every call surfaces the typed `channel_not_wired`
/// failure.
void registerLinuxTesseractDependencies(
  GetIt getIt, {
  LinuxTesseractChannel? channel,
  Duration? timeout,
}) {
  final wired =
      channel ?? (timeout == null ? null : linuxTesseractChannel(timeout: timeout));
  getIt.registerLazySingleton<TesseractPort>(
    () => LinuxTesseractPort(
      channel: wired ??
          LinuxTesseractChannel(
            invoke: (_, __) => throw const LinuxTesseractException(
              'channel_not_wired',
              'No Linux channel was injected — pass one to '
              'registerLinuxTesseractDependencies.',
              recoverable: false,
            ),
          ),
    ),
  );
}