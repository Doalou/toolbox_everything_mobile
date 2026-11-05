import 'package:flutter/material.dart';

/// Échelle de formes Material 3 Expressive (M3E).
/// Formes généreuses, coins asymétriques « Hero » et composants pilules.
class ExpressiveShapes {
  ExpressiveShapes._();

  // Rayons M3 Expressive (corner-shape scale étendue)
  static const double none = 0;
  static const double extraSmall = 6;
  static const double small = 10;
  static const double medium = 16;
  static const double large = 20;
  static const double largeIncreased = 24;
  static const double extraLarge = 28;
  static const double extraLargeIncreased = 32;
  static const double extraExtraLarge = 36;
  static const double full = 999;

  // Formes expressives par défaut (cards, sheets, dialogs)
  static const Radius radiusMedium = Radius.circular(medium);
  static const Radius radiusLarge = Radius.circular(large);
  static const Radius radiusExtraLarge = Radius.circular(extraLarge);
  static const Radius radiusFull = Radius.circular(full);

  static BorderRadius all(double r) => BorderRadius.circular(r);

  static BorderRadius asymmetricHero({double major = 28, double minor = 12}) =>
      BorderRadius.only(
        topLeft: Radius.circular(major),
        topRight: Radius.circular(minor),
        bottomLeft: Radius.circular(minor),
        bottomRight: Radius.circular(major),
      );

  /// Bottom sheet expressif (top arrondi extra-large).
  static const RoundedRectangleBorder bottomSheet = RoundedRectangleBorder(
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(extraLargeIncreased),
      topRight: Radius.circular(extraLargeIncreased),
    ),
  );

  /// Carte standard expressive.
  static RoundedRectangleBorder card({double radius = largeIncreased}) =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));

  /// Carte hero (asymétrique M3E).
  static RoundedRectangleBorder cardHero() =>
      RoundedRectangleBorder(borderRadius: asymmetricHero());

  /// Dialog M3E (extra-large rounded).
  static const RoundedRectangleBorder dialog = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(radiusExtraLarge),
  );

  /// Bouton hero / pill.
  static const StadiumBorder pill = StadiumBorder();
}
