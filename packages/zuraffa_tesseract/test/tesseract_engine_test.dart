import 'package:test/test.dart';
import 'package:zuraffa_tesseract/zuraffa_tesseract.dart';

void main() {
  group('TesseractEngine', () {
    test('parses the wire values', () {
      expect(TesseractEngine.tryParse('vision'), TesseractEngine.vision);
      expect(TesseractEngine.tryParse('tesseract'), TesseractEngine.tesseract);
      expect(
        TesseractEngine.tryParse('defaultEngine'),
        TesseractEngine.defaultEngine,
      );
    });

    test('accepts the enum names and the bare default spelling', () {
      expect(TesseractEngine.tryParse('default'), TesseractEngine.defaultEngine);
      expect(TesseractEngine.tryParse('VISION'), TesseractEngine.vision);
      expect(TesseractEngine.tryParse('  Tesseract '), TesseractEngine.tesseract);
    });

    test('passes an already-parsed engine through', () {
      expect(
        TesseractEngine.tryParse(TesseractEngine.vision),
        TesseractEngine.vision,
      );
    });

    test('rejects unknown and non-string values', () {
      expect(TesseractEngine.tryParse('tensorflow'), isNull);
      expect(TesseractEngine.tryParse(null), isNull);
      expect(TesseractEngine.tryParse(42), isNull);
    });
  });

  group('TesseractRequest', () {
    test('defaults to the platform default engine', () {
      const request = TesseractRequest(image: '/tmp/a.png');
      expect(request.engine, TesseractEngine.defaultEngine);
      expect(request.usesVision, isFalse);
    });

    test('encodes the engine at the top level', () {
      const request = TesseractRequest(
        image: '/tmp/a.png',
        engine: TesseractEngine.vision,
      );
      final args = request.encode();

      expect(args['engine'], 'vision');
      expect(request.usesVision, isTrue);
    });

    test('carries language, tessdata and options alongside the engine', () {
      final request = TesseractRequest(
        image: 'blob:https://example.com/x',
        language: 'eng+tur',
        engine: TesseractEngine.tesseract,
        tessDataPath: '/srv/tessdata',
        options: const <String, String>{'preserve_interword_spaces': '1'},
      );
      final args = request.encode();

      expect(args, <String, Object?>{
        'imagePath': 'blob:https://example.com/x',
        'language': 'eng+tur',
        'engine': 'tesseract',
        'tessData': '/srv/tessdata',
        'options': <String, String>{'preserve_interword_spaces': '1'},
      });
    });

    test('omits tessdata and options when unset', () {
      final args = const TesseractRequest(image: '/tmp/a.png').encode();

      expect(args.containsKey('tessData'), isFalse);
      expect(args.containsKey('options'), isFalse);
    });
  });
}
