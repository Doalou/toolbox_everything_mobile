import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toolbox_everything_mobile/core/constants/app_constants.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_shapes.dart';
import 'package:toolbox_everything_mobile/core/services/app_feedback.dart';
import 'package:toolbox_everything_mobile/shared/widgets/editorial_tool_components.dart';
import 'package:toolbox_everything_mobile/shared/widgets/editorial_tool_scaffold.dart';
import 'package:toolbox_everything_mobile/shared/widgets/expressive_action_button.dart';
import 'package:toolbox_everything_mobile/shared/widgets/expressive_card.dart';
import 'package:toolbox_everything_mobile/shared/widgets/status_badge.dart';

class PasswordGeneratorScreen extends StatefulWidget {
  final String heroTag;

  const PasswordGeneratorScreen({super.key, required this.heroTag});

  @override
  PasswordGeneratorScreenState createState() => PasswordGeneratorScreenState();
}

class PasswordGeneratorScreenState extends State<PasswordGeneratorScreen> {
  String _password = '';
  double _length = 16.0;
  bool _includeUppercase = true;
  bool _includeLowercase = true;
  bool _includeNumbers = true;
  bool _includeSymbols = true;

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

    final length = _length.toInt().clamp(
      AppConstants.minPasswordLength,
      AppConstants.maxPasswordLength,
    );

    final random = Random.secure();
    final newPassword = String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );

    setState(() {
      _password = newPassword;

      if (!_passwordHistory.contains(newPassword)) {
        _passwordHistory.insert(0, newPassword);
        if (_passwordHistory.length > 20) {
          _passwordHistory = _passwordHistory.take(20).toList();
        }
      }
    });

    _startHistoryTimer();
  }

  void _startHistoryTimer() {
    _historyTimer?.cancel();
    setState(() {
      _showHistory = false;
    });

    _historyTimer = Timer(const Duration(seconds: 3), () {
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
      AppFeedback.copied(context, AppConstants.copySuccessMessage);
    }
  }

  void _copyPasswordFromHistory(String password) {
    Clipboard.setData(ClipboardData(text: password));
    AppFeedback.copied(context, 'Mot de passe copié !');
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

    return switch (score) {
      0 || 1 => 'Faible',
      2 || 3 => 'Moyen',
      4 => 'Fort',
      5 => 'Très fort',
      _ => '',
    };
  }

  BadgeTone get _strengthTone => switch (_strengthIndicator) {
    'Faible' => BadgeTone.danger,
    'Moyen' => BadgeTone.warning,
    'Fort' => BadgeTone.info,
    'Très fort' => BadgeTone.success,
    _ => BadgeTone.neutral,
  };

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

    return EditorialToolScaffold(
      title: 'Générateur de mot de passe',
      heroTag: widget.heroTag,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EditorialToolIntro(
              icon: Icons.password_rounded,
              title: 'Mots de passe robustes',
              description: 'Génération aléatoire cryptographiquement sûre.',
              trailing: _strengthIndicator.isNotEmpty
                  ? StatusBadge(
                      label: _strengthIndicator,
                      icon: Icons.shield_rounded,
                      tone: _strengthTone,
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            _buildPasswordField(context, colorScheme),
            const SizedBox(height: 16),
            ExpressiveActionButton.iconLabel(
              icon: Icons.refresh_rounded,
              label: 'Générer un nouveau mot de passe',
              onPressed: _generatePassword,
            ),
            const SizedBox(height: 16),
            _buildControlsSection(context),
            if (_showHistory && _passwordHistory.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildHistorySection(context, colorScheme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField(BuildContext context, ColorScheme colorScheme) {
    return ExpressiveCard.hero(
      color: colorScheme.primaryContainer.withValues(alpha: 0.65),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  _password,
                  style: TextStyle(
                    fontSize: 21,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                label: AppConstants.semanticCopyButton,
                child: IconButton.filled(
                  icon: const Icon(Icons.copy_rounded),
                  onPressed: _copyToClipboard,
                  tooltip: AppConstants.semanticCopyButton,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(BuildContext context, ColorScheme colorScheme) {
    return ExpressiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _PasswordCardIcon(
                icon: Icons.history_rounded,
                color: colorScheme.primary,
              ),
              const SizedBox(width: AppConstants.smallPadding),
              Expanded(
                child: Text(
                  'Historique (${_passwordHistory.length} derniers)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 96,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _passwordHistory.length,
              itemBuilder: (context, index) {
                final password = _passwordHistory[index];
                return Container(
                  width: 210,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(ExpressiveShapes.large),
                    border: Border.all(color: colorScheme.outlineVariant),
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
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _copyPasswordFromHistory(password),
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        '${password.length} caractères',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsSection(BuildContext context) {
    return ExpressiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Longueur', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              StatusBadge(
                label: '${_length.toInt()} caractères',
                tone: BadgeTone.accent,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Semantics(
            label: 'Curseur de longueur du mot de passe',
            value: '${_length.toInt()} caractères',
            child: Slider(
              value: _length,
              min: AppConstants.minPasswordLength.toDouble(),
              max: AppConstants.maxPasswordLength.toDouble(),
              divisions:
                  AppConstants.maxPasswordLength -
                  AppConstants.minPasswordLength,
              label: _length.toInt().toString(),
              onChanged: (value) {
                setState(() => _length = value);
                _generatePassword();
              },
            ),
          ),
          const Divider(),
          Text(
            'Types de caractères',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            title: const Text('Majuscules (A-Z)'),
            subtitle: const Text('ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
            value: _includeUppercase,
            onChanged: (value) {
              setState(() => _includeUppercase = value!);
              _generatePassword();
            },
          ),
          CheckboxListTile(
            title: const Text('Minuscules (a-z)'),
            subtitle: const Text('abcdefghijklmnopqrstuvwxyz'),
            value: _includeLowercase,
            onChanged: (value) {
              setState(() => _includeLowercase = value!);
              _generatePassword();
            },
          ),
          CheckboxListTile(
            title: const Text('Nombres (0-9)'),
            subtitle: const Text('0123456789'),
            value: _includeNumbers,
            onChanged: (value) {
              setState(() => _includeNumbers = value!);
              _generatePassword();
            },
          ),
          CheckboxListTile(
            title: const Text('Symboles (!@#\$%)'),
            subtitle: const Text('!@#\$%^&*()'),
            value: _includeSymbols,
            onChanged: (value) {
              setState(() => _includeSymbols = value!);
              _generatePassword();
            },
          ),
        ],
      ),
    );
  }
}

class _PasswordCardIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _PasswordCardIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: ShapeDecoration(
        color: color.withValues(alpha: 0.14),
        shape: const StadiumBorder(),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
