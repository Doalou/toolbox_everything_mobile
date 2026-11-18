import 'package:flutter/animation.dart';

/// Motion tokens Material 3 Expressive.
class ExpressiveMotion {
  ExpressiveMotion._();

  // Durées (tokens M3E)
  static const Duration short3 = Duration(milliseconds: 120);
  static const Duration short4 = Duration(milliseconds: 180);
  static const Duration medium2 = Duration(milliseconds: 260);

  /// Spring naturel pour micro-interactions scale (presses, hovers).
  static const Curve springStandard = Cubic(0.36, 1.39, 0.42, 1.0);

  /// Courbe spatiale décélérée bornée [0..1] sûre pour AnimatedContainer,
  /// ShapeBorder.lerp, Color.lerp et AnimatedSize.
  static const Curve spatialMorph = Cubic(0.22, 1.0, 0.36, 1.0);
}
