import 'package:flutter_test/flutter_test.dart';
import 'package:toolbox_everything_mobile/core/services/uuid_service.dart';

void main() {
  group('UuidService', () {
    final svc = UuidService();

    test('v4 a le bon format (8-4-4-4-12)', () {
      final id = svc.v4();
      expect(svc.isValid(id), isTrue);
      expect(id.length, 36);
      expect(id[8], '-');
      expect(id[13], '-');
      expect(id[18], '-');
      expect(id[23], '-');
    });

    test('v4 a le bit de version 4', () {
      final id = svc.v4();
      expect(id[14], '4');
    });

    test('v4 a la variant 10xx (8/9/a/b)', () {
      final id = svc.v4();
      expect('89ab'.contains(id[19].toLowerCase()), isTrue);
    });

    test('v4Many génère bien N UUID uniques', () {
      final ids = svc.v4Many(100);
      expect(ids.length, 100);
      expect(ids.toSet().length, 100);
    });

    test('isValid rejette les chaînes mal formées', () {
      expect(svc.isValid(''), isFalse);
      expect(svc.isValid('not-a-uuid'), isFalse);
      expect(svc.isValid('12345678-1234-1234-1234-12345678901'), isFalse);
    });
  });
}
