import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_motion.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_shapes.dart';
import 'package:toolbox_everything_mobile/core/providers/settings_provider.dart';
import 'package:toolbox_everything_mobile/core/services/haptics_service.dart';

/// Bouton d'action Material 3 Expressive (forme pilule, spring rebondissant et
/// retour haptique intégré).
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

  void _handleTap() {
    if (widget.onPressed == null || widget.loading) return;
    HapticsService.perform(context, HapticType.selection);
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lowResource = context.select<SettingsProvider, bool>(
      (s) => s.lowResourceMode,
    );
    final bg = widget.tonal ? scheme.secondaryContainer : scheme.primary;
    final fg = widget.tonal ? scheme.onSecondaryContainer : scheme.onPrimary;
    final disabled = widget.onPressed == null || widget.loading;

    Widget content;
    if (widget.icon != null && widget.label != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.loading)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: fg),
            )
          else
            Icon(widget.icon, color: fg, size: 19),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.label!,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      );
    } else {
      content = widget.child;
    }

    final material = Material(
      color: disabled ? bg.withValues(alpha: 0.45) : bg,
      shape: ExpressiveShapes.pill,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: disabled ? null : _handleTap,
        onHighlightChanged: lowResource
            ? null
            : (v) {
                if (mounted) setState(() => _pressed = v);
              },
        splashColor: lowResource
            ? Colors.transparent
            : fg.withValues(alpha: 0.18),
        highlightColor: lowResource
            ? Colors.transparent
            : fg.withValues(alpha: 0.10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          child: content,
        ),
      ),
    );

    if (lowResource) return material;

    return AnimatedScale(
      scale: _pressed ? 0.96 : 1.0,
      duration: ExpressiveMotion.short4,
      curve: ExpressiveMotion.springStandard,
      child: material,
    );
  }
}
