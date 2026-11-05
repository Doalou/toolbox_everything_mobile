import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toolbox_everything_mobile/core/services/app_feedback.dart';
import 'package:toolbox_everything_mobile/shared/widgets/editorial_tool_components.dart';
import 'package:toolbox_everything_mobile/shared/widgets/editorial_tool_scaffold.dart';
import 'package:toolbox_everything_mobile/shared/widgets/expressive_action_button.dart';
import 'package:toolbox_everything_mobile/shared/widgets/expressive_card.dart';

class LoremGeneratorScreen extends StatefulWidget {
  final String heroTag;

  const LoremGeneratorScreen({super.key, required this.heroTag});

  @override
  State<LoremGeneratorScreen> createState() => _LoremGeneratorScreenState();
}

class _LoremGeneratorScreenState extends State<LoremGeneratorScreen> {
  final TextEditingController _resultController = TextEditingController();

  int _paragraphCount = 3;
  int _sentenceCount = 5;
  LoremType _selectedType = LoremType.classic;
  GenerationType _generationType = GenerationType.paragraphs;

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _generateLorem();
  }

  @override
  void dispose() {
    _resultController.dispose();
    super.dispose();
  }

  void _generateLorem() {
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
    final List<String> paragraphs = [];
    for (int i = 0; i < count; i++) {
      paragraphs.add(_generateSentences(5 + _random.nextInt(8)));
    }
    return paragraphs.join('\n\n');
  }

  String _generateSentences(int count) {
    final List<String> sentences = [];
    final words = _getWordsForType(_selectedType);

    for (int i = 0; i < count; i++) {
      final int sentenceLength = 8 + _random.nextInt(15);
      final List<String> sentenceWords = [];

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
    final List<String> result = [];

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
      AppFeedback.copied(context, 'Texte copié dans le presse-papiers');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return EditorialToolScaffold(
      title: 'Générateur Lorem Ipsum',
      heroTag: widget.heroTag,
      actions: [
        IconButton(
          onPressed: _copyResult,
          icon: Icon(Icons.content_copy_rounded, color: colorScheme.primary),
          tooltip: 'Copier le texte',
        ),
      ],
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const EditorialToolIntro(
              icon: Icons.text_snippet_rounded,
              title: 'Générer du texte',
              description: 'Lorem ipsum pour vos maquettes et prototypes.',
            ),
            const SizedBox(height: 16),
            _buildGenerationOptions(),
            const SizedBox(height: 16),
            ExpressiveActionButton.iconLabel(
              onPressed: _generateLorem,
              icon: Icons.auto_awesome_rounded,
              label: 'Générer le texte',
            ),
            const SizedBox(height: 16),
            _buildResultArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerationOptions() {
    return ExpressiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Type de génération',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<GenerationType>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: GenerationType.paragraphs,
                  icon: Icon(Icons.subject_rounded, size: 16),
                  label: Text('Paragraphes'),
                ),
                ButtonSegment(
                  value: GenerationType.sentences,
                  icon: Icon(Icons.format_align_left_rounded, size: 16),
                  label: Text('Phrases'),
                ),
                ButtonSegment(
                  value: GenerationType.words,
                  icon: Icon(Icons.text_fields_rounded, size: 16),
                  label: Text('Mots'),
                ),
              ],
              selected: {_generationType},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _generationType = newSelection.first;
                });
                _generateLorem();
              },
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Style de texte',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: LoremType.values.map((type) {
              final isSelected = _selectedType == type;
              return ChoiceChip(
                selected: isSelected,
                avatar: Icon(_getIconForType(type), size: 16),
                label: Text(_getNameForType(type)),
                onSelected: (_) {
                  setState(() => _selectedType = type);
                  _generateLorem();
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Text(
            _generationType == GenerationType.paragraphs
                ? 'Nombre de paragraphes : $_paragraphCount'
                : _generationType == GenerationType.sentences
                ? 'Nombre de phrases : $_sentenceCount'
                : 'Nombre de mots : ${_sentenceCount * 10}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
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
              _generateLorem();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResultArea() {
    final colorScheme = Theme.of(context).colorScheme;

    return ExpressiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.text_snippet_rounded,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Texte généré',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              IconButton(
                onPressed: _copyResult,
                icon: Icon(
                  Icons.content_copy_rounded,
                  size: 18,
                  color: colorScheme.primary,
                ),
                tooltip: 'Copier',
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _resultController,
            minLines: 8,
            maxLines: 14,
            readOnly: true,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(LoremType type) {
    switch (type) {
      case LoremType.classic:
        return Icons.history_edu_rounded;
      case LoremType.hipster:
        return Icons.coffee_rounded;
      case LoremType.tech:
        return Icons.computer_rounded;
      case LoremType.french:
        return Icons.language_rounded;
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
  'langage',
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
