import 'package:flutter/material.dart';
import 'package:toolbox_everything_mobile/core/constants/app_constants.dart';

class UnifiedNavigationRoute<T> extends PageRouteBuilder<T> {
  UnifiedNavigationRoute({
    required WidgetBuilder builder,
    Duration duration = AppConstants.mediumAnimation,
    Curve curve = AppConstants.defaultAnimationCurve,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => builder(context),
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: curve, reverseCurve: curve);
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0.06, 0.0), end: Offset.zero).animate(curved),
                child: child,
              ),
            );
          },
        );
}

Future<T?> pushUnified<T>(BuildContext context, Widget page, {required bool lowResourceMode}) {
  if (lowResourceMode) {
    return Navigator.push<T>(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }
  return Navigator.push<T>(
    context,
    UnifiedNavigationRoute(builder: (_) => page),
  );
}


