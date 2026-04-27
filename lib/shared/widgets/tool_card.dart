import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_motion.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_shapes.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_tokens.dart';
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
        isAndroid: Theme.of(context).platform == TargetPlatform.android,
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

    final card = Hero(
      tag: widget.tool.heroTag,
      transitionOnUserGestures: true,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: ExpressiveMotion.short3,
        curve: ExpressiveMotion.springStandard,
        child: Material(
          color: scheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ExpressiveShapes.largeIncreased,
            ),
            side: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _open(context),
            onHighlightChanged: (v) {
              if (lowResource) return;
              if (mounted) setState(() => _pressed = v);
            },
            splashColor: accent.withValues(alpha: 0.10),
            highlightColor: accent.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(ExpressiveTokens.spacing),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: ShapeDecoration(
                          color: accent.withValues(alpha: 0.18),
                          shape: const StadiumBorder(),
                        ),
                        child: Icon(widget.tool.icon, color: accent, size: 26),
                      ),
                      const SizedBox(height: ExpressiveTokens.spacing),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.tool.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  height: 1.25,
                                ),
                          ),
                          if (widget.tool.subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.tool.subtitle!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    top: -4,
                    right: -4,
                    child: IconButton(
                      onPressed: () {
                        widget.tool.toggleFavorite();
                        widget.onFavoriteToggle?.call();
                        if (mounted) setState(() {});
                      },
                      iconSize: 18,
                      visualDensity: VisualDensity.compact,
                      tooltip: widget.tool.isFavorite
                          ? 'Retirer des favoris'
                          : 'Ajouter aux favoris',
                      icon: Icon(
                        widget.tool.isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: widget.tool.isFavorite
                            ? scheme.error
                            : scheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
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
