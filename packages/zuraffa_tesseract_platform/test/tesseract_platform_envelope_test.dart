import 'dart:async';

import 'package:test/test.dart';
import 'package:zuraffa_tesseract_platform/zuraffa_tesseract_platform.dart';

class _FakeFailure implements Exception {
  final String code;
  final String message;
  final bool recoverable;

  const _FakeFailure(this.code, this.message, {required this.recoverable});

  @override
  String toString() => '$code|$message|$recoverable';
}

_FakeFailure typed(String code, String message, {required bool recoverable}) =>
    _FakeFailure(code, message, recoverable: recoverable);

void main() {
  group('TesseractPlatformEnvelope', () {
    test('a successful call decodes the payload map', () async {
      final envelope = TesseractPlatformEnvelope(
        invoke: (method, args) async => <String, Object?>{
          'text': 'hello',
          'count': 2,
        },
        onTyped: typed,
      );

      final result = await envelope.call('extractText', const {});

      expect(result?['text'], 'hello');
      expect(result?['count'], 2);
    });

    test('a null payload decodes as null, not a malformed response',
        () async {
      final envelope = TesseractPlatformEnvelope(
        invoke: (_, __) async => null,
        onTyped: typed,
      );

      expect(await envelope.call('extractText', const {}), isNull);
    });

    test('a non-map payload is a malformed_response failure', () async {
      final envelope = TesseractPlatformEnvelope(
        invoke: (_, __) async => 'not a map',
        onTyped: typed,
      );

      await expectLater(
        () => envelope.call('extractText', const {}),
        throwsA(predicate(
          (Object e) => e.toString().startsWith('malformed_response|'),
        )),
      );
    });

    test('a native error map is mapped through the taxonomy hook',
        () async {
      final envelope = TesseractPlatformEnvelope(
        invoke: (_, __) async => <String, Object?>{
          'error': <String, Object?>{'code': 'OCR_TIMEOUT', 'message': 'slow'},
        },
        onTyped: typed,
        mapNativeError: (code, message) =>
            code == 'OCR_TIMEOUT' ? typed(code, message, recoverable: true) : null,
      );

      await expectLater(
        () => envelope.call('extractText', const {}),
        throwsA(predicate((Object e) => e.toString() == 'OCR_TIMEOUT|slow|true')),
      );
    });

    test('an unmapped native code falls through to the adapter factory',
        () async {
      final envelope = TesseractPlatformEnvelope(
        invoke: (_, __) async => <String, Object?>{
          'error': <String, Object?>{'code': 'TESSDATA_NOT_FOUND'},
        },
        onTyped: typed,
        mapNativeError: (_, __) => null,
      );

      await expectLater(
        () => envelope.call('extractText', const {}),
        throwsA(predicate(
          (Object e) => e.toString().startsWith('TESSDATA_NOT_FOUND|'),
        )),
      );
    });

    test('a thrown transport failure becomes a non-recoverable channel_error',
        () async {
      final envelope = TesseractPlatformEnvelope(
        invoke: (_, __) => throw StateError('messenger gone'),
        onTyped: typed,
      );

      await expectLater(
        () => envelope.call('extractText', const {}),
        throwsA(predicate((Object e) =>
            e.toString().contains('channel_error|') &&
            e.toString().endsWith('|false'))),
      );
    });

    test('a typed failure from the transport passes through unwrapped',
        () async {
      final marker = typed('already_mine', 'thrown by the adapter', recoverable: true);
      final envelope = TesseractPlatformEnvelope(
        invoke: (_, __) => throw marker,
        onTyped: typed,
        isTypedError: (Object error) => error == marker,
      );

      await expectLater(
        () => envelope.call('extractText', const {}),
        throwsA(same(marker)),
      );
    });

    test('a call past the timeout is a recoverable timeout', () async {
      final envelope = TesseractPlatformEnvelope(
        invoke: (_, __) => Future<Object?>.delayed(
          const Duration(seconds: 5),
          () => <String, Object?>{'text': 'late'},
        ),
        onTyped: typed,
        timeout: const Duration(milliseconds: 50),
      );

      await expectLater(
        () => envelope.call('extractText', const {}),
        throwsA(predicate((Object e) => e.toString() == 'timeout|The platform call exceeded the timeout window.|true')),
      );
    });
  });
}