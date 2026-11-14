import 'package:zuraffa/zuraffa.dart';
import 'package:zuraffa_tesseract/zuraffa_tesseract.dart';

import 'web_tesseract_channel.dart';
import 'web_tesseract_exception.dart';
import 'web_tesseract_port.dart';

/// Registers the web adapter on [getIt]: the [TesseractPort] over the
/// injected channel. An injected [timeout] is applied to the wired channel.
/// Without a channel every call surfaces the typed `channel_not_wired`
/// failure.
void registerWebTesseractDependencies(
  GetIt getIt, {
  WebTesseractChannel? channel,
  Duration? timeout,
}) {
  final wired = channel ??
      (timeout == null ? null : WebTesseractChannel(
        invoke: (_, __) => throw const WebTesseractException(
          'channel_not_wired',
          'No web channel was injected — pass one to '
          'registerWebTesseractDependencies.',
          recoverable: false,
        ),
        timeout: timeout,
      ));
  getIt.registerLazySingleton<TesseractPort>(
    () => WebTesseractPort(
      channel: wired ??
          WebTesseractChannel(
            invoke: (_, __) => throw const WebTesseractException(
              'channel_not_wired',
              'No web channel was injected — pass one to '
              'registerWebTesseractDependencies.',
              recoverable: false,
            ),
          ),
    ),
  );
}