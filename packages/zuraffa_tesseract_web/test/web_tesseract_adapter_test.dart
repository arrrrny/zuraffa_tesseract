// Adapter tests over a fake injected transport (bare-string success, empty
// result, taxonomy, timeout, unwired) — no browser required.
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:zuraffa/zuraffa.dart';
import 'package:zuraffa_tesseract/zuraffa_tesseract.dart';
import 'package:zuraffa_tesseract_web/zuraffa_tesseract_web.dart';

void main() {
  group('WebTesseractAdapter', () {
    test('recognize decodes the bare string the plugin returns', () async {
      final channel = WebTesseractChannel(
        invoke: (method, args) async {
          expect(method, 'extractText');
          expect(args['imagePath'], 'blob:https://example.com/abc');
          expect(args['language'], 'eng');
          return 'hello from wasm';
        },
      );
      final port = WebTesseractPort(channel: channel);

      final result = await port.recognize(
        modelId: 'eng',
        request: const TesseractRequest(
          image: 'blob:https://example.com/abc',
        ),
      );

      expect(result.text, 'hello from wasm');
      expect(result.isEmpty, isFalse);
    });

    test('an empty string decodes as an empty result', () async {
      final channel = WebTesseractChannel(invoke: (_, __) async => '');
      final port = WebTesseractPort(channel: channel);

      final result = await port.recognize(
        modelId: 'eng',
        request: const TesseractRequest(image: 'blob:x'),
      );

      expect(result.isEmpty, isTrue);
    });

    test('a null result decodes as an empty result, not an error', () async {
      final channel = WebTesseractChannel(invoke: (_, __) async => null);
      final port = WebTesseractPort(channel: channel);

      final result = await port.recognize(
        modelId: 'eng',
        request: const TesseractRequest(image: 'blob:x'),
      );

      expect(result.isEmpty, isTrue);
    });

    test('loadModel rejects empty traineddata before touching the transport',
        () async {
      var calls = 0;
      final channel = WebTesseractChannel(
        invoke: (_, __) async {
          calls++;
          return '';
        },
      );
      final port = WebTesseractPort(channel: channel);

      await expectLater(
        () => port.loadModel(id: 'eng', bytes: Uint8List(0)),
        throwsA(isA<TesseractException>()
            .having((e) => e.code, 'code', 'empty_model')),
      );
      expect(calls, 0);
    });

    test('native error payloads surface as typed failures', () async {
      final channel = WebTesseractChannel(
        invoke: (_, __) async => <String, Object?>{
          'error': <String, Object?>{
            'code': 'TESSDATA_NOT_FOUND',
            'message': 'no eng.traineddata in the bundle',
          },
        },
      );
      final port = WebTesseractPort(channel: channel);

      await expectLater(
        () => port.recognize(
          modelId: 'eng',
          request: const TesseractRequest(image: 'blob:x'),
        ),
        throwsA(isA<TesseractException>()
            .having((e) => e.code, 'code', 'TESSDATA_NOT_FOUND')
            .having((e) => e.recoverable, 'recoverable', isFalse)),
      );
    });

    test('a recognition past the timeout is a recoverable timeout', () async {
      final channel = WebTesseractChannel(
        invoke: (_, __) => Future<String>.delayed(
          const Duration(seconds: 5),
          () => 'late',
        ),
        timeout: const Duration(milliseconds: 50),
      );
      final port = WebTesseractPort(channel: channel);

      await expectLater(
        () => port.recognize(
          modelId: 'eng',
          request: const TesseractRequest(image: 'blob:x'),
        ),
        throwsA(isA<TesseractException>()
            .having((e) => e.code, 'code', 'timeout')
            .having((e) => e.recoverable, 'recoverable', isTrue)),
      );
    });

    test('registerWebTesseractDependencies resolves over the wired channel',
        () async {
      final getIt = GetIt.instance..reset();
      registerWebTesseractDependencies(
        getIt,
        channel: WebTesseractChannel(invoke: (_, __) async => 'ok'),
      );

      final port = getIt<TesseractPort>();
      final result = await port.recognize(
        modelId: 'eng',
        request: const TesseractRequest(image: 'blob:x'),
      );
      expect(result.text, 'ok');

      getIt.reset();
    });

    test('without an injected channel every call is channel_not_wired',
        () async {
      final getIt = GetIt.instance..reset();
      registerWebTesseractDependencies(getIt);

      final port = getIt<TesseractPort>();

      await expectLater(
        () => port.recognize(
          modelId: 'eng',
          request: const TesseractRequest(image: 'blob:x'),
        ),
        throwsA(isA<TesseractException>()
            .having((e) => e.code, 'code', 'channel_not_wired')),
      );

      getIt.reset();
    });
  });
}