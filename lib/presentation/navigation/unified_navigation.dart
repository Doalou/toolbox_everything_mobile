import 'package:flutter/material.dart';

Route<dynamic> unifiedNavigation(
  BuildContext context,
  Widget page, {
  bool isAndroid = false,
}) {
  if (isAndroid) {
    // Utiliser MaterialPageRoute pour une intégration parfaite du Predictive Back Gesture
    return MaterialPageRoute(builder: (context) => page);
  } else {
    // Transition personnalisée pour les autres plateformes
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.06, 0.0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}
