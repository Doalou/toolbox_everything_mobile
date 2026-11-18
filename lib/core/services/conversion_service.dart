import 'package:toolbox_everything_mobile/core/models/unit_conversion.dart';

class ConversionService {
  final List<ConversionCategory> categories = [
    ConversionCategory(
      name: 'Longueur',
      units: [
        Unit(name: 'Millimètre', symbol: 'mm', conversionFactor: 0.001),
        Unit(name: 'Centimètre', symbol: 'cm', conversionFactor: 0.01),
        Unit(name: 'Mètre', symbol: 'm', conversionFactor: 1.0),
        Unit(name: 'Kilomètre', symbol: 'km', conversionFactor: 1000.0),
        Unit(name: 'Pouce', symbol: 'in', conversionFactor: 0.0254),
        Unit(name: 'Pied', symbol: 'ft', conversionFactor: 0.3048),
        Unit(name: 'Yard', symbol: 'yd', conversionFactor: 0.9144),
        Unit(name: 'Mile', symbol: 'mi', conversionFactor: 1609.344),
        Unit(name: 'Mille marin', symbol: 'nmi', conversionFactor: 1852.0),
      ],
    ),
    ConversionCategory(
      name: 'Masse',
      units: [
        Unit(name: 'Milligramme', symbol: 'mg', conversionFactor: 0.001),
        Unit(name: 'Gramme', symbol: 'g', conversionFactor: 1.0),
        Unit(name: 'Kilogramme', symbol: 'kg', conversionFactor: 1000.0),
        Unit(name: 'Tonne', symbol: 't', conversionFactor: 1000000.0),
        Unit(name: 'Once', symbol: 'oz', conversionFactor: 28.349523125),
        Unit(name: 'Livre', symbol: 'lb', conversionFactor: 453.59237),
        Unit(name: 'Stone', symbol: 'st', conversionFactor: 6350.29318),
      ],
    ),
    ConversionCategory(
      name: 'Température',
      units: [
        Unit(name: 'Celsius', symbol: '°C', conversionFactor: 1.0),
        Unit(name: 'Fahrenheit', symbol: '°F', conversionFactor: 1.0),
        Unit(name: 'Kelvin', symbol: 'K', conversionFactor: 1.0),
      ],
    ),
    ConversionCategory(
      name: 'Volume',
      units: [
        Unit(name: 'Millilitre', symbol: 'mL', conversionFactor: 0.001),
        Unit(name: 'Centilitre', symbol: 'cL', conversionFactor: 0.01),
        Unit(name: 'Litre', symbol: 'L', conversionFactor: 1.0),
        Unit(name: 'Mètre cube', symbol: 'm³', conversionFactor: 1000.0),
        Unit(name: 'Cuillère à café', symbol: 'càc', conversionFactor: 0.005),
        Unit(name: 'Cuillère à soupe', symbol: 'càs', conversionFactor: 0.015),
        Unit(name: 'Tasse US', symbol: 'cup', conversionFactor: 0.2365882365),
        Unit(name: 'Pinte US', symbol: 'pt', conversionFactor: 0.473176473),
        Unit(name: 'Gallon US', symbol: 'gal', conversionFactor: 3.785411784),
      ],
    ),
    ConversionCategory(
      name: 'Surface',
      units: [
        Unit(name: 'Centimètre carré', symbol: 'cm²', conversionFactor: 0.0001),
        Unit(name: 'Mètre carré', symbol: 'm²', conversionFactor: 1.0),
        Unit(name: 'Are', symbol: 'a', conversionFactor: 100.0),
        Unit(name: 'Hectare', symbol: 'ha', conversionFactor: 10000.0),
        Unit(
          name: 'Kilomètre carré',
          symbol: 'km²',
          conversionFactor: 1000000.0,
        ),
        Unit(name: 'Pied carré', symbol: 'ft²', conversionFactor: 0.09290304),
        Unit(name: 'Acre', symbol: 'ac', conversionFactor: 4046.8564224),
      ],
    ),
    ConversionCategory(
      name: 'Vitesse',
      units: [
        Unit(name: 'Mètre/seconde', symbol: 'm/s', conversionFactor: 1.0),
        Unit(
          name: 'Kilomètre/heure',
          symbol: 'km/h',
          conversionFactor: 1.0 / 3.6,
        ),
        Unit(name: 'Mile/heure', symbol: 'mph', conversionFactor: 0.44704),
        Unit(name: 'Nœud', symbol: 'kn', conversionFactor: 1852.0 / 3600.0),
      ],
    ),
    ConversionCategory(
      name: 'Temps',
      units: [
        Unit(name: 'Milliseconde', symbol: 'ms', conversionFactor: 0.001),
        Unit(name: 'Seconde', symbol: 's', conversionFactor: 1.0),
        Unit(name: 'Minute', symbol: 'min', conversionFactor: 60.0),
        Unit(name: 'Heure', symbol: 'h', conversionFactor: 3600.0),
        Unit(name: 'Jour', symbol: 'j', conversionFactor: 86400.0),
        Unit(name: 'Semaine', symbol: 'sem', conversionFactor: 604800.0),
        Unit(name: 'Année', symbol: 'an', conversionFactor: 31557600.0),
      ],
    ),
    ConversionCategory(
      name: 'Données',
      units: [
        Unit(name: 'Bit', symbol: 'b', conversionFactor: 0.125),
        Unit(name: 'Octet', symbol: 'o', conversionFactor: 1.0),
        Unit(name: 'Kilo-octet', symbol: 'Ko', conversionFactor: 1024.0),
        Unit(
          name: 'Méga-octet',
          symbol: 'Mo',
          conversionFactor: 1024.0 * 1024.0,
        ),
        Unit(
          name: 'Giga-octet',
          symbol: 'Go',
          conversionFactor: 1024.0 * 1024.0 * 1024.0,
        ),
        Unit(
          name: 'Téra-octet',
          symbol: 'To',
          conversionFactor: 1024.0 * 1024.0 * 1024.0 * 1024.0,
        ),
        Unit(
          name: 'Péta-octet',
          symbol: 'Po',
          conversionFactor: 1024.0 * 1024.0 * 1024.0 * 1024.0 * 1024.0,
        ),
      ],
    ),
    ConversionCategory(
      name: 'Pression',
      units: [
        Unit(name: 'Pascal', symbol: 'Pa', conversionFactor: 1.0),
        Unit(name: 'Hectopascal', symbol: 'hPa', conversionFactor: 100.0),
        Unit(name: 'Bar', symbol: 'bar', conversionFactor: 100000.0),
        Unit(name: 'Atmosphère', symbol: 'atm', conversionFactor: 101325.0),
        Unit(name: 'PSI', symbol: 'psi', conversionFactor: 6894.757293168),
        Unit(
          name: 'Millimètre de mercure',
          symbol: 'mmHg',
          conversionFactor: 133.322387415,
        ),
      ],
    ),
    ConversionCategory(
      name: 'Énergie',
      units: [
        Unit(name: 'Joule', symbol: 'J', conversionFactor: 1.0),
        Unit(name: 'Kilojoule', symbol: 'kJ', conversionFactor: 1000.0),
        Unit(name: 'Calorie', symbol: 'cal', conversionFactor: 4.184),
        Unit(name: 'Kilocalorie', symbol: 'kcal', conversionFactor: 4184.0),
        Unit(name: 'Watt-heure', symbol: 'Wh', conversionFactor: 3600.0),
        Unit(
          name: 'Kilowatt-heure',
          symbol: 'kWh',
          conversionFactor: 3600000.0,
        ),
      ],
    ),
  ];

