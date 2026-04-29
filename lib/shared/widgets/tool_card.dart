import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_motion.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_shapes.dart';
import 'package:toolbox_everything_mobile/core/models/tool_item.dart';
import 'package:toolbox_everything_mobile/core/providers/settings_provider.dart';
import 'package:toolbox_everything_mobile/core/services/haptics_service.dart';
import 'package:toolbox_everything_mobile/core/services/usage_stats_service.dart';
import 'package:toolbox_everything_mobile/presentation/navigation/unified_navigation.dart';

/// Carte d'outil M3 Expressive : icône colorée dans une bulle pill,
/// titre fort, sous-titre, badge favori discret.
class ExpressiveToolCard extends StatefulWidget {
  final ToolItem tool;
  final VoidCallback? onFavoriteToggle;

  const ExpressiveToolCard({
    super.key,
    required this.tool,
    this.onFavoriteToggle,
  });

  @override
  State<ExpressiveToolCard> createState() => _ExpressiveToolCardState();
}

class _ExpressiveToolCardState extends State<ExpressiveToolCard> {
  bool _pressed = false;

  void _open(BuildContext context) {
    HapticsService.perform(context, HapticType.selection);
    UsageStatsService.recordToolUsage(widget.tool.title);
    Navigator.of(context).push(
      unifiedNavigation(
        context,
        widget.tool.screenBuilder(widget.tool.heroTag),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lowResource = context.select<SettingsProvider, bool>(
      (s) => s.lowResourceMode,
    );
    final accent = widget.tool.cardColor;
    final cardShape = RoundedRectangleBorder(
      borderRadius: ExpressiveShapes.asymmetricHero(major: 22, minor: 14),
      side: BorderSide(
        color: scheme.outlineVariant.withValues(alpha: 0.48),
        width: 1,
      ),
    );

    final card = AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: ExpressiveMotion.short3,
      curve: ExpressiveMotion.springStandard,
      child: Material(
        color: scheme.surfaceContainerLow,
        shape: cardShape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _open(context),
          onHighlightChanged: (v) {
            if (lowResource) return;
            if (mounted) setState(() => _pressed = v);
          },
          splashColor: scheme.primary.withValues(alpha: 0.08),
          highlightColor: scheme.primary.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: ShapeDecoration(
                        color: accent.withValues(alpha: 0.11),
                        shape: const StadiumBorder(),
                      ),
                      child: Icon(widget.tool.icon, color: accent, size: 20),
                    ),
                    const Spacer(),
                    _FavoriteButton(
                      selected: widget.tool.isFavorite,
                      onPressed: () {
                        widget.tool.toggleFavorite();
                        widget.onFavoriteToggle?.call();
                        if (mounted) setState(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Hero(
                  tag: widget.tool.heroTag,
                  transitionOnUserGestures: true,
                  child: Material(
                    type: MaterialType.transparency,
                    child: Text(
                      widget.tool.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Semantics(
      label: 'Outil ${widget.tool.title}',
      button: true,
      child: card,
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  final bool selected;
  final VoidCallback onPressed;

  const _FavoriteButton({required this.selected, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox.square(
      dimension: 28,
      child: Material(
        color: scheme.surface.withValues(alpha: 0.72),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: IconButton(
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          iconSize: 15,
          visualDensity: VisualDensity.compact,
          tooltip: selected ? 'Retirer des favoris' : 'Ajouter aux favoris',
          icon: Icon(
            selected ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: selected
                ? scheme.error
                : scheme.onSurfaceVariant.withValues(alpha: 0.72),
          ),
        ),
      ),
    );
  }
}
