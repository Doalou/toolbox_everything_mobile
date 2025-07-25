import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class BubbleLevelScreen extends StatefulWidget {
  const BubbleLevelScreen({super.key});

  @override
  _BubbleLevelScreenState createState() => _BubbleLevelScreenState();
}

class _BubbleLevelScreenState extends State<BubbleLevelScreen> {
  double _x = 0.0, _y = 0.0;

  @override
  void initState() {
    super.initState();
    accelerometerEventStream().listen((AccelerometerEvent event) {
      setState(() {
        _x = event.x;
        _y = event.y;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Niveau à bulle')),
      body: Center(
        child: CustomPaint(
          size: const Size(200, 200),
          painter: BubbleLevelPainter(
            x: _x,
            y: _y,
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