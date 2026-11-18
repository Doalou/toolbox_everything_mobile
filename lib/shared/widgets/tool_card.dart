import 'package:material_ui/material_ui.dart';
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
  final bool isFavorite;
  final ValueChanged<bool>? onFavoriteChanged;
  final VoidCallback? onOpen;

  const ExpressiveToolCard({
    super.key,
    required this.tool,
    required this.isFavorite,
    this.onFavoriteChanged,
    this.onOpen,
  });

  @override
  State<ExpressiveToolCard> createState() => _ExpressiveToolCardState();
}

class _ExpressiveToolCardState extends State<ExpressiveToolCard> {
  bool _pressed = false;

  void _open() {
    if (widget.onOpen != null) {
      widget.onOpen!();
      return;
    }
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

    final restRadius = ExpressiveShapes.asymmetricHero(major: 24, minor: 14);
    final pressedRadius = BorderRadius.circular(18);
    final inkContent = InkWell(
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
              lowResource: lowResource,
              onPressed: () {
                HapticsService.perform(context, HapticType.light);
                widget.onFavoriteChanged?.call(!widget.isFavorite);
              },
            ),
            const SizedBox(width: 4),
            AnimatedContainer(
              duration: lowResource ? Duration.zero : ExpressiveMotion.short3,
              curve: ExpressiveMotion.spatialMorph,
              width: 28,
              height: 28,
              decoration: ShapeDecoration(
                color: accent.withValues(
                  alpha: _pressed ? 0.28 : (isDark ? 0.16 : 0.11),
                ),
                shape: const StadiumBorder(),
              ),
              child: Icon(Icons.chevron_right_rounded, size: 18, color: accent),
            ),
          ],
        ),
      ),
    );

    if (lowResource) {
      return Material(
        color: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: restRadius,
          side: BorderSide(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: inkContent,
      );
    }

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: ExpressiveMotion.short4,
      curve: ExpressiveMotion.springStandard,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: _pressed ? 1.0 : 0.0),
        duration: ExpressiveMotion.short3,
        curve: ExpressiveMotion.spatialMorph,
        builder: (context, t, child) => Material(
          color: surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.lerp(restRadius, pressedRadius, t)!,
            side: BorderSide(color: borderColor),
          ),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
        child: inkContent,
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  final bool selected;
  final bool lowResource;
  final VoidCallback onPressed;

  const _FavoriteButton({
    required this.selected,
    required this.lowResource,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final icon = Icon(
      selected ? Icons.favorite_rounded : Icons.favorite_border_rounded,
      key: ValueKey(selected),
      color: selected
          ? scheme.error
          : scheme.onSurfaceVariant.withValues(alpha: 0.65),
    );

    return IconButton(
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
      iconSize: 19,
      tooltip: selected ? 'Retirer des favoris' : 'Ajouter aux favoris',
      icon: lowResource
          ? icon
          : AnimatedSwitcher(
              duration: ExpressiveMotion.short4,
              switchInCurve: ExpressiveMotion.springStandard,
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: icon,
            ),
    );
  }
}
