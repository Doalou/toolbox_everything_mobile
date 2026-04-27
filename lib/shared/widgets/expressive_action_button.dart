import 'package:flutter/material.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_motion.dart';

/// Bouton hero pill avec spring sur la pression — variante visuelle marquée
/// pour les actions principales (Télécharger, Convertir, Lancer test, etc.).
class ExpressiveActionButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final IconData? icon;
  final String? label;
  final bool loading;
  final bool tonal;

  const ExpressiveActionButton({
    super.key,
    this.onPressed,
    required this.child,
    this.icon,
    this.label,
    this.loading = false,
    this.tonal = false,
  });

  /// Construit un bouton avec icône + label (pas besoin de child).
  factory ExpressiveActionButton.iconLabel({
    Key? key,
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool loading = false,
    bool tonal = false,
  }) {
    return ExpressiveActionButton(
      key: key,
      icon: icon,
      label: label,
      onPressed: onPressed,
      loading: loading,
      tonal: tonal,
      child: const SizedBox.shrink(),
    );
  }

  @override
  State<ExpressiveActionButton> createState() => _ExpressiveActionButtonState();
}

class _ExpressiveActionButtonState extends State<ExpressiveActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = widget.tonal ? scheme.secondaryContainer : scheme.primary;
    final fg = widget.tonal ? scheme.onSecondaryContainer : scheme.onPrimary;
    final disabled = widget.onPressed == null || widget.loading;

    Widget content;
    if (widget.icon != null && widget.label != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.loading)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: fg),
            )
          else
            Icon(widget.icon, color: fg, size: 20),
          const SizedBox(width: 10),
          Text(
            widget.label!,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: 15,
              letterSpacing: 0.1,
            ),
          ),
        ],
      );
    } else {
      content = widget.child;
    }

    return AnimatedScale(
      scale: _pressed ? 0.96 : 1.0,
      duration: ExpressiveMotion.short3,
      curve: ExpressiveMotion.springSnappy,
      child: Material(
        color: disabled ? bg.withValues(alpha: 0.5) : bg,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: disabled ? null : widget.onPressed,
          onHighlightChanged: (v) {
            if (mounted) setState(() => _pressed = v);
          },
          splashColor: fg.withValues(alpha: 0.18),
          highlightColor: fg.withValues(alpha: 0.10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: content,
          ),
        ),
      ),
    );
  }
}
