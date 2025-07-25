import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('À propos')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Toolbox Everything', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text('Version 1.0.0'),
              SizedBox(height: 20),
              Text(
                'Une collection d\'outils pratiques pour les développeurs et les curieux.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 