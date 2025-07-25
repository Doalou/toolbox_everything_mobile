class Unit {
  final String name;
  final double conversionFactor; // Factor to convert FROM the base unit

  Unit({required this.name, required this.conversionFactor});
}

class ConversionCategory {
  final String name;
  final List<Unit> units;
  final String baseUnitName; // e.g., 'Meters' for Length

  ConversionCategory({required this.name, required this.units, required this.baseUnitName});
} 