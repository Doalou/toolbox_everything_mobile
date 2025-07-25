import 'package:toolbox_everything_mobile/core/models/unit_conversion.dart';

class ConversionService {
  final List<ConversionCategory> categories = [
    ConversionCategory(
      name: 'Longueur',
      baseUnitName: 'Mètre',
      units: [
        Unit(name: 'Mètre', conversionFactor: 1.0),
        Unit(name: 'Kilomètre', conversionFactor: 1000.0),
        Unit(name: 'Mile', conversionFactor: 1609.34),
        Unit(name: 'Pied', conversionFactor: 0.3048),
      ],
    ),
    ConversionCategory(
      name: 'Poids',
      baseUnitName: 'Gramme',
      units: [
        Unit(name: 'Gramme', conversionFactor: 1.0),
        Unit(name: 'Kilogramme', conversionFactor: 1000.0),
        Unit(name: 'Livre', conversionFactor: 453.592),
        Unit(name: 'Once', conversionFactor: 28.3495),
      ],
    ),
    ConversionCategory(
      name: 'Température',
      baseUnitName: 'Celsius',
      units: [
        Unit(name: 'Celsius', conversionFactor: 1.0),
        Unit(name: 'Fahrenheit', conversionFactor: 1.0), // Special handling
        Unit(name: 'Kelvin', conversionFactor: 1.0), // Special handling
      ],
    ),
     ConversionCategory(
      name: 'Données',
      baseUnitName: 'Octet',
      units: [
        Unit(name: 'Octet', conversionFactor: 1.0),
        Unit(name: 'Kilo-octet', conversionFactor: 1024.0),
        Unit(name: 'Méga-octet', conversionFactor: 1024.0 * 1024.0),
        Unit(name: 'Giga-octet', conversionFactor: 1024.0 * 1024.0 * 1024.0),
      ],
    ),
  ];

  double convert(double value, Unit from, Unit to, ConversionCategory category) {
    if (category.name == 'Température') {
      return _convertTemperature(value, from.name, to.name);
    }
    
    // Convert 'from' unit to the base unit of the category
    double baseValue = value * from.conversionFactor;
    
    // Convert the base unit to the 'to' unit
    double result = baseValue / to.conversionFactor;
    
    return result;
  }

  double _convertTemperature(double value, String from, String to) {
    if (from == to) return value;

    // To Celsius
    if (from == 'Fahrenheit') value = (value - 32) * 5 / 9;
    if (from == 'Kelvin') value = value - 273.15;

    // From Celsius
    if (to == 'Fahrenheit') return value * 9 / 5 + 32;
    if (to == 'Kelvin') return value + 273.15;
    
    return value; // Should be Celsius
  }
} 