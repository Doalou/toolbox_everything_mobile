import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_shapes.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_tokens.dart';
import 'package:toolbox_everything_mobile/shared/widgets/editorial_tool_components.dart';
import 'package:toolbox_everything_mobile/shared/widgets/editorial_tool_scaffold.dart';
import 'package:toolbox_everything_mobile/shared/widgets/expressive_card.dart';
import 'package:toolbox_everything_mobile/shared/widgets/status_badge.dart';

class CompassScreen extends StatefulWidget {
  final String heroTag;

  const CompassScreen({super.key, required this.heroTag});

  @override
  CompassScreenState createState() => CompassScreenState();
}

class CompassScreenState extends State<CompassScreen> {
  String _getDirection(double heading) {
    final normalized = (heading % 360 + 360) % 360;
    if (normalized >= 337.5 || normalized < 22.5) return 'Nord';
    if (normalized >= 22.5 && normalized < 67.5) return 'Nord-Est';
    if (normalized >= 67.5 && normalized < 112.5) return 'Est';
    if (normalized >= 112.5 && normalized < 157.5) return 'Sud-Est';
    if (normalized >= 157.5 && normalized < 202.5) return 'Sud';
    if (normalized >= 202.5 && normalized < 247.5) return 'Sud-Ouest';
    if (normalized >= 247.5 && normalized < 292.5) return 'Ouest';
    return 'Nord-Ouest';
  }

  Color _getDirectionSeed(double heading) {
    final normalized = (heading % 360 + 360) % 360;
    if (normalized >= 337.5 || normalized < 22.5) {
      return ExpressivePalette.sunsetCoral;
    }
    if (normalized >= 67.5 && normalized < 112.5) {
      return ExpressivePalette.lemonZest;
    }
    if (normalized >= 157.5 && normalized < 202.5) {
      return ExpressivePalette.tealOptimist;
    }
    if (normalized >= 247.5 && normalized < 292.5) {
      return ExpressivePalette.violetVibrant;
    }
    return ExpressivePalette.amberWarm;
  }

