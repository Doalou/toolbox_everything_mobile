import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toolbox_everything_mobile/core/constants/app_constants.dart';
import 'package:toolbox_everything_mobile/core/services/app_feedback.dart';
import 'package:toolbox_everything_mobile/core/services/haptics_service.dart';
import 'package:toolbox_everything_mobile/shared/widgets/editorial_tool_components.dart';
import 'package:toolbox_everything_mobile/shared/widgets/editorial_tool_scaffold.dart';
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
      _outputController.text = 'Erreur : ${e.toString()}';
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
        return utf8
            .encode(input)
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join();
    }
  }

  String _decode(String input) {
    switch (_selectedType) {
      case EncodingType.base64:
        return utf8.decode(base64Decode(input.trim()));
      case EncodingType.url:
        return Uri.decodeComponent(input);
      case EncodingType.html:
        return input
            .replaceAll('&nbsp;', ' ')
            .replaceAll('&#39;', "'")
            .replaceAll('&quot;', '"')
            .replaceAll('&gt;', '>')
            .replaceAll('&lt;', '<')
            .replaceAll('&amp;', '&');
      case EncodingType.hex:
        final cleanHex = input
            .replaceAll(' ', '')
            .replaceAll('\n', '')
            .replaceAll('0x', '');
        if (cleanHex.length.isOdd) {
          throw const FormatException('Longueur hexadécimale impaire');
        }
        final bytes = <int>[];
        for (var i = 0; i < cleanHex.length; i += 2) {
          bytes.add(int.parse(cleanHex.substring(i, i + 2), radix: 16));
        }
        return utf8.decode(bytes, allowMalformed: true);
    }
  }

  void _copyOutput() {
    if (_outputController.text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _outputController.text));
    AppFeedback.copied(context, AppConstants.copySuccessMessage);
  }

  void _swapFields() {
    HapticsService.perform(context, HapticType.selection);
    final temp = _inputController.text;
    _inputController.text = _outputController.text;
    _outputController.text = temp;
    setState(() => _isEncoding = !_isEncoding);
    _process();
  }

  void _clearAll() {
    HapticsService.perform(context, HapticType.light);
    _inputController.clear();
    _outputController.clear();
    setState(() {});
  }

  String get _typeLabel => switch (_selectedType) {
    EncodingType.base64 => 'Base64',
    EncodingType.url => 'URL',
    EncodingType.html => 'HTML',
    EncodingType.hex => 'Hexadécimal',
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return EditorialToolScaffold(
      title: 'Encodeur / Décodeur',
      heroTag: widget.heroTag,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _IntroCard(),
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
                    HapticsService.perform(context, HapticType.selection);
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
                  icon: Icon(Icons.lock_rounded),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Décoder'),
                  icon: Icon(Icons.lock_open_rounded),
                ),
              ],
              selected: {_isEncoding},
              onSelectionChanged: (selection) {
                HapticsService.perform(context, HapticType.selection);
                setState(() => _isEncoding = selection.first);
                _process();
              },
            ),
            const SizedBox(height: 16),
            ExpressiveCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CardHeader(
                    icon: Icons.input_rounded,
                    title: _isEncoding ? 'Texte à encoder' : 'Texte à décoder',
                    action: IconButton(
                      onPressed: _clearAll,
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      tooltip: 'Effacer',
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _inputController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Entrez votre texte ici…',
                    ),
                    onChanged: (_) => _process(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: IconButton.filledTonal(
                  onPressed: _swapFields,
                  icon: const Icon(Icons.swap_vert_rounded),
                  tooltip: 'Inverser',
                ),
              ),
            ),
            ExpressiveCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CardHeader(
                    icon: Icons.output_rounded,
                    title: 'Résultat ($_typeLabel)',
                    action: IconButton(
                      onPressed: _copyOutput,
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      tooltip: 'Copier',
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _outputController,
                    maxLines: 4,
                    readOnly: true,
                    style: const TextStyle(fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      hintText: 'Le résultat apparaîtra ici…',
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
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _CardHeader(
                    icon: Icons.lightbulb_outline_rounded,
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

  String _getTypeLabel(EncodingType type) => switch (type) {
    EncodingType.base64 => 'Base64',
    EncodingType.url => 'URL',
    EncodingType.html => 'HTML',
    EncodingType.hex => 'Hex (UTF-8)',
  };

  String _getDescription() => switch (_selectedType) {
    EncodingType.base64 =>
      'Base64 encode les octets UTF-8 en caractères ASCII sûrs pour le transfert.',
    EncodingType.url =>
      'URL encoding remplace les caractères réservés par des séquences %XX.',
    EncodingType.html =>
      'Les entités HTML échappent les balises (<, >, &, ") pour un rendu sûr.',
    EncodingType.hex =>
      'Hexadécimal convertit chaque octet UTF-8 en sa représentation base 16.',
  };
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return const EditorialToolIntro(
      icon: Icons.code_rounded,
      title: 'Encoder ou décoder du texte',
      description: 'Base64, URL, entités HTML et hexadécimal UTF-8.',
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
            color: scheme.primaryContainer,
            shape: const StadiumBorder(),
          ),
          child: Icon(icon, size: 18, color: scheme.onPrimaryContainer),
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
