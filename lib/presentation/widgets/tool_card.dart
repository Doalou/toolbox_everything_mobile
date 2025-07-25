import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:toolbox_everything_mobile/core/models/tool_item.dart';

class ToolCard extends StatefulWidget {
  final ToolItem tool;
  final int animationDelay;

  const ToolCard({
    super.key, 
    required this.tool,
    this.animationDelay = 0,
  });

  @override
  State<ToolCard> createState() => _ToolCardState();
}

class _ToolCardState extends State<ToolCard> 
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _tapController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _tapScaleAnimation;
  
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    
    // Animation controller pour le hover
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Animation controller pour le tap
    _tapController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.03,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOutCubic,
    ));
    
    _elevationAnimation = Tween<double>(
      begin: 0.0,
      end: 12.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOutCubic,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOutCubic,
    ));
    
    _tapScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _tapController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _tapController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _tapController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _tapController.reverse();
  }

  void _onTapCancel() {
    _tapController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return FadeInUp(
      delay: Duration(milliseconds: widget.animationDelay),
      duration: const Duration(milliseconds: 800),
      child: AnimatedBuilder(
        animation: Listenable.merge([_hoverController, _tapController]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value * _tapScaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  // Ombre principale
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.08),
                    blurRadius: 8 + (_elevationAnimation.value * 0.5),
                    offset: Offset(0, 4 + (_elevationAnimation.value * 0.3)),
                  ),
                  // Glow effect
                  if (_glowAnimation.value > 0)
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.1 * _glowAnimation.value),
                      blurRadius: 20 * _glowAnimation.value,
                      offset: const Offset(0, 0),
                    ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.surfaceContainer,
                        colorScheme.surfaceContainerLow,
                      ],
                      stops: const [0.0, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _isHovered 
                          ? colorScheme.primary.withOpacity(0.2)
                          : colorScheme.outlineVariant.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    splashColor: colorScheme.primary.withOpacity(0.1),
                    highlightColor: colorScheme.primary.withOpacity(0.05),
                    onTapDown: _onTapDown,
                    onTapUp: _onTapUp,
                    onTapCancel: _onTapCancel,
                    onTap: () {
                      // Haptic feedback
                      // HapticFeedback.lightImpact();
                      
                      // Navigation avec animation héroïque
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => widget.tool.screen,
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            const begin = Offset(1.0, 0.0);
                            const end = Offset.zero;
                            const curve = Curves.easeOutCubic;

                            var tween = Tween(begin: begin, end: end).chain(
                              CurveTween(curve: curve),
                            );

                            return SlideTransition(
                              position: animation.drive(tween),
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                          transitionDuration: const Duration(milliseconds: 500),
                        ),
                      );
                    },
                    onHover: (hovering) {
                      setState(() {
                        _isHovered = hovering;
                      });
                      if (hovering) {
                        _hoverController.forward();
                      } else {
                        _hoverController.reverse();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Icône avec effet de glow animé
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  colorScheme.primaryContainer.withOpacity(
                                    0.2 + (0.1 * _glowAnimation.value)
                                  ),
                                  colorScheme.primaryContainer.withOpacity(
                                    0.05 + (0.05 * _glowAnimation.value)
                                  ),
                                ],
                              ),
                              boxShadow: [
                                if (_glowAnimation.value > 0)
                                  BoxShadow(
                                    color: colorScheme.primary.withOpacity(
                                      0.15 * _glowAnimation.value
                                    ),
                                    blurRadius: 16 * _glowAnimation.value,
                                    offset: const Offset(0, 0),
                                  ),
                              ],
                            ),
                            child: AnimatedScale(
                              scale: 1.0 + (0.1 * _glowAnimation.value),
                              duration: const Duration(milliseconds: 300),
                              child: Icon(
                                widget.tool.icon,
                                size: 36.0,
                                color: Color.lerp(
                                  colorScheme.primary,
                                  colorScheme.primary,
                                  _glowAnimation.value,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Titre avec style expressif
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                              fontSize: 16 + (1 * _glowAnimation.value),
                            ) ?? const TextStyle(),
                            child: Flexible(
                              child: Text(
                                widget.tool.title,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Indicateur d'interaction avec animation
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            height: 3,
                            width: _isHovered ? 60 : 30,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.primary.withOpacity(
                                    _isHovered ? 1.0 : 0.4
                                  ),
                                  colorScheme.primary.withOpacity(
                                    _isHovered ? 0.3 : 0.1
                                  ),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(1.5),
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
        },
      ),
    );
  }
}