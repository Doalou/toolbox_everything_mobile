import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:math' as math;

class CompassScreen extends StatefulWidget {
  const CompassScreen({super.key});

  @override
  _CompassScreenState createState() => _CompassScreenState();
}

class _CompassScreenState extends State<CompassScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Boussole')),
      body: StreamBuilder<CompassEvent>(
        stream: FlutterCompass.events,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          double? direction = snapshot.data!.heading;

          if (direction == null) {
            return const Center(child: Text("L'appareil ne supporte pas les capteurs nécessaires"));
          }

          return Center(
            child: Transform.rotate(
              angle: (direction * (math.pi / 180) * -1),
              child: Image.asset('lib/assets/images/compass.png'),
            ),
          );
        },
      ),
    );
  }
} 