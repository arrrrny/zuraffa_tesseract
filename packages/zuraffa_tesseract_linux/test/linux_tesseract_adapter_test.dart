// Adapter tests over a fake injected channel (success, taxonomy, timeout,
// unwired) — no platform required.
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:zuraffa/zuraffa.dart';
import 'package:zuraffa_tesseract/zuraffa_tesseract.dart';
import 'package:zuraffa_tesseract_linux/zuraffa_tesseract_linux.dart';

void main() {
  group('LinuxTesseractAdapter', () {
    test('isSupported decodes the native payload', () async {
      final channel = LinuxTesseractChannel(
        invoke: (_, __) async => <String, Object?>{'supported': true},
      );
      final port = LinuxTesseractPort(channel: channel);

      expect(await port.isSupported(), isTrue);
    });

    test('recognize decodes the extracted text', () async {
      final channel = LinuxTesseractChannel(
        invoke: (method, args) async {
          expect(method, 'extractText');
          expect(args['imagePath'], '/tmp/shot.png');
          expect(args['language'], 'eng');
          return <String, Object?>{'text': 'hello world'};
        },
      );
      final port = LinuxTesseractPort(channel: channel);

      final result = await port.recognize(
        modelId: 'eng',
        request: const TesseractRequest(image: '/tmp/shot.png'),
      );

      expect(result.text, 'hello world');
      expect(result.isEmpty, isFalse);
    });

    test('a null text payload decodes as empty, not an error', () async {
      final channel = LinuxTesseractChannel(
        invoke: (_, __) async => <String, Object?>{},
      );
      final port = LinuxTesseractPort(channel: channel);

      final result = await port.recognize(
        modelId: 'eng',
        request: const TesseractRequest(image: '/tmp/blank.png'),
      );

      expect(result.isEmpty, isTrue);
    });

    test('loadModel rejects empty traineddata before touching the channel',
        () async {
      var calls = 0;
      final channel = LinuxTesseractChannel(
        invoke: (_, __) async {
          calls++;
          return <String, Object?>{};
        },
      );
      final port = LinuxTesseractPort(channel: channel);

      await expectLater(
        () => port.loadModel(id: 'eng', bytes: Uint8List(0)),
        throwsA(isA<TesseractException>()
            .having((e) => e.code, 'code', 'empty_model')),
      );
      expect(calls, 0);
    });

    test('native error payloads surface as typed failures', () async {
      final channel = LinuxTesseractChannel(
        invoke: (_, __) async => <String, Object?>{
          'error': <String, Object?>{
            'code': 'TESSDATA_NOT_FOUND',
            'message': 'no eng.traineddata',
          },
        },
      );
      final port = LinuxTesseractPort(channel: channel);

      await expectLater(
        () => port.recognize(
          modelId: 'eng',
          request: const TesseractRequest(image: '/tmp/shot.png'),
        ),
        throwsA(isA<TesseractException>()
            .having((e) => e.code, 'code', 'TESSDATA_NOT_FOUND')
            .having((e) => e.recoverable, 'recoverable', isFalse)),
      );
    });

    test('a recoverable native code is marked recoverable', () async {
      final channel = LinuxTesseractChannel(
        invoke: (_, __) async => <String, Object?>{
          'error': <String, Object?>{'code': 'OCR_TIMEOUT', 'message': 'slow'},
        },
      );
      final port = LinuxTesseractPort(channel: channel);

      await expectLater(
        () => port.recognize(
          modelId: 'eng',
          request: const TesseractRequest(image: '/tmp/shot.png'),
        ),
        throwsA(isA<TesseractException>()
            .having((e) => e.code, 'code', 'OCR_TIMEOUT')
            .having((e) => e.recoverable, 'recoverable', isTrue)),
      );
    });

    test('a recognition past the timeout is a recoverable timeout',
        () async {
      final channel = LinuxTesseractChannel(
        invoke: (_, __) => Future<Object?>.delayed(
          const Duration(seconds: 5),
          () => <String, Object?>{'text': 'late'},
        ),
        timeout: const Duration(milliseconds: 50),
      );
      final port = LinuxTesseractPort(channel: channel);

      await expectLater(
        () => port.recognize(
          modelId: 'eng',
          request: const TesseractRequest(image: '/tmp/shot.png'),
        ),
        throwsA(isA<TesseractException>()
            .having((e) => e.code, 'code', 'timeout')
            .having((e) => e.recoverable, 'recoverable', isTrue)),
      );
    });

    test('registerLinuxTesseractDependencies resolves over the wired port',
        () async {
      final getIt = GetIt.instance..reset();
      registerLinuxTesseractDependencies(
        getIt,
        channel: LinuxTesseractChannel(
          invoke: (_, __) async => <String, Object?>{'supported': true},
        ),
      );

      final port = getIt<TesseractPort>();
      expect(await port.isSupported(), isTrue);

      getIt.reset();
    });

    test('without an injected channel every call is channel_not_wired',
        () async {
      final getIt = GetIt.instance..reset();
      registerLinuxTesseractDependencies(getIt);

      final port = getIt<TesseractPort>();

      await expectLater(
        () => port.isSupported(),
        throwsA(isA<TesseractException>()
            .having((e) => e.code, 'code', 'channel_not_wired')),
      );

      getIt.reset();
    });
  });
}