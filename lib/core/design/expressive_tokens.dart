import 'package:material_ui/material_ui.dart';

/// Tokens centralisés du design system Material 3 Expressive.
class ExpressiveTokens {
  ExpressiveTokens._();

  // Espacements (spacing scale)
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 12;
  static const double spacing = 16;
  static const double spacingLg = 20;

  // Tailles d'icônes
  static const double iconSm = 18;
  static const double iconMd = 24;
  static const double iconLg = 32;
  static const double iconXl = 48;

  // Élévation expressive par défaut.
  static const double elevation0 = 0;
}

/// Palette M3 Expressive : couleurs plus saturées et émotionnelles.
/// Utilisée comme seeds dans `ColorScheme.fromSeed(dynamicSchemeVariant: expressive)`.
class ExpressivePalette {
  ExpressivePalette._();

  static const Color violetVibrant = Color(0xFF2544D8);
  static const Color magentaPlayful = Color(0xFFCF4B99);
  static const Color tealOptimist = Color(0xFF0F9D70);
  static const Color sunsetCoral = Color(0xFFD1442F);
  static const Color lemonZest = Color(0xFFC67C11);
  static const Color forestNature = Color(0xFF477A59);
  static const Color skyClarity = Color(0xFF5C6FF4);
  static const Color amberWarm = Color(0xFF905FCB);

  static const List<Color> seeds = [
    violetVibrant,
    magentaPlayful,
    tealOptimist,
    sunsetCoral,
    lemonZest,
    forestNature,
    skyClarity,
    amberWarm,
  ];
}
