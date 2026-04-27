import 'package:flutter/animation.dart';

/// Motion tokens Material 3 Expressive.
/// Springs : pour les transitions spatiales (mouvements, déplacements).
/// Effects : pour les transitions de propriétés (couleur, opacité, rayon).
class ExpressiveMotion {
  ExpressiveMotion._();

  // Durées (tokens M3E)
  static const Duration short1 = Duration(milliseconds: 50);
  static const Duration short2 = Duration(milliseconds: 100);
  static const Duration short3 = Duration(milliseconds: 150);
  static const Duration short4 = Duration(milliseconds: 200);

  static const Duration medium1 = Duration(milliseconds: 250);
  static const Duration medium2 = Duration(milliseconds: 300);
  static const Duration medium3 = Duration(milliseconds: 350);
  static const Duration medium4 = Duration(milliseconds: 400);

  static const Duration long1 = Duration(milliseconds: 450);
  static const Duration long2 = Duration(milliseconds: 500);
  static const Duration long3 = Duration(milliseconds: 550);
  static const Duration long4 = Duration(milliseconds: 600);

  static const Duration extraLong1 = Duration(milliseconds: 700);
  static const Duration extraLong2 = Duration(milliseconds: 800);

  /// Courbes M3 Expressive — proches des springs natifs.
  /// Spatial = mouvement (pour positions, tailles).
  static const Curve spatialFast = Cubic(0.42, 1.67, 0.21, 0.90);
  static const Curve spatialDefault = Cubic(0.34, 1.56, 0.32, 1.0);
  static const Curve spatialSlow = Cubic(0.16, 1.0, 0.22, 1.0);

  /// Effects = propriétés (opacité, couleur, rayon).
  static const Curve effectsFast = Cubic(0.31, 0.94, 0.34, 1.0);
  static const Curve effectsDefault = Cubic(0.20, 0.0, 0.0, 1.0);
  static const Curve effectsSlow = Cubic(0.30, 0.0, 0.0, 1.0);

  /// Emphasized — courbes phares M3.
  static const Curve emphasized = Cubic(0.20, 0.0, 0.0, 1.0);
  static const Curve emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1.0);
  static const Curve emphasizedAccelerate = Cubic(0.3, 0.0, 0.8, 0.15);

  /// Spring naturel pour micro-interactions (presses, hovers).
  static const Curve springStandard = Cubic(0.36, 1.39, 0.42, 1.0);
  static const Curve springGentle = Cubic(0.34, 1.16, 0.42, 1.0);
  static const Curve springSnappy = Cubic(0.45, 1.85, 0.36, 1.0);
}
