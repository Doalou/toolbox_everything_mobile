import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toolbox_everything_mobile/core/design/editorial_tokens.dart';
import 'package:toolbox_everything_mobile/core/models/tool_item.dart';
import 'package:toolbox_everything_mobile/core/providers/settings_provider.dart';
import 'package:toolbox_everything_mobile/core/services/haptics_service.dart';
import 'package:toolbox_everything_mobile/core/services/usage_stats_service.dart';
import 'package:toolbox_everything_mobile/presentation/navigation/unified_navigation.dart';

/// Carte éditoriale d'accès direct. Le nom historique est conservé afin de ne
/// pas casser les écrans qui l'utilisent déjà.
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
    final lowResource = context.select<SettingsProvider, bool>(
      (settings) => settings.lowResourceMode,
    );
    final accent = widget.tool.cardColor;
    final card = Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(EditorialTokens.radiusMd),
        side: BorderSide(color: scheme.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _open,
        onHighlightChanged: lowResource
            ? null
            : (value) => setState(() => _pressed = value),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    widget.index.toString().padLeft(2, '0'),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.tool.category.label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                  _FavoriteButton(
                    selected: widget.isFavorite,
                    onPressed: () =>
                        widget.onFavoriteChanged?.call(!widget.isFavorite),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(
                        EditorialTokens.radiusSm,
                      ),
                      border: Border.all(color: accent.withValues(alpha: 0.28)),
                    ),
                    child: Icon(widget.tool.icon, color: accent, size: 21),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
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
                              style: Theme.of(context).textTheme.titleLarge,
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
                  Icon(Icons.arrow_forward_rounded, size: 16, color: accent),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (lowResource) return card;
    return AnimatedScale(
      scale: _pressed ? 0.99 : 1,
      duration: EditorialTokens.durationFast,
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
    return IconButton(
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      iconSize: 18,
      tooltip: selected ? 'Retirer des favoris' : 'Ajouter aux favoris',
      icon: Icon(
        selected ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color: selected
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
