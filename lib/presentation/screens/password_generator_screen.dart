import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:math';

class PasswordGeneratorScreen extends StatefulWidget {
  const PasswordGeneratorScreen({super.key});

  @override
  _PasswordGeneratorScreenState createState() => _PasswordGeneratorScreenState();
}

class _PasswordGeneratorScreenState extends State<PasswordGeneratorScreen> {
  String _password = '';
  double _length = 12.0;
  bool _includeUppercase = true;
  bool _includeLowercase = true;
  bool _includeNumbers = true;
  bool _includeSymbols = true;

  void _generatePassword() {
    String chars = '';
    if (_includeLowercase) chars += 'abcdefghijklmnopqrstuvwxyz';
    if (_includeUppercase) chars += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    if (_includeNumbers) chars += '0123456789';
    if (_includeSymbols) chars += '!@#\$%^&*()';

    if (chars.isEmpty) {
      setState(() {
        _password = 'Sélectionnez une option';
      });
      return;
    }

    Random random = Random.secure();
    setState(() {
      _password = String.fromCharCodes(Iterable.generate(
          _length.toInt(), (_) => chars.codeUnitAt(random.nextInt(chars.length))));
    });
  }

  @override
  void initState() {
    super.initState();
    _generatePassword();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Générateur de mot de passe'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                child: Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        _password,
                        style: const TextStyle(fontSize: 24, fontFamily: 'monospace'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _password));
                        Fluttertoast.showToast(msg: "Mot de passe copié !");
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Longueur: ${_length.toInt()}'),
            Slider(
              value: _length,
              min: 4,
              max: 32,
              divisions: 28,
              label: _length.toInt().toString(),
              onChanged: (value) {
                setState(() {
                  _length = value;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Majuscules (A-Z)'),
              value: _includeUppercase,
              onChanged: (value) {
                setState(() {
                  _includeUppercase = value!;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Minuscules (a-z)'),
              value: _includeLowercase,
              onChanged: (value) {
                setState(() {
                  _includeLowercase = value!;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Nombres (0-9)'),
              value: _includeNumbers,
              onChanged: (value) {
                setState(() {
                  _includeNumbers = value!;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Symboles (!@#\$%)'),
              value: _includeSymbols,
              onChanged: (value) {
                setState(() {
                  _includeSymbols = value!;
                });
              },
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _generatePassword,
              child: const Text('Générer'),
              // No style needed here, it comes from the theme
            ),
          ],
        ),
      ),
    );
  }
} 