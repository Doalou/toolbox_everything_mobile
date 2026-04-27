import 'package:flutter_test/flutter_test.dart';
import 'package:toolbox_everything_mobile/core/services/diff_service.dart';

void main() {
  group('DiffService', () {
    const svc = DiffService();

    test('diff identique → toutes lignes en keep', () {
      final r = svc.diff('a\nb\nc', 'a\nb\nc');
      expect(r.every((l) => l.op == DiffOp.keep), isTrue);
      expect(r.length, 3);
    });

    test('ajout d\'une ligne', () {
      final r = svc.diff('a\nb', 'a\nb\nc');
      final s = svc.summary(r);
      expect(s.added, 1);
      expect(s.removed, 0);
    });

    test('suppression d\'une ligne', () {
      final r = svc.diff('a\nb\nc', 'a\nc');
      final s = svc.summary(r);
      expect(s.added, 0);
      expect(s.removed, 1);
    });

    test('ajout + suppression combinés', () {
      final r = svc.diff('un\ndeux\ntrois', 'un\nDEUX\ntrois');
      final s = svc.summary(r);
      expect(s.added, 1);
      expect(s.removed, 1);
    });

    test('texte vide vs non vide', () {
      final r = svc.diff('', 'hello');
      final s = svc.summary(r);
      expect(s.added, 1);
    });
  });
}
