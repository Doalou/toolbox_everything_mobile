import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:math';

class LoremGeneratorScreen extends StatefulWidget {
  const LoremGeneratorScreen({super.key});

  @override
  State<LoremGeneratorScreen> createState() => _LoremGeneratorScreenState();
}

class _LoremGeneratorScreenState extends State<LoremGeneratorScreen>
    with TickerProviderStateMixin {
  final TextEditingController _resultController = TextEditingController();

  late AnimationController _generateController;
  late Animation<double> _generateAnimation;

  int _paragraphCount = 3;
  int _sentenceCount = 5;
  LoremType _selectedType = LoremType.classic;
  GenerationType _generationType = GenerationType.paragraphs;

  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    _generateController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _generateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _generateController, curve: Curves.elasticOut),
    );

    _generateLorem();
  }

  @override
  void dispose() {
    _generateController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  void _generateLorem() {
    _generateController.forward().then((_) {
      _generateController.reverse();
    });

    String result = '';

    switch (_generationType) {
      case GenerationType.paragraphs:
        result = _generateParagraphs(_paragraphCount);
        break;
      case GenerationType.sentences:
        result = _generateSentences(_sentenceCount);
        break;
      case GenerationType.words:
        result = _generateWords(_sentenceCount * 10);
        break;
    }

    setState(() {
      _resultController.text = result;
    });
  }

  String _generateParagraphs(int count) {
    List<String> paragraphs = [];

    for (int i = 0; i < count; i++) {
      paragraphs.add(_generateSentences(5 + _random.nextInt(8)));
    }

    return paragraphs.join('\n\n');
  }

  String _generateSentences(int count) {
    List<String> sentences = [];
    final words = _getWordsForType(_selectedType);

    for (int i = 0; i < count; i++) {
      int sentenceLength = 8 + _random.nextInt(15);
      List<String> sentenceWords = [];

      for (int j = 0; j < sentenceLength; j++) {
        sentenceWords.add(words[_random.nextInt(words.length)]);
      }

      String sentence = sentenceWords.join(' ');
      sentence =
          '${sentence[0].toUpperCase()}${sentence.substring(1).toLowerCase()}.';
      sentences.add(sentence);
    }

    return sentences.join(' ');
  }

  String _generateWords(int count) {
    final words = _getWordsForType(_selectedType);
    List<String> result = [];

    for (int i = 0; i < count; i++) {
      result.add(words[_random.nextInt(words.length)]);
    }

    return result.join(' ');
  }

  List<String> _getWordsForType(LoremType type) {
    switch (type) {
      case LoremType.classic:
        return _classicLoremWords;
      case LoremType.hipster:
        return _hipsterWords;
      case LoremType.tech:
        return _techWords;
      case LoremType.french:
        return _frenchWords;
    }
  }

  void _copyResult() {
    if (_resultController.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _resultController.text));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.content_copy, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Texte copié dans le presse-papiers'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Générateur Lorem Ipsum'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          FadeInRight(
            delay: const Duration(milliseconds: 300),
            child: IconButton(
              onPressed: _copyResult,
              icon: Icon(Icons.content_copy, color: colorScheme.primary),
              tooltip: 'Copier le texte',
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            FadeInDown(
              delay: const Duration(milliseconds: 200),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.text_snippet,
                      size: 48,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Générateur de texte',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onPrimaryContainer,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lorem ipsum pour vos maquettes et prototypes',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer.withValues(
                          alpha: 0.7,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Options de génération
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: _buildGenerationOptions(),
            ),

            const SizedBox(height: 24),

            // Bouton de génération
            FadeInUp(
              delay: const Duration(milliseconds: 500),
              child: AnimatedBuilder(
                animation: _generateAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1 + (_generateAnimation.value * 0.1),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _generateLorem,
                        icon: Icon(Icons.auto_awesome, size: 20),
                        label: const Text(
                          'Générer le texte',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Résultat
            FadeInUp(
              delay: const Duration(milliseconds: 600),
              child: _buildResultArea(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerationOptions() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type de génération
          Text(
            'Type de génération',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          SegmentedButton<GenerationType>(
            segments: const [
              ButtonSegment(
                value: GenerationType.paragraphs,
                icon: Icon(Icons.subject, size: 16),
                label: Text('Paragraphes'),
              ),
              ButtonSegment(
                value: GenerationType.sentences,
                icon: Icon(Icons.format_align_left, size: 16),
                label: Text('Phrases'),
              ),
              ButtonSegment(
                value: GenerationType.words,
                icon: Icon(Icons.text_fields, size: 16),
                label: Text('Mots'),
              ),
            ],
            selected: {_generationType},
            onSelectionChanged: (newSelection) {
              setState(() {
                _generationType = newSelection.first;
              });
            },
          ),

          const SizedBox(height: 24),

          // Style de texte
          Text(
            'Style de texte',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: LoremType.values.map((type) {
              final isSelected = _selectedType == type;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedType = type;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getIconForType(type),
                        size: 16,
                        color: isSelected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getNameForType(type),
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Quantité
          Text(
            _generationType == GenerationType.paragraphs
                ? 'Nombre de paragraphes: $_paragraphCount'
                : _generationType == GenerationType.sentences
                ? 'Nombre de phrases: $_sentenceCount'
                : 'Nombre de mots: ${_sentenceCount * 10}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Slider(
            value: _generationType == GenerationType.paragraphs
                ? _paragraphCount.toDouble()
                : _sentenceCount.toDouble(),
            min: 1,
            max: _generationType == GenerationType.paragraphs ? 10 : 20,
            divisions: _generationType == GenerationType.paragraphs ? 9 : 19,
            onChanged: (value) {
              setState(() {
                if (_generationType == GenerationType.paragraphs) {
                  _paragraphCount = value.round();
                } else {
                  _sentenceCount = value.round();
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResultArea() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.text_snippet, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Texte généré',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _copyResult,
                  icon: Icon(
                    Icons.content_copy,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  tooltip: 'Copier',
                ),
              ],
            ),
          ),
          Expanded(
            child: TextField(
              controller: _resultController,
              maxLines: null,
              readOnly: true,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.6),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(LoremType type) {
    switch (type) {
      case LoremType.classic:
        return Icons.history_edu;
      case LoremType.hipster:
        return Icons.coffee;
      case LoremType.tech:
        return Icons.computer;
      case LoremType.french:
        return Icons.language;
    }
  }

  String _getNameForType(LoremType type) {
    switch (type) {
      case LoremType.classic:
        return 'Classique';
      case LoremType.hipster:
        return 'Hipster';
      case LoremType.tech:
        return 'Tech';
      case LoremType.french:
        return 'Français';
    }
  }
}

enum LoremType { classic, hipster, tech, french }

enum GenerationType { paragraphs, sentences, words }

// Dictionnaires de mots
const List<String> _classicLoremWords = [
  'lorem',
  'ipsum',
  'dolor',
  'sit',
  'amet',
  'consectetur',
  'adipiscing',
  'elit',
  'sed',
  'do',
  'eiusmod',
  'tempor',
  'incididunt',
  'ut',
  'labore',
  'et',
  'dolore',
  'magna',
  'aliqua',
  'enim',
  'ad',
  'minim',
  'veniam',
  'quis',
  'nostrud',
  'exercitation',
  'ullamco',
  'laboris',
  'nisi',
  'aliquip',
  'ex',
  'ea',
  'commodo',
  'consequat',
  'duis',
  'aute',
  'irure',
  'in',
  'reprehenderit',
  'voluptate',
  'velit',
  'esse',
  'cillum',
  'fugiat',
  'nulla',
  'pariatur',
  'excepteur',
  'sint',
  'occaecat',
  'cupidatat',
  'non',
  'proident',
  'sunt',
  'culpa',
  'qui',
  'officia',
  'deserunt',
  'mollit',
  'anim',
  'id',
  'est',
  'laborum',
];

const List<String> _hipsterWords = [
  'artisan',
  'craft',
  'organic',
  'sustainable',
  'vintage',
  'brooklyn',
  'fixie',
  'beard',
  'mustache',
  'flannel',
  'vinyl',
  'kale',
  'quinoa',
  'kombucha',
  'meditation',
  'yoga',
  'mindfulness',
  'aesthetic',
  'minimalist',
  'indie',
  'authentic',
  'local',
  'farm-to-table',
  'gluten-free',
  'vegan',
  'raw',
  'cold-pressed',
  'small-batch',
  'handcrafted',
  'ethically-sourced',
  'fair-trade',
];

const List<String> _techWords = [
  'algorithm',
  'api',
  'backend',
  'frontend',
  'database',
  'framework',
  'library',
  'component',
  'interface',
  'protocol',
  'server',
  'client',
  'cloud',
  'container',
  'microservice',
  'deployment',
  'repository',
  'commit',
  'branch',
  'merge',
  'authentication',
  'authorization',
  'security',
  'encryption',
  'optimization',
  'performance',
  'scalability',
  'responsive',
  'mobile',
  'web',
  'native',
  'cross-platform',
  'agile',
  'devops',
  'continuous',
  'integration',
  'testing',
];

const List<String> _frenchWords = [
  'bonjour',
  'monde',
  'français',
  'language',
  'texte',
  'exemple',
  'contenu',
  'paragraphe',
  'phrase',
  'mot',
  'création',
  'génération',
  'automatique',
  'maquette',
  'prototype',
  'design',
  'interface',
  'utilisateur',
  'expérience',
  'moderne',
  'élégant',
  'simple',
  'efficace',
  'pratique',
  'utile',
  'rapide',
  'fluide',
  'intuitif',
  'accessible',
  'responsive',
  'adaptatif',
  'optimisé',
];
