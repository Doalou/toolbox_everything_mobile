import 'package:flutter/material.dart';

/// Tokens de forme Material 3 Expressive.
/// L'expressif privilégie les rayons larges et asymétriques pour les
/// éléments interactifs majeurs (cartes héro, FAB, hero buttons).
class ExpressiveShapes {
  ExpressiveShapes._();

  // Rayons standards (extension de la corner-shape scale M3).
  static const double none = 0;
  static const double extraSmall = 4;
  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
  static const double largeIncreased = 20;
  static const double extraLarge = 28;
  static const double extraLargeIncreased = 32;
  static const double extraExtraLarge = 36;
  static const double full = 999;

  // Forme expressive par défaut (cards, sheets, dialogs).
  static const Radius radiusMedium = Radius.circular(medium);
  static const Radius radiusLarge = Radius.circular(large);
  static const Radius radiusExtraLarge = Radius.circular(extraLarge);
  static const Radius radiusFull = Radius.circular(full);

  static BorderRadius all(double r) => BorderRadius.circular(r);

  /// Forme asymétrique typiquement M3E : 28/12/12/28 (signature des hero cards).
  static BorderRadius asymmetricHero({double major = 28, double minor = 12}) =>
      BorderRadius.only(
        topLeft: Radius.circular(major),
        topRight: Radius.circular(minor),
        bottomLeft: Radius.circular(minor),
        bottomRight: Radius.circular(major),
      );

  /// Bottom sheet expressif (top arrondi large).
  static const RoundedRectangleBorder bottomSheet = RoundedRectangleBorder(
    borderRadius: BorderRadius.only(
      topLeft: radiusExtraLarge,
      topRight: radiusExtraLarge,
    ),
  );

  /// Carte standard expressive.
  static RoundedRectangleBorder card({double radius = largeIncreased}) =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));

  /// Carte hero (asymétrique).
  static RoundedRectangleBorder cardHero() =>
      RoundedRectangleBorder(borderRadius: asymmetricHero());

  /// Dialog M3E (extra-large rounded).
  static const RoundedRectangleBorder dialog = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(radiusExtraLarge),
  );

  /// Bouton hero / pill.
  static const StadiumBorder pill = StadiumBorder();
}
