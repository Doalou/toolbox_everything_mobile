import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:toolbox_everything_mobile/core/constants/app_constants.dart';
import 'dart:convert';

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
      String result;
      if (_isEncoding) {
        result = _encode(input);
      } else {
        result = _decode(input);
      }
      _outputController.text = result;
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
        return _htmlEncode(input);
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
        return _htmlDecode(input);
      case EncodingType.hex:
        return _hexDecode(input);
    }
  }

  String _htmlEncode(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;')
        .replaceAll(' ', '&nbsp;');
  }

  String _htmlDecode(String input) {
    return input
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');
  }

  String _hexDecode(String input) {
    final cleanHex = input.replaceAll(' ', '').replaceAll('\n', '');
    final bytes = <int>[];
    for (int i = 0; i < cleanHex.length; i += 2) {
      if (i + 2 <= cleanHex.length) {
        bytes.add(int.parse(cleanHex.substring(i, i + 2), radix: 16));
      }
    }
    return String.fromCharCodes(bytes);
  }

  void _copyOutput() {
    if (_outputController.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _outputController.text));
      Fluttertoast.showToast(msg: AppConstants.copySuccessMessage);
    }
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
    final colorScheme = Theme.of(context).colorScheme;

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
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.code, color: colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Encodez et décodez du texte',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Base64, URL, HTML entities, Hexadécimal.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onPrimaryContainer
                                        .withValues(alpha: 0.8),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Type selector
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: EncodingType.values.map((type) {
                final selected = type == _selectedType;
                return ChoiceChip(
                  label: Text(_getTypeLabel(type)),
                  selected: selected,
                  onSelected: (v) {
                    setState(() => _selectedType = type);
                    _process();
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Encode/Decode toggle
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                    value: true,
                    label: Text('Encoder'),
                    icon: Icon(Icons.lock)),
                ButtonSegment(
                    value: false,
                    label: Text('Décoder'),
                    icon: Icon(Icons.lock_open)),
              ],
              selected: {_isEncoding},
              onSelectionChanged: (v) {
                setState(() => _isEncoding = v.first);
                _process();
              },
            ),

            const SizedBox(height: 16),

            // Input field
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.input, size: 18, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          _isEncoding ? 'Texte à encoder' : 'Texte à décoder',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: _clearAll,
                          icon: const Icon(Icons.clear, size: 18),
                          tooltip: 'Effacer',
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _inputController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Entrez votre texte ici...',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _process(),
                    ),
                  ],
                ),
              ),
            ),

            // Swap button
            Center(
              child: IconButton.filled(
                onPressed: _swapFields,
                icon: const Icon(Icons.swap_vert),
                tooltip: 'Inverser',
              ),
            ),

            // Output field
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.output,
                            size: 18, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Résultat ($_typeLabel)',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: _copyOutput,
                          icon: const Icon(Icons.copy, size: 18),
                          tooltip: 'Copier',
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _outputController,
                      maxLines: 4,
                      readOnly: true,
                      decoration: InputDecoration(
                        hintText: 'Le résultat apparaîtra ici...',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerLow,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Quick tips
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline,
                            size: 18, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'À propos',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getDescription(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
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
