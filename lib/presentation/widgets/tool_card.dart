import 'package:flutter/material.dart';
import 'package:toolbox_everything_mobile/core/models/tool_item.dart';
import 'package:toolbox_everything_mobile/core/constants/app_constants.dart';
import 'package:provider/provider.dart';
import 'package:toolbox_everything_mobile/core/providers/settings_provider.dart';

class ToolCard extends StatefulWidget {
  final ToolItem tool;
  final int animationDelay;
  final VoidCallback? onFavoriteToggle;

  const ToolCard({
    super.key,
    required this.tool,
    this.animationDelay = 0,
    this.onFavoriteToggle,
  });

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

    // Utilisation des couleurs expressives depuis les constantes
    final cardColor = AppConstants.expressiveColors.getColorByText(
      widget.tool.title,
    );

    return Semantics(
      label: 'Outil ${widget.tool.title}',
      hint: 'Appuyez pour ouvrir ${widget.tool.title}',
      button: true,
      child: MouseRegion(
        onEnter: (_) {
          if (!lowResourceMode) setState(() => _isHovered = true);
        },
        onExit: (_) {
          if (!lowResourceMode) setState(() => _isHovered = false);
        },
        child: AnimatedContainer(
          duration: lowResourceMode
              ? Duration.zero
              : AppConstants.mediumAnimation,
          curve: Curves.easeOutCubic,
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
            borderRadius: BorderRadius.circular(AppConstants.largeBorderRadius),
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon Container avec plus de caractère
                        AnimatedContainer(
                          duration: lowResourceMode
                              ? Duration.zero
                              : AppConstants.mediumAnimation,
                          padding: const EdgeInsets.all(
                            AppConstants.defaultPadding,
                          ),
                          decoration: BoxDecoration(
                            gradient: (_isHovered && !lowResourceMode)
                                ? RadialGradient(
                                    center: Alignment.center,
                                    colors: [
                                      cardColor.withValues(alpha: 0.8),
                                      cardColor.withValues(alpha: 0.6),
                                    ],
                                  )
                                : RadialGradient(
                                    center: Alignment.center,
                                    colors: [
                                      colorScheme.primaryContainer,
                                      colorScheme.primaryContainer.withValues(
                                        alpha: 0.8,
                                      ),
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(
                              AppConstants.defaultBorderRadius,
                            ),
                            boxShadow: (_isHovered && !lowResourceMode)
                                ? [
                                    BoxShadow(
                                      color: cardColor.withValues(alpha: 0.3),
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
                            child: Icon(
                              widget.tool.icon,
                              size: AppConstants.largeIconSize,
                              color: _isHovered
                                  ? Colors.white
                                  : colorScheme.onPrimaryContainer,
                              semanticLabel: 'Icône ${widget.tool.title}',
                            ),
                          ),
                        ),

                        const SizedBox(height: AppConstants.defaultPadding),

                        // Title
                        Expanded(
                          child: Center(
                            child: Text(
                              widget.tool.title,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                    height: 1.3,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),

                        const SizedBox(height: AppConstants.smallPadding),

                        // Interaction indicator plus attrayant
                        AnimatedContainer(
                          duration: lowResourceMode
                              ? Duration.zero
                              : AppConstants.mediumAnimation,
                          height: 4,
                          width: (_isHovered && !lowResourceMode) ? 50 : 25,
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
                                      color: cardColor.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bouton favori
                  Positioned(
                    top: 8,
                    right: 8,
                    child: AnimatedOpacity(
                      opacity: _isHovered || widget.tool.isFavorite ? 1.0 : 0.0,
                      duration: AppConstants.mediumAnimation,
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withValues(alpha: 0.2),
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
                                : colorScheme.onSurface.withValues(alpha: 0.6),
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
    );
  }

  void _navigateToTool(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            widget.tool.screenBuilder(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }
}