  double convert(
    double value,
    Unit from,
    Unit to,
    ConversionCategory category,
  ) {
    if (identical(from, to) || from.name == to.name) {
      return value;
    }
    if (category.name == 'Température') {
      return _convertTemperature(value, from.name, to.name);
    }

    final baseValue = value * from.conversionFactor;
    return baseValue / to.conversionFactor;
  }

  double _convertTemperature(double value, String from, String to) {
    if (from == to) return value;

    var celsius = value;
    if (from == 'Fahrenheit') {
      celsius = (value - 32) * 5 / 9;
    } else if (from == 'Kelvin') {
      celsius = value - 273.15;
    }

    if (to == 'Fahrenheit') return celsius * 9 / 5 + 32;
    if (to == 'Kelvin') return celsius + 273.15;
    return celsius;
  }

  String formatValue(double value) {
    if (value.isNaN || value.isInfinite) return '';
    if (value.abs() < 1e-12) return '0';

    if (value.abs() >= 1e9 || value.abs() < 1e-6) {
      final raw = value.toStringAsExponential(4);
      final parts = raw.split('e');
      final mantissa = parts[0]
          .replaceFirst(RegExp(r'0+$'), '')
          .replaceFirst(RegExp(r'\.$'), '');
      return '$mantissa'
          'e${parts[1]}';
    }

    var formatted = value.toStringAsFixed(6);
    if (formatted.contains('.')) {
      formatted = formatted
          .replaceFirst(RegExp(r'0+$'), '')
          .replaceFirst(RegExp(r'\.$'), '');
    }
    if (formatted == '-0') return '0';
    return formatted;
  }
}
