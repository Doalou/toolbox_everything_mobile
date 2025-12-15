import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:toolbox_everything_mobile/core/constants/app_constants.dart';
import 'dart:math';
import 'dart:async';

class PasswordGeneratorScreen extends StatefulWidget {
  final String heroTag;

  const PasswordGeneratorScreen({super.key, required this.heroTag});

  @override
  PasswordGeneratorScreenState createState() => PasswordGeneratorScreenState();
}

class PasswordGeneratorScreenState extends State<PasswordGeneratorScreen> {
  String _password = '';
  double _length = 12.0;
  bool _includeUppercase = true;
  bool _includeLowercase = true;
  bool _includeNumbers = true;
  bool _includeSymbols = true;

  // Historique des mots de passe
  List<String> _passwordHistory = [];
  Timer? _historyTimer;
  bool _showHistory = false;

  void _generatePassword() {
    String chars = '';
    if (_includeLowercase) chars += 'abcdefghijklmnopqrstuvwxyz';
    if (_includeUppercase) chars += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    if (_includeNumbers) chars += '0123456789';
    if (_includeSymbols) chars += '!@#\$%^&*()';

    if (chars.isEmpty) {
      setState(() {
        _password = 'Sélectionnez au moins une option';
      });
      return;
    }

    // Validation de la longueur
    final length = _length.toInt().clamp(
      AppConstants.minPasswordLength,
      AppConstants.maxPasswordLength,
    );

    Random random = Random.secure();
    final newPassword = String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );

    setState(() {
      _password = newPassword;

      // Ajouter à l'historique
      if (!_passwordHistory.contains(newPassword)) {
        _passwordHistory.insert(0, newPassword);
        // Garder seulement les 20 derniers
        if (_passwordHistory.length > 20) {
          _passwordHistory = _passwordHistory.take(20).toList();
        }
      }
    });

