import 'package:flutter/material.dart';
import 'package:toolbox_everything_mobile/core/models/tool_item.dart';
import 'package:toolbox_everything_mobile/core/constants/app_constants.dart';
import 'package:provider/provider.dart';
import 'package:toolbox_everything_mobile/core/providers/settings_provider.dart';
import 'package:toolbox_everything_mobile/core/services/usage_stats_service.dart';
import 'package:toolbox_everything_mobile/presentation/navigation/unified_navigation.dart';
import 'package:toolbox_everything_mobile/core/services/haptics_service.dart';

class ToolCard extends StatefulWidget {
  final ToolItem tool;
  final VoidCallback? onFavoriteToggle;

  const ToolCard({super.key, required this.tool, this.onFavoriteToggle});

  @override
  State<ToolCard> createState() => _ToolCardState();
}

class _ToolCardState extends State<ToolCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool lowResourceMode = context.select<SettingsProvider, bool>(
      (s) => s.lowResourceMode,
    );

    // Version optimisée pour les appareils bas de gamme
    if (lowResourceMode) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.largeBorderRadius),
          side: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        color: colorScheme.surfaceContainer,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _navigateToTool(context),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: LayoutBuilder(
              builder: (context, c) {
                final double w = c.maxWidth;
                final double iconSize = (w * 0.28).clamp(24.0, 40.0);
                final double spacing = w < 180
                    ? AppConstants.smallPadding
                    : AppConstants.defaultPadding;
                final double titleSize = (w * 0.09).clamp(12.0, 16.0);

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.tool.icon,
                      size: iconSize,
                      color: colorScheme.primary,
                    ),
                    SizedBox(height: spacing),
                    Text(
                      widget.tool.title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                        height: 1.3,
                        fontSize: titleSize,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
    }

    // Version complète avec animations pour les appareils performants
    final cardColor = widget.tool.cardColor;

    final bool isAndroid = Theme.of(context).platform == TargetPlatform.android;
    return Semantics(
      label: 'Outil ${widget.tool.title}',
      hint: 'Appuyez pour ouvrir ${widget.tool.title}',
      button: true,
      child: Hero(
        tag: widget.tool.heroTag,
        transitionOnUserGestures: !isAndroid,
        flightShuttleBuilder: isAndroid
            ? null
            : (
                flightContext,
                animation,
                flightDirection,
                fromHeroContext,
                toHeroContext,
              ) {
                final isPush = flightDirection == HeroFlightDirection.push;
                final fromWidget = (fromHeroContext.widget as Hero).child;
                final toWidget = (toHeroContext.widget as Hero).child;

                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    final val = isPush
                        ? Curves.easeInOut.transform(animation.value)
                        : Curves.easeInOut.transform(1 - animation.value);

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Opacity(opacity: 1 - val, child: fromWidget),
                        Opacity(opacity: val, child: toWidget),
                      ],
                    );
                  },
                );
              },
        child: MouseRegion(
          onEnter: (_) {
            if (!lowResourceMode && widget.tool.animates) {
              setState(() => _isHovered = true);
            }
          },
          onExit: (_) {
            if (!lowResourceMode && widget.tool.animates) {
              setState(() => _isHovered = false);
            }
          },
          child: AnimatedContainer(
            duration: lowResourceMode
                ? Duration.zero
                : AppConstants.mediumAnimation,
            curve: AppConstants.defaultAnimationCurve,
            transform: lowResourceMode
                ? Matrix4.identity()
                : (Matrix4.identity()
                    ..translate(0.0, _isHovered ? -4.0 : 0.0)
                    ..scale(_isHovered ? 1.02 : 1.0)),
            decoration: BoxDecoration(
              gradient: (_isHovered && !lowResourceMode)
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        cardColor.withValues(alpha: 0.1),
                        cardColor.withValues(alpha: 0.05),
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.surfaceContainer,
                        colorScheme.surfaceContainerLow,
                      ],
                    ),
              borderRadius: BorderRadius.circular(
                AppConstants.largeBorderRadius,
              ),
              border: Border.all(
                color: (_isHovered && !lowResourceMode)
                    ? cardColor.withValues(alpha: 0.4)
                    : colorScheme.outline.withValues(alpha: 0.1),
                width: (_isHovered && !lowResourceMode) ? 2 : 1,
              ),
              boxShadow: [
                if (_isHovered && !lowResourceMode) ...[
                  BoxShadow(
                    color: cardColor.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: cardColor.withValues(alpha: 0.1),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                ] else if (!lowResourceMode)
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(
                  AppConstants.largeBorderRadius,
                ),
                splashColor: colorScheme.primary.withValues(alpha: 0.1),
                highlightColor: colorScheme.primary.withValues(alpha: 0.05),
                onTap: () => _navigateToTool(context),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppConstants.largePadding),
                      child: LayoutBuilder(
                        builder: (context, c) {
                          final double w = c.maxWidth;
                          final double scale = (w / 220.0).clamp(0.85, 1.15);
                          final double iconPadding =
                              (AppConstants.defaultPadding * scale).clamp(
                                10.0,
                                16.0,
                              );
                          final double iconSize =
                              (AppConstants.largeIconSize * scale).clamp(
                                28.0,
                                44.0,
                              );
                          final double titleSize = (14.0 * scale).clamp(
                            12.0,
                            16.0,
                          );
                          final double spacingLarge =
                              (AppConstants.defaultPadding * scale).clamp(
                                8.0,
                                16.0,
                              );
                          final double indicatorWidth =
                              (_isHovered && !lowResourceMode)
                              ? (44.0 * scale).clamp(28.0, 56.0)
                              : (24.0 * scale).clamp(18.0, 34.0);

                          final column = Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Icon Container avec plus de caractère
                              AnimatedContainer(
                                duration: lowResourceMode
                                    ? Duration.zero
                                    : AppConstants.mediumAnimation,
                                curve: AppConstants.defaultAnimationCurve,
                                padding: EdgeInsets.all(iconPadding),
                                decoration: BoxDecoration(
                                  gradient: (_isHovered && !lowResourceMode)
                                      ? RadialGradient(
                                          center: Alignment.center,
                                          colors: [
                                            cardColor.withOpacity(0.8),
                                            cardColor.withOpacity(0.6),
                                          ],
                                        )
                                      : RadialGradient(
                                          center: Alignment.center,
                                          colors: [
                                            colorScheme.primaryContainer,
                                            colorScheme.primaryContainer
                                                .withOpacity(0.8),
                                          ],
                                        ),
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.defaultBorderRadius,
                                  ),
                                  boxShadow: (_isHovered && !lowResourceMode)
                                      ? [
                                          BoxShadow(
                                            color: cardColor.withOpacity(0.3),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: AnimatedRotation(
                                  turns: (_isHovered && !lowResourceMode)
                                      ? 0.05
                                      : 0.0,
                                  duration: lowResourceMode
                                      ? Duration.zero
                                      : AppConstants.mediumAnimation,
                                  curve: AppConstants.defaultAnimationCurve,
                                  child: Icon(
                                    widget.tool.icon,
                                    size: iconSize,
                                    color: _isHovered
                                        ? Colors.white
                                        : colorScheme.onPrimaryContainer,
                                    semanticLabel: 'Icône ${widget.tool.title}',
                                  ),
                                ),
                              ),

                              SizedBox(height: spacingLarge),

                              // Title
                              Align(
                                alignment: Alignment.center,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppConstants.smallPadding,
                                  ),
                                  child: Text(
                                    widget.tool.title,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.onSurface,
                                          height: 1.3,
                                          fontSize: titleSize,
                                        ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),

                              SizedBox(height: AppConstants.smallPadding),

                              // Interaction indicator plus attrayant
                              AnimatedContainer(
                                duration: lowResourceMode
                                    ? Duration.zero
                                    : AppConstants.mediumAnimation,
                                curve: AppConstants.defaultAnimationCurve,
                                height: 4,
                                width: indicatorWidth,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: (_isHovered && !lowResourceMode)
                                        ? [
                                            cardColor,
                                            cardColor.withValues(alpha: 0.6),
                                          ]
                                        : [
                                            colorScheme.primary.withValues(
                                              alpha: 0.4,
                                            ),
                                            colorScheme.primary.withValues(
                                              alpha: 0.2,
                                            ),
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: (_isHovered && !lowResourceMode)
                                      ? [
                                          BoxShadow(
                                            color: cardColor.withValues(
                                              alpha: 0.4,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                            ],
                          );

                          return FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.center,
                            child: column,
                          );
                        },
                      ),
                    ),

                    // Bouton favori
                    Positioned(
                      top: 8,
                      right: 8,
                      child: AnimatedOpacity(
                        opacity: _isHovered || widget.tool.isFavorite
                            ? 1.0
                            : 0.0,
                        duration: AppConstants.mediumAnimation,
                        curve: AppConstants.defaultAnimationCurve,
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surface.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.shadow.withValues(
                                  alpha: 0.2,
                                ),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: () {
                              widget.tool.toggleFavorite();
                              widget.onFavoriteToggle?.call();
                              setState(() {});
                            },
                            icon: Icon(
                              widget.tool.isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: widget.tool.isFavorite
                                  ? Colors.red
                                  : colorScheme.onSurface.withValues(
                                      alpha: 0.6,
                                    ),
                              size: 20,
                            ),
                            tooltip: widget.tool.isFavorite
                                ? 'Retirer des favoris'
                                : 'Ajouter aux favoris',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToTool(BuildContext context) {
    HapticsService.perform(context, HapticType.selection);
    // Enregistrer l'usage (non bloquant)
    UsageStatsService.recordToolUsage(widget.tool.title);

    Navigator.of(context).push(
      unifiedNavigation(
        context,
        widget.tool.screenBuilder(widget.tool.heroTag),
        isAndroid: Theme.of(context).platform == TargetPlatform.android,
      ),
    );
  }
}
