import 'package:flutter/material.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_motion.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_shapes.dart';

/// Tokens centralisés du design system Material 3 Expressive.
class ExpressiveTokens {
  ExpressiveTokens._();

  // Espacements (spacing scale)
  static const double spacingXxs = 2;
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 12;
  static const double spacing = 16;
  static const double spacingLg = 20;
  static const double spacingXl = 24;
  static const double spacingXxl = 32;
  static const double spacingXxxl = 48;

  // Tailles d'icônes
  static const double iconSm = 18;
  static const double iconMd = 24;
  static const double iconLg = 32;
  static const double iconXl = 48;

  // Élévations expressives — plus subtiles que M3 classique.
  static const double elevation0 = 0;
  static const double elevation1 = 1;
  static const double elevation2 = 3;
  static const double elevation3 = 6;
  static const double elevation4 = 8;
  static const double elevation5 = 12;
}

/// Palette M3 Expressive : couleurs plus saturées et émotionnelles.
/// Utilisée comme seeds dans `ColorScheme.fromSeed(dynamicSchemeVariant: expressive)`.
class ExpressivePalette {
  ExpressivePalette._();

  static const Color violetVibrant = Color(0xFF6A4FE0);
  static const Color magentaPlayful = Color(0xFFE0398B);
  static const Color tealOptimist = Color(0xFF0FB5A8);
  static const Color sunsetCoral = Color(0xFFFF6E5A);
  static const Color lemonZest = Color(0xFFE9C400);
  static const Color forestNature = Color(0xFF2E9E5B);
  static const Color skyClarity = Color(0xFF1FA2FF);
  static const Color amberWarm = Color(0xFFFFA033);

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

  /// Retourne une couleur expressive dérivée d'un texte (stable, hash).
  static Color seedFor(String text) =>
      seeds[text.hashCode.abs() % seeds.length];
}

/// Re-export des tokens motion/shapes pour un accès groupé.
class Expressive {
  Expressive._();

  static ExpressiveMotion get motion => throw UnimplementedError();
  static ExpressiveShapes get shapes => throw UnimplementedError();
  static ExpressiveTokens get tokens => throw UnimplementedError();
}
