import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_motion.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_shapes.dart';
import 'package:toolbox_everything_mobile/core/models/tool_item.dart';
import 'package:toolbox_everything_mobile/core/providers/settings_provider.dart';
import 'package:toolbox_everything_mobile/core/services/haptics_service.dart';
import 'package:toolbox_everything_mobile/core/services/usage_stats_service.dart';
import 'package:toolbox_everything_mobile/presentation/navigation/unified_navigation.dart';

/// Carte d'outil Material 3 Expressive : surface tonale harmonieuse fidèle à la
/// couleur de l'outil, icône squircle saturée, hiérarchie claire sur une seule
/// ligne et micro-interaction spring au toucher.
class ExpressiveToolCard extends StatefulWidget {
  final ToolItem tool;
  final int index;
  final bool isFavorite;
  final ValueChanged<bool>? onFavoriteChanged;

  const ExpressiveToolCard({
    super.key,
    required this.tool,
    required this.index,
    required this.isFavorite,
    this.onFavoriteChanged,
  });

  @override
  State<ExpressiveToolCard> createState() => _ExpressiveToolCardState();
}

class _ExpressiveToolCardState extends State<ExpressiveToolCard> {
  bool _pressed = false;

  void _open() {
    HapticsService.perform(context, HapticType.selection);
    UsageStatsService.recordToolUsage(widget.tool.id);
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
    final isDark = scheme.brightness == Brightness.dark;
    final lowResource = context.select<SettingsProvider, bool>(
      (settings) => settings.lowResourceMode,
    );

    final hsl = HSLColor.fromColor(widget.tool.cardColor);
    final accent = isDark
        ? hsl.withLightness(hsl.lightness.clamp(0.62, 0.78)).toColor()
        : hsl.withLightness(hsl.lightness.clamp(0.32, 0.48)).toColor();

    final surfaceColor = Color.alphaBlend(
      accent.withValues(alpha: isDark ? 0.08 : 0.06),
      scheme.surfaceContainerLow,
    );
    final iconBgColor = accent.withValues(alpha: isDark ? 0.18 : 0.13);
    final borderColor = accent.withValues(alpha: isDark ? 0.22 : 0.18);

    final card = Material(
      color: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: ExpressiveShapes.asymmetricHero(major: 24, minor: 14),
        side: BorderSide(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _open,
        onHighlightChanged: lowResource
            ? null
            : (value) {
                if (mounted) setState(() => _pressed = value);
              },
        splashColor: lowResource
            ? Colors.transparent
            : accent.withValues(alpha: 0.14),
        highlightColor: lowResource
            ? Colors.transparent
            : accent.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(ExpressiveShapes.medium),
                ),
                child: Icon(widget.tool.icon, color: accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Hero(
                      tag: widget.tool.heroTag,
                      child: Material(
                        type: MaterialType.transparency,
                        child: Text(
                          widget.tool.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    if (widget.tool.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.tool.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              _FavoriteButton(
                selected: widget.isFavorite,
                accent: accent,
                onPressed: () {
                  HapticsService.perform(context, HapticType.light);
                  widget.onFavoriteChanged?.call(!widget.isFavorite);
                },
              ),
              const SizedBox(width: 4),
              Container(
                width: 28,
                height: 28,
                decoration: ShapeDecoration(
                  color: accent.withValues(alpha: isDark ? 0.16 : 0.11),
                  shape: const StadiumBorder(),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (lowResource) return card;
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: ExpressiveMotion.short4,
      curve: ExpressiveMotion.springStandard,
      child: card,
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  final bool selected;
  final Color accent;
  final VoidCallback onPressed;

  const _FavoriteButton({
    required this.selected,
    required this.accent,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
      iconSize: 19,
      tooltip: selected ? 'Retirer des favoris' : 'Ajouter aux favoris',
      icon: Icon(
        selected ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color: selected
            ? scheme.error
            : scheme.onSurfaceVariant.withValues(alpha: 0.65),
      ),
    );
  }
}
