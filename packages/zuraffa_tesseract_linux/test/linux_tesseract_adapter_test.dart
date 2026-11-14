// Adapter tests over a fake injected channel (success, empty result, taxonomy,
// timeout, engine gate, unwired) — no platform required.
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:zuraffa/zuraffa.dart';
import 'package:zuraffa_tesseract/zuraffa_tesseract.dart';
import 'package:zuraffa_tesseract_linux/zuraffa_tesseract_linux.dart';

void main() {
  group('LinuxTesseractAdapter', () {
    test('recognize decodes the extracted text', () async {
      final channel = LinuxTesseractChannel(invoke: (method, args) async {
        expect(method, 'extractText');
        expect(args['imagePath'], '/tmp/shot.png');
        expect(args['language'], 'eng');
        return <String, Object?>{'text': 'hello world'};
      });
      final port = LinuxTesseractPort(channel: channel);

      final result = await port.recognize(
        modelId: 'eng',
        request: const TesseractRequest(image: '/tmp/shot.png'),
      );

      expect(result.text, 'hello world');
      expect(result.isEmpty, isFalse);
    });

    test('an empty result decodes as empty, not an error', () async {
      final channel = LinuxTesseractChannel(
        invoke: (_, __) async => <String, Object?>{'text': ''});
      final port = LinuxTesseractPort(channel: channel);

      final result = await port.recognize(
        modelId: 'eng',
        request: const TesseractRequest(image: '/tmp/blank.png'),
      );

      expect(result.isEmpty, isTrue);
    });

    test('a null payload decodes as empty, not a malformed response',
        () async {
      final channel = LinuxTesseractChannel(invoke: (_, __) async => null);
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
      final channel = LinuxTesseractChannel(invoke: (_, __) async {
        calls++;
        return '';
      });
      final port = LinuxTesseractPort(channel: channel);

      await expectLater(
        () => port.loadModel(id: 'eng', bytes: Uint8List(0)),
        throwsA(isA<TesseractException>()
            .having((e) => e.code, 'code', 'empty_model')),
      );
      expect(calls, 0);
    });

    test('native error payloads surface as typed failures', () async {
      final channel = LinuxTesseractChannel(invoke: (_, __) async {
        return <String, Object?>{
          'error': <String, Object?>{
            'code': 'TESSDATA_NOT_FOUND',
            'message': 'no eng.traineddata',
          },
        };
      });
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
      final channel = LinuxTesseractChannel(invoke: (_, __) async {
        return <String, Object?>{
          'error': <String, Object?>{'code': 'OCR_TIMEOUT', 'message': 'slow'},
        };
      });
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

    test('a recognition past the timeout is a recoverable timeout', () async {
      final channel = LinuxTesseractChannel(
        invoke: (_, __) =>
            Future<String>.delayed(const Duration(seconds: 5), () => 'late'),
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

    test('vision is rejected before the transport is touched', () async {
      var calls = 0;
      final channel = LinuxTesseractChannel(invoke: (_, __) async {
        calls++;
        return 'should not run';
      });
      final port = LinuxTesseractPort(channel: channel);

      await expectLater(
        () => port.recognize(
          modelId: 'eng',
          request: const TesseractRequest(
            image: '/tmp/a.png',
            engine: TesseractEngine.vision,
          ),
        ),
        throwsA(isA<TesseractException>()
            .having((e) => e.code, 'code', 'unsupported_engine')
            .having((e) => e.recoverable, 'recoverable', isFalse)),
      );
      expect(calls, 0, reason: 'the native side never sees a vision request');
    });

    test('the selected engine reaches the channel', () async {
      String? seen;
      final channel = LinuxTesseractChannel(invoke: (_, args) async {
        seen = args['engine'] as String?;
        return <String, Object?>{'text': 'ok'};
      });
      final port = LinuxTesseractPort(channel: channel);

      await port.recognize(
        modelId: 'eng',
        request: const TesseractRequest(
          image: '/tmp/a.png',
          engine: TesseractEngine.tesseract,
        ),
      );

      expect(seen, 'tesseract');
    });

    test('registerLinuxTesseractDependencies resolves over the wired channel', () async {
      final getIt = GetIt.instance..reset();
      registerLinuxTesseractDependencies(
        getIt,
        channel: LinuxTesseractChannel(
            invoke: (_, __) async => <String, Object?>{'text': 'ok'}),
      );

      final port = getIt<TesseractPort>();
      final result = await port.recognize(
        modelId: 'eng',
        request: const TesseractRequest(image: '/tmp/a.png'),
      );
      expect(result.text, 'ok');

      getIt.reset();
    });

    test('without an injected channel every call is channel_not_wired',
        () async {
      final getIt = GetIt.instance..reset();
      registerLinuxTesseractDependencies(getIt);

      final port = getIt<TesseractPort>();

      await expectLater(
        () => port.recognize(
          modelId: 'eng',
          request: const TesseractRequest(image: '/tmp/a.png'),
        ),
        throwsA(isA<TesseractException>()
            .having((e) => e.code, 'code', 'channel_not_wired')),
      );

      getIt.reset();
    });
  });
}
