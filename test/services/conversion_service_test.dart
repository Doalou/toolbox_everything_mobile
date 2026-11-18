import 'package:flutter_test/flutter_test.dart';
import 'package:toolbox_everything_mobile/core/services/conversion_service.dart';

void main() {
  group('ConversionService', () {
    final svc = ConversionService();

    test('expose 10 catégories avec symboles et unités', () {
      expect(svc.categories, hasLength(10));
      for (final category in svc.categories) {
        expect(category.units, isNotEmpty);
        for (final unit in category.units) {
          expect(unit.symbol, isNotEmpty);
        }
      }
    });

    test('convertit correctement longueurs, masses et données', () {
      final length = svc.categories.firstWhere((c) => c.name == 'Longueur');
      final m = length.units.firstWhere((u) => u.symbol == 'm');
      final cm = length.units.firstWhere((u) => u.symbol == 'cm');
      final inch = length.units.firstWhere((u) => u.symbol == 'in');

      expect(svc.convert(1.5, m, cm, length), closeTo(150.0, 1e-9));
      expect(svc.convert(2.54, cm, inch, length), closeTo(1.0, 1e-6));

      final data = svc.categories.firstWhere((c) => c.name == 'Données');
      final byte = data.units.firstWhere((u) => u.symbol == 'o');
      final bit = data.units.firstWhere((u) => u.symbol == 'b');
      final mo = data.units.firstWhere((u) => u.symbol == 'Mo');
      final ko = data.units.firstWhere((u) => u.symbol == 'Ko');

      expect(svc.convert(1, byte, bit, data), closeTo(8.0, 1e-9));
      expect(svc.convert(2, mo, ko, data), closeTo(2048.0, 1e-9));
    });

    test('convertit températures positives et négatives', () {
      final temp = svc.categories.firstWhere((c) => c.name == 'Température');
      final c = temp.units.firstWhere((u) => u.symbol == '°C');
      final f = temp.units.firstWhere((u) => u.symbol == '°F');
      final k = temp.units.firstWhere((u) => u.symbol == 'K');

      expect(svc.convert(-40, c, f, temp), closeTo(-40.0, 1e-9));
      expect(svc.convert(0, c, f, temp), closeTo(32.0, 1e-9));
      expect(svc.convert(0, c, k, temp), closeTo(273.15, 1e-9));
      expect(svc.convert(0, k, c, temp), closeTo(-273.15, 1e-9));
    });

    test('convertit pression, vitesse, volume, surface, temps, énergie', () {
      final speed = svc.categories.firstWhere((c) => c.name == 'Vitesse');
      final ms = speed.units.firstWhere((u) => u.symbol == 'm/s');
      final kmh = speed.units.firstWhere((u) => u.symbol == 'km/h');
      expect(svc.convert(10, ms, kmh, speed), closeTo(36.0, 1e-9));

      final pressure = svc.categories.firstWhere((c) => c.name == 'Pression');
      final bar = pressure.units.firstWhere((u) => u.symbol == 'bar');
      final hpa = pressure.units.firstWhere((u) => u.symbol == 'hPa');
      expect(svc.convert(1, bar, hpa, pressure), closeTo(1000.0, 1e-9));

      final energy = svc.categories.firstWhere((c) => c.name == 'Énergie');
      final kwh = energy.units.firstWhere((u) => u.symbol == 'kWh');
      final kj = energy.units.firstWhere((u) => u.symbol == 'kJ');
      expect(svc.convert(1, kwh, kj, energy), closeTo(3600.0, 1e-9));
    });

    test(
      'formatValue supprime les zéros inutiles et gère les petites valeurs',
      () {
        expect(svc.formatValue(150.0), '150');
        expect(svc.formatValue(0.001), '0.001');
        expect(svc.formatValue(-0.0), '0');
        expect(svc.formatValue(12.340000), '12.34');
        expect(svc.formatValue(1e-8), '1e-8');
        expect(svc.formatValue(double.nan), '');
      },
    );
  });
}
