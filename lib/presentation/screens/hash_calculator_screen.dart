import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class HashCalculatorScreen extends StatefulWidget {
  final String heroTag;

  const HashCalculatorScreen({super.key, required this.heroTag});

  @override
  State<HashCalculatorScreen> createState() => _HashCalculatorScreenState();
}

class _HashCalculatorScreenState extends State<HashCalculatorScreen>
    with TickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final Map<HashType, TextEditingController> _resultControllers = {
    HashType.md5: TextEditingController(),
    HashType.sha256: TextEditingController(),
    HashType.sha512: TextEditingController(),
  };

  late AnimationController _calculateController;
  late Animation<double> _calculateAnimation;

  InputType _inputType = InputType.text;
  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();

    _calculateController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _calculateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _calculateController, curve: Curves.easeInOut),
    );

    _inputController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _calculateController.dispose();
    _inputController.dispose();
    for (var controller in _resultControllers.values) {
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

  Future<void> _calculateHashes() async {
    if (_inputController.text.isEmpty) return;

    setState(() {
      _isCalculating = true;
    });

    _calculateController.forward();

    try {
      Uint8List bytes;

      if (_inputType == InputType.text) {
        bytes = utf8.encode(_inputController.text);
      } else {
        // Hexadécimal input
        final cleanHex = _inputController.text
            .replaceAll(' ', '')
            .replaceAll('0x', '');
        if (cleanHex.length % 2 != 0) {
          _showError('Format hexadécimal invalide');
          return;
        }
        bytes = Uint8List.fromList(
          List.generate(
            cleanHex.length ~/ 2,
            (i) => int.parse(cleanHex.substring(i * 2, i * 2 + 2), radix: 16),
          ),
        );
      }

      // Calcul des hash
      final md5Hash = md5.convert(bytes);
      final sha256Hash = sha256.convert(bytes);
      final sha512Hash = sha512.convert(bytes);

      setState(() {
        _resultControllers[HashType.md5]!.text = md5Hash.toString();
        _resultControllers[HashType.sha256]!.text = sha256Hash.toString();
        _resultControllers[HashType.sha512]!.text = sha512Hash.toString();
        _isCalculating = false;
      });
    } catch (e) {
      _showError('Erreur lors du calcul: $e');
      setState(() {
        _isCalculating = false;
      });
    }

    await Future.delayed(const Duration(milliseconds: 300));
    _calculateController.reverse();
  }

  void _clearResults() {
    for (var controller in _resultControllers.values) {
      controller.clear();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _copyHash(HashType type) {
    final text = _resultControllers[type]!.text;
    if (text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hash ${_getHashName(type)} copié !'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _clearAll() {
    _inputController.clear();
    _clearResults();
  }

  String _getHashName(HashType type) {
    switch (type) {
      case HashType.md5:
        return 'MD5';
      case HashType.sha256:
        return 'SHA-256';
      case HashType.sha512:
        return 'SHA-512';
    }
  }

  IconData _getHashIcon(HashType type) {
    switch (type) {
      case HashType.md5:
        return Icons.fingerprint;
      case HashType.sha256:
        return Icons.security;
      case HashType.sha512:
        return Icons.enhanced_encryption;
    }
  }

  Color _getHashColor(HashType type, ColorScheme colorScheme) {
    switch (type) {
      case HashType.md5:
        return Colors.orange;
      case HashType.sha256:
        return Colors.blue;
      case HashType.sha512:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Hero(
          tag: widget.heroTag,
          child: Material(
            type: MaterialType.transparency,
            child: Text(
              'Calculateur de Hash',
              style: Theme.of(context).appBarTheme.titleTextStyle,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _clearAll,
            icon: Icon(Icons.clear_all, color: colorScheme.primary),
            tooltip: 'Effacer tout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(Icons.fingerprint, size: 48, color: colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    'Calculateur de Hash',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'MD5 • SHA-256 • SHA-512',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Type d'entrée
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Type d\'entrée',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<InputType>(
                    segments: const [
                      ButtonSegment(
                        value: InputType.text,
                        icon: Icon(Icons.text_fields, size: 16),
                        label: Text('Texte'),
                      ),
                      ButtonSegment(
                        value: InputType.hex,
                        icon: Icon(Icons.code, size: 16),
                        label: Text('Hexadécimal'),
                      ),
                    ],
                    selected: {_inputType},
                    onSelectionChanged: (newSelection) {
                      setState(() {
                        _inputType = newSelection.first;
                      });
                      _onInputChanged();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Zone de saisie
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          _inputType == InputType.text
                              ? Icons.text_fields
                              : Icons.code,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _inputType == InputType.text
                              ? 'Texte à hasher'
                              : 'Données hexadécimales',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        if (_isCalculating)
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.primary,
                            ),
                          ),
                      ],
                    ),
                  ),
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
                          ? 'Saisissez votre texte ici...'
                          : 'Saisissez vos données en hexadécimal (ex: 48656C6C6F)',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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

            const SizedBox(height: 32),

            // Résultats des hash
            AnimatedBuilder(
              animation: _calculateAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1 + (_calculateAnimation.value * 0.02),
                  child: Column(
                    children: HashType.values.map((type) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: _buildHashResult(type),
                      );
                    }).toList(),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Exemples rapides
            _buildQuickExamples(),
          ],
        ),
      ),
    );
  }

  Widget _buildHashResult(HashType type) {
    final colorScheme = Theme.of(context).colorScheme;
    final hashColor = _getHashColor(type, colorScheme);
    final result = _resultControllers[type]!.text;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: result.isNotEmpty
              ? hashColor.withValues(alpha: 0.3)
              : colorScheme.outline.withValues(alpha: 0.1),
          width: result.isNotEmpty ? 2 : 1,
        ),
        boxShadow: result.isNotEmpty
            ? [
                BoxShadow(
                  color: hashColor.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: hashColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_getHashIcon(type), size: 16, color: hashColor),
              ),
              const SizedBox(width: 12),
              Text(
                _getHashName(type),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              if (result.isNotEmpty)
                IconButton(
                  onPressed: () => _copyHash(type),
                  icon: Icon(Icons.content_copy, size: 18, color: hashColor),
                  tooltip: 'Copier',
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              result.isNotEmpty
                  ? result
                  : 'Hash ${_getHashName(type)} apparaîtra ici...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                color: result.isNotEmpty
                    ? colorScheme.onSurface
                    : colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickExamples() {
    final colorScheme = Theme.of(context).colorScheme;

    final examples = [
      {'text': 'Hello World', 'label': 'Texte simple'},
      {'text': 'password123', 'label': 'Mot de passe'},
      {'text': 'Lorem ipsum dolor', 'label': 'Texte long'},
      {'text': '{"key": "value"}', 'label': 'JSON'},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flash_on, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Exemples rapides',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: examples.map((example) {
              return InkWell(
                onTap: () {
                  _inputController.text = example['text']!;
                  _onInputChanged();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        example['label']!,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        example['text']!,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: colorScheme.onSurface.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
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
