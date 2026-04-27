import 'package:flutter_test/flutter_test.dart';
import 'package:toolbox_everything_mobile/core/services/timestamp_service.dart';

void main() {
  group('TimestampService', () {
    const svc = TimestampService();

    test('fromTimestamp en secondes donne la bonne date', () {
      // 2026-01-01T00:00:00Z = 1767225600
      final dt = svc.fromTimestamp(1767225600);
      expect(dt.year, 2026);
      expect(dt.month, 1);
      expect(dt.day, 1);
    });

    test('fromTimestamp en millisecondes', () {
      final dt = svc.fromTimestamp(1767225600000, milliseconds: true);
      expect(dt.year, 2026);
      expect(dt.month, 1);
    });

    test('toTimestamp en secondes', () {
      final dt = DateTime.utc(2026, 1, 1);
      expect(svc.toTimestamp(dt), 1767225600);
    });

    test('toTimestamp en millisecondes', () {
      final dt = DateTime.utc(2026, 1, 1);
      expect(svc.toTimestamp(dt, milliseconds: true), 1767225600000);
    });

    test('round-trip seconds', () {
      final ts = svc.nowSeconds();
      final dt = svc.fromTimestamp(ts);
      expect(svc.toTimestamp(dt), ts);
    });

    test('toIso renvoie une date ISO 8601', () {
      final dt = DateTime.utc(2026, 4, 25, 12, 0, 0);
      expect(svc.toIso(dt), startsWith('2026-04-25T12:00:00'));
    });
  });
}
