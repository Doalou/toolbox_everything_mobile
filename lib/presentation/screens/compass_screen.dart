import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:math' as math;

class CompassScreen extends StatefulWidget {
  final String heroTag;

  const CompassScreen({super.key, required this.heroTag});

  @override
  CompassScreenState createState() => CompassScreenState();
}

class CompassScreenState extends State<CompassScreen>
    with TickerProviderStateMixin {
  bool _isCalibrating = true;

  @override
  void initState() {
    super.initState();

    // Simuler la calibration
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isCalibrating = false;
        });
      }
    });
  }


  String _getDirection(double heading) {
    if (heading >= 337.5 || heading < 22.5) {
      return 'Nord';
    }
    if (heading >= 22.5 && heading < 67.5) {
      return 'Nord-Est';
    }
    if (heading >= 67.5 && heading < 112.5) {
      return 'Est';
    }
    if (heading >= 112.5 && heading < 157.5) {
      return 'Sud-Est';
    }
    if (heading >= 157.5 && heading < 202.5) {
      return 'Sud';
    }
    if (heading >= 202.5 && heading < 247.5) {
      return 'Sud-Ouest';
    }
    if (heading >= 247.5 && heading < 292.5) {
      return 'Ouest';
    }
    if (heading >= 292.5 && heading < 337.5) {
      return 'Nord-Ouest';
    }
    return 'Inconnu';
  }

  Color _getDirectionColor(double heading) {
    if (heading >= 337.5 || heading < 22.5) {
      return const Color(0xFFE53E3E); // Nord - Rouge
    }
    if (heading >= 67.5 && heading < 112.5) {
      return const Color(0xFFFF9500); // Est - Orange
    }
    if (heading >= 157.5 && heading < 202.5) {
      return const Color(0xFF38A169); // Sud - Vert
    }
    if (heading >= 247.5 && heading < 292.5) {
      return const Color(0xFF3182CE); // Ouest - Bleu
    }
    return const Color(0xFF805AD5); // Directions intermédiaires - Violet
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Hero(
          tag: widget.heroTag,
          child: Material(
            type: MaterialType.transparency,
            child: Text(
              'Boussole',
              style: Theme.of(context).appBarTheme.titleTextStyle,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isCalibrating = true;
              });
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  setState(() {
                    _isCalibrating = false;
                  });
                }
              });
            },
            icon: Icon(Icons.refresh, color: colorScheme.primary),
            tooltip: 'Recalibrer',
          ),
        ],
      ),
      body: StreamBuilder<CompassEvent>(
        stream: FlutterCompass.events,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorView(snapshot.error.toString());
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingView();
          }

          double? direction = snapshot.data?.heading;

          if (direction == null) {
            return _buildUnsupportedView();
          }


          return _buildCompassView(direction, colorScheme);
        },
      ),
    );
  }

  Widget _buildCompassView(double direction, ColorScheme colorScheme) {
    final directionName = _getDirection(direction);
    final directionColor = _getDirectionColor(direction);

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: directionColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.explore, size: 32, color: directionColor),
                ),
                const SizedBox(height: 16),
                Text(
                  'Boussole numérique',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                if (_isCalibrating)
                  Text(
                    'Calibration en cours...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: directionColor,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  Text(
                    'Pointez votre appareil vers la direction souhaitée',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Boussole principale
          _buildCompassRose(direction, directionColor),

          const SizedBox(height: 40),

          // Informations détaillées
          _buildDirectionInfo(
            direction,
            directionName,
            directionColor,
            colorScheme,
          ),

          const SizedBox(height: 24),

          // Coordonnées et conseils
          _buildAdditionalInfo(direction, colorScheme),
        ],
      ),
    );
  }

  Widget _buildCompassRose(double direction, Color directionColor) {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: directionColor.withValues(alpha: 0.3),
          width: 2,
        ),
        color: Colors.transparent,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rose de la boussole qui tourne (laisse l'aiguille fixe)
          Transform.rotate(
            angle: -direction * (math.pi / 180),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Graduations et étiquettes cardinales
                ...List.generate(8, (index) {
                  final angle = index * 45.0;
                  final isCardinal = index % 2 == 0;
                  return Transform.rotate(
                    angle: angle * (math.pi / 180),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        margin: const EdgeInsets.only(top: 10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: isCardinal ? 4 : 2,
                              height: isCardinal ? 20 : 12,
                              decoration: BoxDecoration(
                                color: isCardinal
                                    ? directionColor
                                    : directionColor.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            if (isCardinal) ...[
                              const SizedBox(height: 8),
                              Transform.rotate(
                                angle: -angle * (math.pi / 180),
                                child: Text(
                                  [
                                    'N',
                                    'NE',
                                    'E',
                                    'SE',
                                    'S',
                                    'SO',
                                    'O',
                                    'NO',
                                  ][index],
                                  style: TextStyle(
                                    color: directionColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          // Aiguille principale (fixe, pointe vers le haut)
          Container(
            width: 6,
            height: 120,
            decoration: BoxDecoration(
              color: directionColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Centre de la boussole
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: directionColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: directionColor.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionInfo(
    double direction,
    String directionName,
    Color directionColor,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: directionColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: directionColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: directionColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.navigation, color: directionColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Direction actuelle',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      directionName,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: directionColor,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: directionColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${direction.toStringAsFixed(1)}°',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: directionColor,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Indicateur de précision
          Row(
            children: [
              Icon(
                _isCalibrating ? Icons.warning_amber : Icons.gps_fixed,
                color: _isCalibrating ? Colors.orange : Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _isCalibrating ? 'Calibration en cours...' : 'Précision élevée',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _isCalibrating ? Colors.orange : Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo(double direction, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Informations complémentaires',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Grille d'informations
          Row(
            children: [
              Expanded(
                child: _buildInfoTile(
                  'Azimut',
                  '${direction.toStringAsFixed(0)}°',
                  Icons.rotate_right,
                  colorScheme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoTile(
                  'Magnétique',
                  'Nord Mag.',
                  Icons.explore,
                  colorScheme,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Conseils d'utilisation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tenez votre appareil à plat et loin des objets métalliques pour une meilleure précision.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    String label,
    String value,
    IconData icon,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: colorScheme.primary, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Initialisation de la boussole...'),
        ],
      ),
    );
  }

  Widget _buildErrorView(String error) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: colorScheme.onErrorContainer,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de la boussole',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnsupportedView() {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.compass_calibration,
              color: colorScheme.primary,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Boussole non disponible',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Votre appareil ne dispose pas des capteurs nécessaires pour utiliser la boussole.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
