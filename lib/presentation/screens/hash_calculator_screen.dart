import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_shapes.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_tokens.dart';
import 'package:toolbox_everything_mobile/core/services/app_feedback.dart';
import 'package:toolbox_everything_mobile/core/services/haptics_service.dart';
import 'package:toolbox_everything_mobile/shared/widgets/editorial_tool_components.dart';
import 'package:toolbox_everything_mobile/shared/widgets/editorial_tool_scaffold.dart';
import 'package:toolbox_everything_mobile/shared/widgets/expressive_card.dart';

class HashCalculatorScreen extends StatefulWidget {
  final String heroTag;

  const HashCalculatorScreen({super.key, required this.heroTag});

  @override
  State<HashCalculatorScreen> createState() => _HashCalculatorScreenState();
}

class _HashCalculatorScreenState extends State<HashCalculatorScreen> {
  final TextEditingController _inputController = TextEditingController();
  final Map<HashType, TextEditingController> _resultControllers = {
    HashType.md5: TextEditingController(),
    HashType.sha256: TextEditingController(),
    HashType.sha512: TextEditingController(),
  };

  InputType _inputType = InputType.text;

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _inputController.dispose();
    for (final controller in _resultControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onInputChanged() {
    if (_inputController.text.isNotEmpty) {
      _calculateHashes();
    } else {
      _clearResults();
    }
  }

  void _calculateHashes() {
    if (_inputController.text.isEmpty) return;

    try {
      Uint8List bytes;

      if (_inputType == InputType.text) {
        bytes = Uint8List.fromList(utf8.encode(_inputController.text));
      } else {
        final cleanHex = _inputController.text
            .replaceAll(' ', '')
            .replaceAll('0x', '');
        if (cleanHex.length.isOdd) {
          _clearResults();
          return;
        }
        bytes = Uint8List.fromList(
          List.generate(
            cleanHex.length ~/ 2,
            (i) => int.parse(cleanHex.substring(i * 2, i * 2 + 2), radix: 16),
          ),
        );
      }

      final md5Hash = md5.convert(bytes);
      final sha256Hash = sha256.convert(bytes);
      final sha512Hash = sha512.convert(bytes);

      setState(() {
        _resultControllers[HashType.md5]!.text = md5Hash.toString();
        _resultControllers[HashType.sha256]!.text = sha256Hash.toString();
        _resultControllers[HashType.sha512]!.text = sha512Hash.toString();
      });
    } catch (e) {
      AppFeedback.show(
        context,
        'Erreur lors du calcul : $e',
        tone: FeedbackTone.error,
      );
    }
  }

  void _clearResults() {
    for (final controller in _resultControllers.values) {
      controller.clear();
    }
    setState(() {});
  }

  void _copyHash(HashType type) {
    final text = _resultControllers[type]!.text;
    if (text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: text));
      AppFeedback.copied(context, 'Hash ${_getHashName(type)} copié !');
    }
  }

  void _clearAll() {
    HapticsService.perform(context, HapticType.light);
    _inputController.clear();
    _clearResults();
  }

  String _getHashName(HashType type) => switch (type) {
    HashType.md5 => 'MD5',
    HashType.sha256 => 'SHA-256',
    HashType.sha512 => 'SHA-512',
  };

  IconData _getHashIcon(HashType type) => switch (type) {
    HashType.md5 => Icons.fingerprint_rounded,
    HashType.sha256 => Icons.security_rounded,
    HashType.sha512 => Icons.enhanced_encryption_rounded,
  };

  Color _getHashSeed(HashType type) => switch (type) {
    HashType.md5 => ExpressivePalette.lemonZest,
    HashType.sha256 => ExpressivePalette.violetVibrant,
    HashType.sha512 => ExpressivePalette.tealOptimist,
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return EditorialToolScaffold(
      title: 'Calculateur de hash',
      heroTag: widget.heroTag,
      actions: [
        IconButton(
          onPressed: _clearAll,
          icon: Icon(Icons.clear_all_rounded, color: colorScheme.primary),
          tooltip: 'Effacer tout',
        ),
      ],
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const EditorialToolIntro(
              icon: Icons.fingerprint_rounded,
              title: 'Calculer une empreinte',
              description: 'MD5, SHA-256 et SHA-512 calculés en temps réel.',
            ),
            const SizedBox(height: 16),
            SegmentedButton<InputType>(
              segments: const [
                ButtonSegment(
                  value: InputType.text,
                  icon: Icon(Icons.text_fields_rounded, size: 18),
                  label: Text('Texte UTF-8'),
                ),
                ButtonSegment(
                  value: InputType.hex,
                  icon: Icon(Icons.code_rounded, size: 18),
                  label: Text('Hexadécimal'),
                ),
              ],
              selected: {_inputType},
              onSelectionChanged: (newSelection) {
                HapticsService.perform(context, HapticType.selection);
                setState(() {
                  _inputType = newSelection.first;
                });
                _onInputChanged();
              },
            ),
            const SizedBox(height: 16),
            ExpressiveCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _inputType == InputType.text
                            ? Icons.text_fields_rounded
                            : Icons.code_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _inputType == InputType.text
                            ? 'Texte à hasher'
                            : 'Données hexadécimales',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _inputController,
                    maxLines: 4,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontFamily: _inputType == InputType.hex
                          ? 'monospace'
                          : null,
                    ),
                    decoration: InputDecoration(
                      hintText: _inputType == InputType.text
                          ? 'Saisissez votre texte ici…'
                          : 'Ex : 48656C6C6F',
                    ),
                    inputFormatters: _inputType == InputType.hex
                        ? [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9A-Fa-f\s]'),
                            ),
                          ]
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            for (final type in HashType.values) ...[
              _buildHashResult(type),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 4),
            _buildQuickExamples(),
          ],
        ),
      ),
    );
  }

  Widget _buildHashResult(HashType type) {
    final baseScheme = Theme.of(context).colorScheme;
    final hashScheme = ColorScheme.fromSeed(
      seedColor: _getHashSeed(type),
      brightness: baseScheme.brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
    );
    final result = _resultControllers[type]!.text;

    return ExpressiveCard(
      onTap: result.isNotEmpty ? () => _copyHash(type) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: hashScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(ExpressiveShapes.small),
                ),
                child: Icon(
                  _getHashIcon(type),
                  size: 18,
                  color: hashScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _getHashName(type),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              if (result.isNotEmpty)
                IconButton.filledTonal(
                  onPressed: () => _copyHash(type),
                  icon: const Icon(Icons.content_copy_rounded, size: 16),
                  tooltip: 'Copier',
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: baseScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(ExpressiveShapes.medium),
            ),
            child: SelectableText(
              result.isNotEmpty
                  ? result
                  : 'Hash ${_getHashName(type)} apparaîtra ici…',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                color: result.isNotEmpty
                    ? baseScheme.onSurface
                    : baseScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickExamples() {
    final colorScheme = Theme.of(context).colorScheme;

    const examples = [
      {'text': 'Hello World', 'label': 'Texte simple'},
      {'text': 'password123', 'label': 'Mot de passe'},
      {'text': 'Lorem ipsum dolor', 'label': 'Phrase'},
      {'text': '{"key": "value"}', 'label': 'JSON'},
    ];

    return ExpressiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flash_on_rounded,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Exemples rapides',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: examples.map((example) {
              return ActionChip(
                onPressed: () {
                  HapticsService.perform(context, HapticType.selection);
                  setState(() => _inputType = InputType.text);
                  _inputController.text = example['text']!;
                },
                avatar: const Icon(Icons.bolt_rounded, size: 16),
                label: Text('${example['label']} (${example['text']})'),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

enum HashType { md5, sha256, sha512 }

enum InputType { text, hex }
