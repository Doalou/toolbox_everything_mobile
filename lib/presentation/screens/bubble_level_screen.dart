import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_shapes.dart';
import 'package:toolbox_everything_mobile/core/providers/settings_provider.dart';
import 'package:toolbox_everything_mobile/core/services/app_feedback.dart';
import 'package:toolbox_everything_mobile/core/services/haptics_service.dart';
import 'package:toolbox_everything_mobile/shared/widgets/editorial_tool_components.dart';
import 'package:toolbox_everything_mobile/shared/widgets/editorial_tool_scaffold.dart';
import 'package:toolbox_everything_mobile/shared/widgets/expressive_action_button.dart';
import 'package:toolbox_everything_mobile/shared/widgets/expressive_card.dart';
import 'package:toolbox_everything_mobile/shared/widgets/status_badge.dart';

class BubbleLevelScreen extends StatefulWidget {
  final String heroTag;

  const BubbleLevelScreen({super.key, required this.heroTag});

  @override
  BubbleLevelScreenState createState() => BubbleLevelScreenState();
}

class BubbleLevelScreenState extends State<BubbleLevelScreen> {
  double _rawX = 0.0;
  double _rawY = 0.0;
  double _offsetX = 0.0;
  double _offsetY = 0.0;
  bool _wasLevel = false;
  StreamSubscription<AccelerometerEvent>? _accelerometerSub;

  double get _calibratedX => _rawX - _offsetX;
  double get _calibratedY => _rawY - _offsetY;

  double get _angleXDeg =>
      (math.atan2(_calibratedX, 9.81) * 180 / math.pi).clamp(-90.0, 90.0);
  double get _angleYDeg =>
      (math.atan2(_calibratedY, 9.81) * 180 / math.pi).clamp(-90.0, 90.0);
  double get _totalTiltDeg => math
      .sqrt(_angleXDeg * _angleXDeg + _angleYDeg * _angleYDeg)
      .clamp(0.0, 90.0);

