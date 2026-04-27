import 'package:flutter_test/flutter_test.dart';
import 'package:toolbox_everything_mobile/core/services/json_formatter_service.dart';

void main() {
  group('JsonFormatterService', () {
    const svc = JsonFormatterService();

    test('prettify indente correctement avec 2 espaces', () {
      final out = svc.prettify('{"a":1,"b":[1,2]}');
      expect(out, contains('  "a"'));
      expect(out.split('\n').length, greaterThan(1));
    });

    test('prettify indente avec 4 espaces si demandé', () {
      final out = svc.prettify('{"a":1}', indent: 4);
      expect(out, contains('    "a"'));
    });

    test('minify supprime espaces et nouvelles lignes', () {
      const input = '{\n  "a": 1,\n  "b": 2\n}';
      expect(svc.minify(input), '{"a":1,"b":2}');
    });

    test('isValid détecte un JSON valide', () {
      expect(svc.isValid('{"a":1}'), isTrue);
      expect(svc.isValid('[1,2,3]'), isTrue);
      expect(svc.isValid('"chaine"'), isTrue);
      expect(svc.isValid('null'), isTrue);
    });

    test('isValid rejette une entrée invalide', () {
      expect(svc.isValid(''), isFalse);
      expect(svc.isValid('{a:1}'), isFalse);
      expect(svc.isValid('{"a":}'), isFalse);
    });

    test('prettify lance FormatException sur entrée invalide', () {
      expect(() => svc.prettify('{not json}'), throwsFormatException);
    });
  });
}
