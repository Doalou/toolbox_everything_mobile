import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_tokens.dart';
import 'package:toolbox_everything_mobile/core/services/json_formatter_service.dart';
import 'package:toolbox_everything_mobile/shared/widgets/expressive_action_button.dart';
import 'package:toolbox_everything_mobile/shared/widgets/expressive_card.dart';
import 'package:toolbox_everything_mobile/shared/widgets/status_badge.dart';

class JsonFormatterScreen extends StatefulWidget {
  final String heroTag;
  const JsonFormatterScreen({super.key, required this.heroTag});

  @override
  State<JsonFormatterScreen> createState() => _JsonFormatterScreenState();
}

class _JsonFormatterScreenState extends State<JsonFormatterScreen> {
  final TextEditingController _input = TextEditingController();
  final TextEditingController _output = TextEditingController();
  final JsonFormatterService _service = const JsonFormatterService();
  String? _error;
  int _indent = 2;

  @override
  void dispose() {
    _input.dispose();
    _output.dispose();
    super.dispose();
  }

  void _format() {
    setState(() {
      _error = null;
    });
    try {
      _output.text = _service.prettify(_input.text, indent: _indent);
    } on FormatException catch (e) {
      setState(() => _error = e.message);
    }
  }

  void _minify() {
    setState(() => _error = null);
    try {
      _output.text = _service.minify(_input.text);
    } on FormatException catch (e) {
      setState(() => _error = e.message);
    }
  }

  Future<void> _copy() async {
    if (_output.text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _output.text));
    Fluttertoast.showToast(msg: 'JSON copié');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Hero(
          tag: widget.heroTag,
          child: Material(
            type: MaterialType.transparency,
            child: Text(
              'Formateur JSON',
              style: Theme.of(context).appBarTheme.titleTextStyle,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(ExpressiveTokens.spacingLg),
        children: [
          Row(
            children: [
              StatusBadge.offline(),
              const SizedBox(width: 8),
              StatusBadge.local(),
            ],
          ),
          const SizedBox(height: ExpressiveTokens.spacingLg),
          ExpressiveCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Entrée', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextField(
                  controller: _input,
                  minLines: 6,
                  maxLines: 14,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  decoration: const InputDecoration(
                    hintText:
                        '{\n  "name": "Toolbox",\n  "version": "0.3.0"\n}',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Indentation : ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 2, label: Text('2')),
                        ButtonSegment(value: 4, label: Text('4')),
                      ],
                      selected: {_indent},
                      onSelectionChanged: (s) =>
                          setState(() => _indent = s.first),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    ExpressiveActionButton.iconLabel(
                      icon: Icons.format_align_left_rounded,
                      label: 'Formater',
                      onPressed: _format,
                    ),
                    ExpressiveActionButton.iconLabel(
                      icon: Icons.compress_rounded,
                      label: 'Minifier',
                      onPressed: _minify,
                      tonal: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: ExpressiveTokens.spacingLg),
          if (_error != null)
            ExpressiveCard(
              color: scheme.errorContainer,
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: scheme.onErrorContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: scheme.onErrorContainer),
                    ),
                  ),
                ],
              ),
            )
          else if (_output.text.isNotEmpty)
            ExpressiveCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Résultat',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _copy,
                        icon: const Icon(Icons.copy_rounded),
                        tooltip: 'Copier',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    _output.text,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      height: 1.4,
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