    // Démarrer le timer pour afficher l'historique
    _startHistoryTimer();
  }

  void _startHistoryTimer() {
    _historyTimer?.cancel();
    setState(() {
      _showHistory = false;
    });

    _historyTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showHistory = true;
        });
      }
    });
  }

  void _copyToClipboard() {
    if (_password.isNotEmpty &&
        _password != 'Sélectionnez au moins une option') {
      Clipboard.setData(ClipboardData(text: _password));
      Fluttertoast.showToast(msg: AppConstants.copySuccessMessage);
    }
  }

  void _copyPasswordFromHistory(String password) {
    Clipboard.setData(ClipboardData(text: password));
    Fluttertoast.showToast(msg: 'Mot de passe copié !');
  }

  String get _strengthIndicator {
    if (_password.isEmpty || _password == 'Sélectionnez au moins une option') {
      return '';
    }

    int score = 0;
    if (_password.length >= 8) score++;
    if (_password.length >= 12) score++;
    if (_includeUppercase && _includeLowercase) score++;
    if (_includeNumbers) score++;
    if (_includeSymbols) score++;

    switch (score) {
      case 0:
      case 1:
        return 'Faible';
      case 2:
      case 3:
        return 'Moyen';
      case 4:
        return 'Fort';
      case 5:
        return 'Très fort';
      default:
        return '';
    }
  }

  Color get _strengthColor {
    switch (_strengthIndicator) {
      case 'Faible':
        return Colors.red;
      case 'Moyen':
        return Colors.orange;
      case 'Fort':
        return Colors.blue;
      case 'Très fort':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();
    _generatePassword();
  }

  @override
  void dispose() {
    _historyTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Hero(
          tag: widget.heroTag,
          child: Material(
            type: MaterialType.transparency,
            child: Text(
              'Générateur de mot de passe',
              style: Theme.of(context).appBarTheme.titleTextStyle,
            ),
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.largePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPasswordField(context, colorScheme),
            const SizedBox(height: AppConstants.largePadding),
            if (_showHistory && _passwordHistory.isNotEmpty) ...[
              _buildHistorySection(context, colorScheme),
              const SizedBox(height: AppConstants.largePadding),
            ],
            _buildControlsSection(context),
            const SizedBox(height: AppConstants.largePadding),
            ElevatedButton.icon(
              onPressed: _generatePassword,
              icon: const Icon(Icons.refresh),
              label: const Text('Générer un nouveau mot de passe'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: AppConstants.defaultPadding,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method for the password field card
  Widget _buildPasswordField(BuildContext context, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.defaultPadding,
          vertical: AppConstants.largePadding,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    _password,
                    style: const TextStyle(
                      fontSize: 20,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Semantics(
                  label: AppConstants.semanticCopyButton,
                  child: IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: _copyToClipboard,
                    tooltip: AppConstants.semanticCopyButton,
                  ),
                ),
              ],
            ),
            if (_strengthIndicator.isNotEmpty) ...[
              const SizedBox(height: AppConstants.defaultPadding),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.security,
                    color: _strengthColor,
                    size: AppConstants.smallIconSize,
                  ),
                  const SizedBox(width: AppConstants.smallPadding),
                  Text(
                    'Force: $_strengthIndicator',
                    style: TextStyle(
                      color: _strengthColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper method for the history section
  Widget _buildHistorySection(BuildContext context, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history,
                  color: colorScheme.primary,
                  size: AppConstants.smallIconSize,
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Text(
                  'Historique (${_passwordHistory.length} derniers)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _passwordHistory.length,
                itemBuilder: (context, index) {
                  final password = _passwordHistory[index];
                  return Container(
                    width: 200,
                    margin: const EdgeInsets.only(
                      right: AppConstants.smallPadding,
                    ),
                    padding: const EdgeInsets.all(AppConstants.smallPadding),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(
                        AppConstants.smallBorderRadius,
                      ),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                password,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  _copyPasswordFromHistory(password),
                              icon: const Icon(Icons.copy, size: 16),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          '${password.length} caractères',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method for the controls section
  Widget _buildControlsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Longueur
        Text(
          'Longueur: ${_length.toInt()} caractères',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        Semantics(
          label: 'Curseur de longueur du mot de passe',
          value: '${_length.toInt()} caractères',
          child: Slider(
            value: _length,
            min: AppConstants.minPasswordLength.toDouble(),
            max: AppConstants.maxPasswordLength.toDouble(),
            divisions:
                AppConstants.maxPasswordLength - AppConstants.minPasswordLength,
            label: _length.toInt().toString(),
            onChanged: (value) {
              setState(() {
                _length = value;
              });
              _generatePassword();
            },
          ),
        ),
        const SizedBox(height: AppConstants.largePadding),
        // Options de caractères
        Text(
          'Types de caractères',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        CheckboxListTile(
          title: const Text('Majuscules (A-Z)'),
          subtitle: const Text('ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
          value: _includeUppercase,
          onChanged: (value) {
            setState(() {
              _includeUppercase = value!;
            });
            _generatePassword();
          },
        ),
        CheckboxListTile(
          title: const Text('Minuscules (a-z)'),
          subtitle: const Text('abcdefghijklmnopqrstuvwxyz'),
          value: _includeLowercase,
          onChanged: (value) {
            setState(() {
              _includeLowercase = value!;
            });
            _generatePassword();
          },
        ),
        CheckboxListTile(
          title: const Text('Nombres (0-9)'),
          subtitle: const Text('0123456789'),
          value: _includeNumbers,
          onChanged: (value) {
            setState(() {
              _includeNumbers = value!;
            });
            _generatePassword();
          },
        ),
        CheckboxListTile(
          title: const Text('Symboles (!@#\$%)'),
          subtitle: const Text('!@#\$%^&*()'),
          value: _includeSymbols,
          onChanged: (value) {
            setState(() {
              _includeSymbols = value!;
            });
            _generatePassword();
          },
        ),
      ],
    );
  }
}
