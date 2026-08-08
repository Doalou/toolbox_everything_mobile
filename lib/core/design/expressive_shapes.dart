import 'package:flutter/material.dart';

/// Alias historiques vers l'échelle de formes éditoriale resserrée.
class ExpressiveShapes {
  ExpressiveShapes._();

  // Rayons standards (extension de la corner-shape scale M3).
  static const double none = 0;
  static const double extraSmall = 5;
  static const double small = 7;
  static const double medium = 10;
  static const double large = 14;
  static const double largeIncreased = 18;
  static const double extraLarge = 22;
  static const double extraLargeIncreased = 24;
  static const double extraExtraLarge = 28;
  static const double full = 999;

  // Forme expressive par défaut (cards, sheets, dialogs).
  static const Radius radiusMedium = Radius.circular(medium);
  static const Radius radiusLarge = Radius.circular(large);
  static const Radius radiusExtraLarge = Radius.circular(extraLarge);
  static const Radius radiusFull = Radius.circular(full);

  static BorderRadius all(double r) => BorderRadius.circular(r);

  static BorderRadius asymmetricHero({double major = 14, double minor = 10}) =>
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
