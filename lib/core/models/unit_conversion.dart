class Unit {
  final String name;
  final String symbol;

  /// Facteur multiplicatif vers l'unité de base de la catégorie.
  final double conversionFactor;

  Unit({required this.name, this.symbol = '', required this.conversionFactor});
}

class ConversionCategory {
  final String name;
  final List<Unit> units;

  ConversionCategory({required this.name, required this.units});
}
