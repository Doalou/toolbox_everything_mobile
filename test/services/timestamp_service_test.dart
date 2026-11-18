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

    test('tryParseDate analyse ISO 8601 et DD/MM/YYYY HH:MM:SS', () {
      final iso = svc.tryParseDate('2026-01-01T00:00:00Z');
      expect(iso, isNotNull);
      expect(svc.toTimestamp(iso!), 1767225600);

      final fr = svc.tryParseDate('01/01/2026 00:00:00', utc: true);
      expect(fr, isNotNull);
      expect(svc.toTimestamp(fr!), 1767225600);

      final frShort = svc.tryParseDate('18/11/2026 14:30', utc: true);
      expect(frShort, DateTime.utc(2026, 11, 18, 14, 30));

      expect(svc.tryParseDate('31/02/2026'), isNull);
      expect(svc.tryParseDate('pas une date'), isNull);
    });

    test('relativeFromNow formate passé, présent et futur', () {
      final ref = DateTime.utc(2026, 11, 18, 12, 0, 0);
      expect(svc.relativeFromNow(ref, reference: ref), 'à l’instant');
      expect(
        svc.relativeFromNow(
          ref.subtract(const Duration(minutes: 5)),
          reference: ref,
        ),
        'il y a 5 min',
      );
      expect(
        svc.relativeFromNow(ref.add(const Duration(days: 2)), reference: ref),
        'dans 2 j',
      );
    });
  });
}
