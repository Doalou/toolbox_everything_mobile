import 'package:material_ui/material_ui.dart';

/// Échelle de formes Material 3 Expressive (M3E).
/// Formes généreuses, coins asymétriques « Hero » et composants pilules.
class ExpressiveShapes {
  ExpressiveShapes._();

  // Rayons M3 Expressive
  static const double extraSmall = 6;
  static const double small = 10;
  static const double medium = 16;
  static const double large = 20;
  static const double largeIncreased = 24;
  static const double extraLarge = 28;
  static const double extraLargeIncreased = 32;

  static const Radius radiusExtraLarge = Radius.circular(extraLarge);

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

  /// Carte hero (asymétrique M3E).
  static RoundedRectangleBorder cardHero({BorderSide side = BorderSide.none}) =>
      RoundedRectangleBorder(borderRadius: asymmetricHero(), side: side);

  /// Morphing bouton M3E (pilule 28dp -> squircle 14dp au toucher).
  static RoundedRectangleBorder morphButton({
    required bool pressed,
    BorderSide side = BorderSide.none,
  }) => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(pressed ? 14 : 28),
    side: side,
  );

  /// Morphing carte M3E au toucher.
  static RoundedRectangleBorder morphCard({
    required bool pressed,
    bool dense = false,
    BorderSide side = BorderSide.none,
  }) => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(
      pressed ? medium : (dense ? large : largeIncreased),
    ),
    side: side,
  );

  /// Dialog M3E (extra-large rounded).
  static const RoundedRectangleBorder dialog = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(radiusExtraLarge),
  );

  /// Bouton hero / pill.
  static const StadiumBorder pill = StadiumBorder();
}
