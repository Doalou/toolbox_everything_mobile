import 'package:flutter/material.dart';

class SmoothPage extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const SmoothPage({super.key, required this.child, this.enabled = true});

  @override
  State<SmoothPage> createState() => _SmoothPageState();
}

class _SmoothPageState extends State<SmoothPage>
    with SingleTickerProviderStateMixin {
  AnimationController? _fallbackController;

  @override
  void initState() {
    super.initState();
    // Crée un contrôleur de secours uniquement si aucune animation de route n'est disponible
    final route = ModalRoute.of(context);
    if (route?.animation == null) {
      _fallbackController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 240),
      );
      if (widget.enabled) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _fallbackController?.forward();
        });
      } else {
        _fallbackController?.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _fallbackController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Utilise l'animation de la route si disponible (suit aussi le geste de retour prédictif)
    final route = ModalRoute.of(context);
    final Animation<double> base =
        (route?.animation ?? _fallbackController) ?? kAlwaysCompleteAnimation;
    final curved = CurvedAnimation(
      parent: base,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeOutCubic,
    );
    final slide = Tween<Offset>(
      begin: const Offset(0.015, 0.0),
      end: Offset.zero,
    ).animate(curved);

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(position: slide, child: widget.child),
    );
  }
}
