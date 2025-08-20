import 'package:flutter/material.dart';
import 'package:toolbox_everything_mobile/presentation/widgets/smooth_page.dart';

Future<T?> pushUnified<T>(
  BuildContext context,
  Widget page, {
  bool lowResourceMode = false,
}) {
  final platform = Theme.of(context).platform;
  if (platform == TargetPlatform.android) {
    // Android: MaterialPageRoute pour Predictive Back, avec animation d'entrée subtile du contenu
    return Navigator.push<T>(
      context,
      MaterialPageRoute(builder: (_) => SmoothPage(child: page)),
    );
  }
  // Autres plateformes: légère transition pour fluidité
  return Navigator.push<T>(
    context,
    PageRouteBuilder(
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
    ),
  );
}