  void _showCalibrationGuide(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: ShapeDecoration(
                      color: scheme.primaryContainer,
                      shape: const StadiumBorder(),
                    ),
                    child: Icon(
                      Icons.compass_calibration_rounded,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Calibrer le magnétomètre',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Si l’orientation semble imprécise, effectuez un mouvement en forme de 8 dans les airs avec votre téléphone pendant quelques secondes et éloignez-vous des coques magnétiques ou objets métalliques.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Compris'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return EditorialToolScaffold(
      title: 'Boussole',
      heroTag: widget.heroTag,
      actions: [
        IconButton(
          onPressed: () => _showCalibrationGuide(context),
          icon: Icon(
            Icons.compass_calibration_rounded,
            color: colorScheme.primary,
          ),
          tooltip: 'Aide à la calibration',
        ),
      ],
      body: StreamBuilder<CompassEvent>(
        stream: FlutterCompass.events,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorView(snapshot.error.toString());
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingView();
          }

          final event = snapshot.data;
          final direction = event?.heading;

          if (direction == null) {
            return _buildUnsupportedView();
          }

          final normalizedHeading = (direction % 360 + 360) % 360;
          return _buildCompassView(
            normalizedHeading,
            event?.accuracy,
            colorScheme,
          );
        },
      ),
    );
  }

  Widget _buildCompassView(
    double direction,
    double? accuracy,
    ColorScheme colorScheme,
  ) {
    final directionName = _getDirection(direction);
    final seed = _getDirectionSeed(direction);
    final dirScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: colorScheme.brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
    );
    final directionColor = dirScheme.primary;
    final needsCalibration = accuracy != null && accuracy > 25;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        children: [
          EditorialToolIntro(
            icon: Icons.explore_rounded,
            title: 'Boussole numérique',
            description: needsCalibration
                ? 'Précision réduite (±${accuracy.toStringAsFixed(0)}°) · mouvement en 8 conseillé.'
                : 'Pointez l’appareil vers la direction souhaitée.',
            accent: directionColor,
            trailing: StatusBadge(
              label: '${direction.toStringAsFixed(0)}°',
              icon: Icons.navigation_rounded,
              tone: needsCalibration ? BadgeTone.warning : BadgeTone.accent,
            ),
          ),
          const SizedBox(height: 18),
          ExpressiveCard(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Center(
              child: _buildCompassRose(direction, directionColor, dirScheme),
            ),
          ),
          const SizedBox(height: 16),
          _buildDirectionInfo(direction, directionName, accuracy, dirScheme),
          const SizedBox(height: 16),
          _buildAdditionalInfo(direction, colorScheme),
        ],
      ),
    );
  }

  Widget _buildCompassRose(
    double direction,
    Color directionColor,
    ColorScheme dirScheme,
  ) {
    return Container(
      width: 232,
      height: 232,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: dirScheme.primaryContainer.withValues(alpha: 0.25),
        border: Border.all(
          color: directionColor.withValues(alpha: 0.35),
          width: 2.5,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: -direction * (math.pi / 180),
            child: Stack(
              alignment: Alignment.center,
              children: [
                ...List.generate(8, (index) {
                  final angle = index * 45.0;
                  final isCardinal = index % 2 == 0;
                  final isNorth = index == 0;
                  return Transform.rotate(
                    angle: angle * (math.pi / 180),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        margin: const EdgeInsets.only(top: 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: isCardinal ? 4 : 2,
                              height: isCardinal ? 18 : 10,
                              decoration: BoxDecoration(
                                color: isNorth
                                    ? dirScheme.error
                                    : isCardinal
                                    ? directionColor
                                    : directionColor.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            if (isCardinal) ...[
                              const SizedBox(height: 6),
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
                                    color: isNorth
                                        ? dirScheme.error
                                        : directionColor,
                                    fontWeight: FontWeight.w800,
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
          // Aiguille principale
          Container(
            width: 6,
            height: 112,
            decoration: BoxDecoration(
              color: directionColor,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          // Centre
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: directionColor,
              shape: BoxShape.circle,
              border: Border.all(color: dirScheme.surface, width: 3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionInfo(
    double direction,
    String directionName,
    double? accuracy,
    ColorScheme dirScheme,
  ) {
    final lowAccuracy = accuracy != null && accuracy > 25;
    final accuracyText = accuracy == null
        ? 'Capteur magnétique actif'
        : lowAccuracy
        ? 'Précision faible (±${accuracy.toStringAsFixed(0)}°)'
        : 'Précision élevée (±${accuracy.toStringAsFixed(0)}°)';

    return ExpressiveCard.hero(
      color: dirScheme.primaryContainer.withValues(alpha: 0.55),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: dirScheme.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(ExpressiveShapes.medium),
                ),
                child: Icon(
                  Icons.navigation_rounded,
                  color: dirScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Direction actuelle',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: dirScheme.onPrimaryContainer.withValues(
                          alpha: 0.78,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      directionName,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: dirScheme.onPrimaryContainer,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: ShapeDecoration(
                  color: dirScheme.surface.withValues(alpha: 0.78),
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  '${direction.toStringAsFixed(1)}°',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: dirScheme.primary,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                lowAccuracy
                    ? Icons.warning_amber_rounded
                    : Icons.gps_fixed_rounded,
                color: lowAccuracy ? dirScheme.error : dirScheme.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  accuracyText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: dirScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo(double direction, ColorScheme colorScheme) {
    return ExpressiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text('Repères', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoTile(
                  'Azimut',
                  '${direction.toStringAsFixed(0)}°',
                  Icons.rotate_right_rounded,
                  colorScheme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoTile(
                  'Cap opposé',
                  '${((direction + 180) % 360).toStringAsFixed(0)}°',
                  Icons.swap_calls_rounded,
                  colorScheme,
                ),
              ),
            ],
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(ExpressiveShapes.large),
      ),
      child: Column(
        children: [
          Icon(icon, color: colorScheme.primary, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ExpressiveCard(
          color: colorScheme.errorContainer,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: colorScheme.onErrorContainer,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Erreur de la boussole',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colorScheme.onErrorContainer,
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
      ),
    );
  }

  Widget _buildUnsupportedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ExpressiveCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.compass_calibration_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Boussole non disponible',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Votre appareil ne dispose pas de magnétomètre compatible.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
