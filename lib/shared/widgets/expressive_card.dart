import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_motion.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_shapes.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_tokens.dart';
import 'package:toolbox_everything_mobile/core/providers/settings_provider.dart';

/// Carte Material 3 Expressive : surface containerLow, rayons larges,
/// animation spring sur la pression (scale + radius).
class ExpressiveCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final ShapeBorder? shape;
  final EdgeInsetsGeometry padding;
  final bool dense;

  const ExpressiveCard({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.shape,
    this.padding = const EdgeInsets.all(ExpressiveTokens.spacing),
    this.dense = false,
  });

  /// Carte hero — coins asymétriques (signature M3E).
  factory ExpressiveCard.hero({
    Key? key,
    required Widget child,
    VoidCallback? onTap,
    Color? color,
    EdgeInsetsGeometry padding = const EdgeInsets.all(
      ExpressiveTokens.spacingLg,
    ),
  }) {
    return ExpressiveCard(
      key: key,
      onTap: onTap,
      color: color,
      shape: ExpressiveShapes.cardHero(),
      padding: padding,
      child: child,
    );
  }

  @override
  State<ExpressiveCard> createState() => _ExpressiveCardState();
}

class _ExpressiveCardState extends State<ExpressiveCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lowResource = context.select<SettingsProvider, bool>(
      (s) => s.lowResourceMode,
    );
    final shape =
        widget.shape ??
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            widget.dense
                ? ExpressiveShapes.medium
                : ExpressiveShapes.largeIncreased,
          ),
        );

    final material = Material(
      color: widget.color ?? scheme.surfaceContainerLow,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        onHighlightChanged: lowResource
            ? null
            : (v) {
                if (mounted) setState(() => _pressed = v);
              },
        splashColor: lowResource
            ? Colors.transparent
            : scheme.primary.withValues(alpha: 0.10),
        highlightColor: lowResource
            ? Colors.transparent
            : scheme.primary.withValues(alpha: 0.05),
        child: Padding(padding: widget.padding, child: widget.child),
      ),
    );

    if (lowResource) return material;

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: ExpressiveMotion.short3,
      curve: ExpressiveMotion.springStandard,
      child: material,
    );
  }
}
