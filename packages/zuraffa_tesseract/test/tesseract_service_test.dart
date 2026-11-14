import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart';
import 'package:zuraffa_tesseract/zuraffa_tesseract.dart';

/// A fake port: records calls and replays canned answers, so the facade's
/// lifecycle rules are tested without a platform.
class _FakePort implements TesseractPort {
  _FakePort({
    this.supported = true,
    this.failLoad = false,
  });

  bool supported;
  bool failLoad;
  int loadCalls = 0;
  int recognizeCalls = 0;
  int unloadCalls = 0;
  TesseractRequest? lastRequest;

  @override
  Future<bool> isSupported() async => supported;

  @override
  Future<TesseractModel> loadModel({
    required String id,
    required Uint8List bytes,
  }) async {
    loadCalls++;
    if (failLoad) {
      throw const TesseractException(
        'load_failed',
        'the engine rejected the model',
        recoverable: false,
      );
    }
    return TesseractModel(id: id, byteLength: bytes.lengthInBytes);
  }

  @override
  Future<TesseractText> recognize({
    required String modelId,
    required TesseractRequest request,
  }) async {
    recognizeCalls++;
    lastRequest = request;
    return TesseractText('text for $modelId at ${request.image}');
  }

  @override
  Future<void> unloadModel({required String id}) async {
    unloadCalls++;
  }
}

void main() {
  group('TesseractService', () {
    test('supported delegates to the port', () async {
      final service = TesseractService(port: _FakePort(supported: false));
      expect(await service.supported(), isFalse);
    });

    test('loadModel registers the model and rejects a double load',
        () async {
      final port = _FakePort();
      final service = TesseractService(port: port);

      final model = await service.loadModel(
        id: 'eng',
        bytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
      );

      expect(model.id, 'eng');
      expect(model.byteLength, 4);
      expect(service.loadedModels, <String>{'eng'});
      expect(port.loadCalls, 1);

      await expectLater(
        () => service.loadModel(
          id: 'eng',
          bytes: Uint8List(4),
        ),
        throwsA(isA<TesseractException>()
            .having((e) => e.code, 'code', 'already_loaded')),
      );
      expect(port.loadCalls, 1, reason: 'the port is not called twice');
    });

    test('recognize forwards the request and decodes the text', () async {
      final port = _FakePort();
      final service = TesseractService(port: port);
      await service.loadModel(id: 'eng', bytes: Uint8List(2));

      final result = await service.recognize(
        modelId: 'eng',
        request: TesseractRequest(
          image: '/tmp/shot.png',
          language: 'eng+tur',
          options: const <String, String>{'preserve_interword_spaces': '1'},
        ),
      );

      expect(result.text, contains('text for eng'));
      expect(port.lastRequest?.language, 'eng+tur');
      expect(port.lastRequest?.options['preserve_interword_spaces'], '1');
      expect(port.lastRequest?.encode()['imagePath'], '/tmp/shot.png');
    });

    test('recognize before load is a typed failure, not a port call',
        () async {
      final port = _FakePort();
      final service = TesseractService(port: port);

      await expectLater(
        () => service.recognize(
          modelId: 'eng',
          request: const TesseractRequest(image: '/tmp/shot.png'),
        ),
        throwsA(isA<TesseractException>()
            .having((e) => e.code, 'code', 'not_loaded')
            .having((e) => e.recoverable, 'recoverable', isFalse)),
      );
      expect(port.recognizeCalls, 0);
    });

    test('unloadModel releases the id so it can be loaded again', () async {
      final port = _FakePort();
      final service = TesseractService(port: port);
      await service.loadModel(id: 'eng', bytes: Uint8List(1));

      await service.unloadModel(id: 'eng');

      expect(service.loadedModels, isEmpty);
      expect(port.unloadCalls, 1);

      await service.loadModel(id: 'eng', bytes: Uint8List(1));
      expect(port.loadCalls, 2);
    });

    test('a port failure propagates unchanged', () async {
      final service = TesseractService(port: _FakePort(failLoad: true));

      await expectLater(
        () => service.loadModel(id: 'eng', bytes: Uint8List(1)),
        throwsA(isA<TesseractException>()
            .having((e) => e.code, 'code', 'load_failed')),
      );
      expect(service.loadedModels, isEmpty);
    });

    test('TesseractText decodes null as empty and rejects non-strings',
        () async {
      expect(TesseractText.decode(null).isEmpty, isTrue);
      expect(TesseractText.decode('hello').text, 'hello');
      expect(
        () => TesseractText.decode(42),
        throwsA(isA<TesseractException>()
            .having((e) => e.code, 'code', 'malformed_value')),
      );
    });

    test('registerTesseractDependencies resolves over the wired port',
        () async {
      final getIt = GetIt.instance;
      final port = _FakePort();
      registerTesseractDependencies(getIt, port: port);

      final service = getIt<TesseractService>();
      expect(await service.supported(), isTrue);

      getIt.reset();
    });

    test('without a wired port every call surfaces port_not_wired', () async {
      final getIt = GetIt.instance..reset();
      registerTesseractDependencies(getIt);

      final service = getIt<TesseractService>();

      await expectLater(
        () => service.supported(),
        throwsA(isA<TesseractException>()
            .having((e) => e.code, 'code', 'port_not_wired')),
      );

      getIt.reset();
    });
  });
}