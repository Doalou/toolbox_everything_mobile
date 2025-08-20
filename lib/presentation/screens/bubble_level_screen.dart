import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:toolbox_everything_mobile/core/providers/settings_provider.dart';

class BubbleLevelScreen extends StatefulWidget {
  final String heroTag;

  const BubbleLevelScreen({super.key, required this.heroTag});

  @override
  BubbleLevelScreenState createState() => BubbleLevelScreenState();
}

class BubbleLevelScreenState extends State<BubbleLevelScreen> {
  double x = 0.0;
  double y = 0.0;
  StreamSubscription<AccelerometerEvent>? _accelerometerSub;

  @override
  void initState() {
    super.initState();
    // Appliquer le verrouillage selon les paramètres utilisateur
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
      setState(() {
        x = event.x;
        y = event.y;
      });
    });
  }

  @override
  void dispose() {
    _accelerometerSub?.cancel();
    // Rétablir les orientations par défaut lorsque l'écran est quitté
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Hero(
          tag: widget.heroTag,
          child: Material(
            type: MaterialType.transparency,
            child: Text(
              'Niveau à bulle',
              style: Theme.of(context).appBarTheme.titleTextStyle,
            ),
          ),
        ),
      ),
      body: Center(
        child: CustomPaint(
          size: const Size(200, 200),
          painter: BubbleLevelPainter(
            x: x,
            y: y,
            dividerColor: Theme.of(context).dividerColor,
            primaryColor: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class BubbleLevelPainter extends CustomPainter {
  final double x;
  final double y;
  final Color dividerColor;
  final Color primaryColor;

  BubbleLevelPainter({
    required this.x,
    required this.y,
    required this.dividerColor,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final circlePaint = Paint()
      ..color = dividerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, radius, circlePaint);
    canvas.drawCircle(center, radius / 2, circlePaint);

    final bubblePaint = Paint()..color = primaryColor;
    final bubbleOffset = Offset(
      center.dx - x * (radius / 10),
      center.dy + y * (radius / 10),
    );
    canvas.drawCircle(bubbleOffset, 15, bubblePaint);
  }

  @override
  bool shouldRepaint(BubbleLevelPainter oldDelegate) {
    return x != oldDelegate.x || y != oldDelegate.y;
  }
}
