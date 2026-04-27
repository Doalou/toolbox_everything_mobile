import 'package:flutter_test/flutter_test.dart';
import 'package:toolbox_everything_mobile/core/services/regex_service.dart';

void main() {
  group('RegexService', () {
    const svc = RegexService();

    test('findAll trouve toutes les correspondances', () {
      final matches = svc.findAll(r'\d+', 'a1 b22 c333');
      expect(matches.length, 3);
      expect(matches[0].text, '1');
      expect(matches[1].text, '22');
      expect(matches[2].text, '333');
    });

    test('findAll respecte caseSensitive=false', () {
      final m = svc.findAll(
        'hello',
        'Hello world hello!',
        caseSensitive: false,
      );
      expect(m.length, 2);
    });

    test('findAll fournit start/end correctement', () {
      final m = svc.findAll(r'\d+', 'abc123def');
      expect(m.first.start, 3);
      expect(m.first.end, 6);
    });

    test('replaceAll supporte les groupes', () {
      final out = svc.replaceAll(r'(\w+)@(\w+)', 'foo@bar baz@qux', r'$2/$1');
      expect(out, 'bar/foo qux/baz');
    });

    test('compile lance FormatException sur regex invalide', () {
      expect(() => svc.compile(r'['), throwsFormatException);
    });

    test('groups expose les sous-groupes', () {
      final m = svc.findAll(r'(\d+)-(\w+)', '1-foo 2-bar');
      expect(m.first.groups[0], '1-foo');
      expect(m.first.groups[1], '1');
      expect(m.first.groups[2], 'foo');
    });
  });
}
