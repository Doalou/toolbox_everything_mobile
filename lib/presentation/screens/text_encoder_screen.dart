import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:toolbox_everything_mobile/core/constants/app_constants.dart';
import 'package:toolbox_everything_mobile/shared/widgets/expressive_card.dart';

enum EncodingType { base64, url, html, hex }

class TextEncoderScreen extends StatefulWidget {
  final String heroTag;

  const TextEncoderScreen({super.key, required this.heroTag});

  @override
  State<TextEncoderScreen> createState() => _TextEncoderScreenState();
}

class _TextEncoderScreenState extends State<TextEncoderScreen> {
  final _inputController = TextEditingController();
  final _outputController = TextEditingController();
  EncodingType _selectedType = EncodingType.base64;
  bool _isEncoding = true;

  @override
  void dispose() {
    _inputController.dispose();
    _outputController.dispose();
    super.dispose();
  }

  void _process() {
    final input = _inputController.text;
    if (input.isEmpty) {
      _outputController.clear();
      return;
    }

    try {
      _outputController.text = _isEncoding ? _encode(input) : _decode(input);
    } catch (e) {
      _outputController.text = 'Erreur: ${e.toString()}';
    }
  }

  String _encode(String input) {
    switch (_selectedType) {
      case EncodingType.base64:
        return base64Encode(utf8.encode(input));
      case EncodingType.url:
        return Uri.encodeComponent(input);
      case EncodingType.html:
        return input
            .replaceAll('&', '&amp;')
            .replaceAll('<', '&lt;')
            .replaceAll('>', '&gt;')
            .replaceAll('"', '&quot;')
            .replaceAll("'", '&#39;')
            .replaceAll(' ', '&nbsp;');
      case EncodingType.hex:
        return input.codeUnits
            .map((c) => c.toRadixString(16).padLeft(2, '0'))
            .join();
    }
  }

  String _decode(String input) {
    switch (_selectedType) {
      case EncodingType.base64:
        return utf8.decode(base64Decode(input));
      case EncodingType.url:
        return Uri.decodeComponent(input);
      case EncodingType.html:
        return input
            .replaceAll('&amp;', '&')
            .replaceAll('&lt;', '<')
            .replaceAll('&gt;', '>')
            .replaceAll('&quot;', '"')
            .replaceAll('&#39;', "'")
            .replaceAll('&nbsp;', ' ');
      case EncodingType.hex:
        final cleanHex = input.replaceAll(' ', '').replaceAll('\n', '');
        final bytes = <int>[];
        for (var i = 0; i < cleanHex.length; i += 2) {
          if (i + 2 <= cleanHex.length) {
            bytes.add(int.parse(cleanHex.substring(i, i + 2), radix: 16));
          }
        }
        return String.fromCharCodes(bytes);
    }
  }

  void _copyOutput() {
    if (_outputController.text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _outputController.text));
    Fluttertoast.showToast(msg: AppConstants.copySuccessMessage);
  }

  void _swapFields() {
    final temp = _inputController.text;
    _inputController.text = _outputController.text;
    _outputController.text = temp;
    setState(() => _isEncoding = !_isEncoding);
    _process();
  }

  void _clearAll() {
    _inputController.clear();
    _outputController.clear();
    setState(() {});
  }

  String get _typeLabel {
    switch (_selectedType) {
      case EncodingType.base64:
        return 'Base64';
      case EncodingType.url:
        return 'URL';
      case EncodingType.html:
        return 'HTML';
      case EncodingType.hex:
        return 'Hexadécimal';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Hero(
          tag: widget.heroTag,
          child: Material(
            type: MaterialType.transparency,
            child: Text(
              'Encodeur / Décodeur',
              style: Theme.of(context).appBarTheme.titleTextStyle,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _IntroCard(scheme: scheme),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: EncodingType.values.map((type) {
                final selected = type == _selectedType;
                return ChoiceChip(
                  label: Text(_getTypeLabel(type)),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _selectedType = type);
                    _process();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('Encoder'),
                  icon: Icon(Icons.lock),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Décoder'),
                  icon: Icon(Icons.lock_open),
                ),
              ],
              selected: {_isEncoding},
              onSelectionChanged: (selection) {
                setState(() => _isEncoding = selection.first);
                _process();
              },
            ),
            const SizedBox(height: 16),
            ExpressiveCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CardHeader(
                    icon: Icons.input_rounded,
                    title: _isEncoding ? 'Texte à encoder' : 'Texte à décoder',
                    action: IconButton(
                      onPressed: _clearAll,
                      icon: const Icon(Icons.clear, size: 18),
                      tooltip: 'Effacer',
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _inputController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Entrez votre texte ici...',
                    ),
                    onChanged: (_) => _process(),
                  ),
                ],
              ),
            ),
            Center(
              child: IconButton.filled(
                onPressed: _swapFields,
                icon: const Icon(Icons.swap_vert),
                tooltip: 'Inverser',
              ),
            ),
            ExpressiveCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CardHeader(
                    icon: Icons.output_rounded,
                    title: 'Résultat ($_typeLabel)',
                    action: IconButton(
                      onPressed: _copyOutput,
                      icon: const Icon(Icons.copy, size: 18),
                      tooltip: 'Copier',
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _outputController,
                    maxLines: 4,
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: 'Le résultat apparaîtra ici...',
                      filled: true,
                      fillColor: scheme.surfaceContainerLow,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ExpressiveCard(
              dense: true,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _CardHeader(
                    icon: Icons.lightbulb_outline,
                    title: 'À propos',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getDescription(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel(EncodingType type) {
    switch (type) {
      case EncodingType.base64:
        return 'Base64';
      case EncodingType.url:
        return 'URL';
      case EncodingType.html:
        return 'HTML';
      case EncodingType.hex:
        return 'Hex';
    }
  }

  String _getDescription() {
    switch (_selectedType) {
      case EncodingType.base64:
        return 'Base64 encode du texte en caractères ASCII sûrs pour le transfert. Utilisé dans les emails, données JSON, etc.';
      case EncodingType.url:
        return 'URL encoding remplace les caractères spéciaux par des séquences %XX. Essentiel pour les paramètres d\'URL.';
      case EncodingType.html:
        return 'HTML entities convertit les caractères spéciaux (<, >, &, etc.) pour affichage sûr dans les pages web.';
      case EncodingType.hex:
        return 'Hexadécimal représente chaque caractère par sa valeur en base 16. Utilisé en programmation et debug.';
    }
  }
}

class _IntroCard extends StatelessWidget {
  final ColorScheme scheme;

  const _IntroCard({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.code, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Encodez et décodez du texte',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Base64, URL, HTML entities, Hexadécimal.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onPrimaryContainer.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? action;

  const _CardHeader({required this.icon, required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: ShapeDecoration(
            color: scheme.primary.withValues(alpha: 0.14),
            shape: const StadiumBorder(),
          ),
          child: Icon(icon, size: 18, color: scheme.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        ?action,
      ],
    );
  }
}