  bool get _isLevel => _totalTiltDeg < 1.0;
  bool get _hasCalibration => _offsetX != 0.0 || _offsetY != 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      if (settings.lockBubbleLevelPortrait) {
        SystemChrome.setPreferredOrientations(const [
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      }
    });
    _accelerometerSub = accelerometerEventStream().listen((
      AccelerometerEvent event,
    ) {
      if (!mounted) return;
      // Lissage léger passe-bas pour éviter le tremblement excessif
      setState(() {
        _rawX = _rawX * 0.7 + event.x * 0.3;
        _rawY = _rawY * 0.7 + event.y * 0.3;
      });
      final nowLevel = _isLevel;
      if (nowLevel && !_wasLevel) {
        HapticsService.perform(context, HapticType.selection);
      }
      _wasLevel = nowLevel;
    });
  }

  @override
  void dispose() {
    _accelerometerSub?.cancel();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void _calibrateZero() {
    setState(() {
      _offsetX = _rawX;
      _offsetY = _rawY;
    });
    AppFeedback.show(
      context,
      'Surface actuelle définie comme référence 0°',
      tone: FeedbackTone.success,
      icon: Icons.straighten_rounded,
    );
  }

  void _resetCalibration() {
    setState(() {
      _offsetX = 0.0;
      _offsetY = 0.0;
    });
    AppFeedback.show(context, 'Calibration réinitialisée');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final levelAccent = _isLevel ? scheme.tertiary : scheme.primary;

    return EditorialToolScaffold(
      title: 'Niveau à bulle',
      heroTag: widget.heroTag,
      actions: [
        if (_hasCalibration)
          IconButton(
            onPressed: _resetCalibration,
            tooltip: 'Réinitialiser le tarage',
            icon: const Icon(Icons.restart_alt_rounded),
          ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EditorialToolIntro(
              icon: Icons.architecture_rounded,
              title: _isLevel ? 'Surface de niveau' : 'Mesure d’inclinaison',
              description: _hasCalibration
                  ? 'Tarage personnalisé actif · posez l’appareil à plat.'
                  : 'Posez votre appareil à plat pour vérifier l’horizontalité.',
              accent: levelAccent,
              trailing: StatusBadge(
                label: '${_totalTiltDeg.toStringAsFixed(1)}°',
                icon: _isLevel
                    ? Icons.check_circle_rounded
                    : Icons.compass_calibration_rounded,
                tone: _isLevel ? BadgeTone.success : BadgeTone.accent,
              ),
            ),
            const SizedBox(height: 16),
            ExpressiveCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  SizedBox(
                    width: 208,
                    height: 208,
                    child: CustomPaint(
                      size: const Size(208, 208),
                      painter: BubbleLevelPainter(
                        x: _calibratedX,
                        y: _calibratedY,
                        isLevel: _isLevel,
                        dividerColor: scheme.outlineVariant,
                        primaryColor: levelAccent,
                        containerColor: scheme.surfaceContainerHigh,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _AxisBar(
                    label: 'Axe X (Gauche / Droite)',
                    angleDeg: _angleXDeg,
                    accent: levelAccent,
                  ),
                  const SizedBox(height: 12),
                  _AxisBar(
                    label: 'Axe Y (Avant / Arrière)',
                    angleDeg: _angleYDeg,
                    accent: levelAccent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _AngleMetricCard(
                    title: 'Roulis (X)',
                    value: '${_angleXDeg.toStringAsFixed(1)}°',
                    icon: Icons.swap_horiz_rounded,
                    highlight: _angleXDeg.abs() < 1.0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AngleMetricCard(
                    title: 'Tangage (Y)',
                    value: '${_angleYDeg.toStringAsFixed(1)}°',
                    icon: Icons.swap_vert_rounded,
                    highlight: _angleYDeg.abs() < 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                ExpressiveActionButton.iconLabel(
                  icon: Icons.center_focus_strong_rounded,
                  label: 'Calibrer 0° ici',
                  onPressed: _calibrateZero,
                ),
                if (_hasCalibration)
                  ExpressiveActionButton.iconLabel(
                    icon: Icons.restart_alt_rounded,
                    label: 'Valeurs brutes',
                    onPressed: _resetCalibration,
                    tonal: true,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AxisBar extends StatelessWidget {
  final String label;
  final double angleDeg;
  final Color accent;

  const _AxisBar({
    required this.label,
    required this.angleDeg,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final normalized = (angleDeg / 45.0).clamp(-1.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const Spacer(),
            Text(
              '${angleDeg >= 0 ? '+' : ''}${angleDeg.toStringAsFixed(1)}°',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontFamily: 'monospace',
                color: accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 22,
          decoration: ShapeDecoration(
            color: scheme.surfaceContainerLow,
            shape: const StadiumBorder(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(width: 2, height: 14, color: scheme.outlineVariant),
              Align(
                alignment: Alignment(normalized, 0),
                child: Container(
                  width: 28,
                  height: 14,
                  decoration: ShapeDecoration(
                    color: accent,
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AngleMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool highlight;

  const _AngleMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = highlight
        ? scheme.tertiaryContainer.withValues(alpha: 0.65)
        : scheme.surfaceContainerLow;
    final fg = highlight ? scheme.onTertiaryContainer : scheme.onSurface;

    return ExpressiveCard(
      color: bg,
      dense: true,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: fg.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(ExpressiveShapes.small),
            ),
            child: Icon(icon, color: fg, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: fg.withValues(alpha: 0.78),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontFamily: 'monospace',
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BubbleLevelPainter extends CustomPainter {
  final double x;
  final double y;
  final bool isLevel;
  final Color dividerColor;
  final Color primaryColor;
  final Color containerColor;

  BubbleLevelPainter({
    required this.x,
    required this.y,
    this.isLevel = false,
    required this.dividerColor,
    required this.primaryColor,
    this.containerColor = Colors.transparent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    if (containerColor != Colors.transparent) {
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = containerColor.withValues(alpha: 0.45),
      );
    }

    final circlePaint = Paint()
      ..color = dividerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, radius, circlePaint);
    canvas.drawCircle(center, radius * 0.62, circlePaint);
    canvas.drawCircle(
      center,
      24,
      Paint()
        ..color = primaryColor.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Axes croisés
    final axisPaint = Paint()
      ..color = dividerColor.withValues(alpha: 0.6)
      ..strokeWidth = 1.2;
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      axisPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      axisPaint,
    );

    // Position de la bulle bornée dans le cercle
    final rawDx = -x * (radius / 10);
    final rawDy = y * (radius / 10);
    final dist = math.sqrt(rawDx * rawDx + rawDy * rawDy);
    final maxDist = radius - 20;
    final scale = dist > maxDist && dist > 0 ? maxDist / dist : 1.0;

    final bubbleOffset = Offset(
      center.dx + rawDx * scale,
      center.dy + rawDy * scale,
    );

    canvas.drawCircle(
      bubbleOffset,
      20,
      Paint()..color = primaryColor.withValues(alpha: 0.24),
    );
    canvas.drawCircle(bubbleOffset, 15, Paint()..color = primaryColor);
  }

  @override
  bool shouldRepaint(BubbleLevelPainter oldDelegate) {
    return x != oldDelegate.x ||
        y != oldDelegate.y ||
        isLevel != oldDelegate.isLevel ||
        primaryColor != oldDelegate.primaryColor;
  }
}
