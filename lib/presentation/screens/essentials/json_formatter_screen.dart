import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_tokens.dart';
import 'package:toolbox_everything_mobile/core/services/app_feedback.dart';
import 'package:toolbox_everything_mobile/core/services/json_formatter_service.dart';
import 'package:toolbox_everything_mobile/shared/widgets/editorial_tool_components.dart';
import 'package:toolbox_everything_mobile/shared/widgets/editorial_tool_scaffold.dart';
import 'package:toolbox_everything_mobile/shared/widgets/expressive_action_button.dart';
import 'package:toolbox_everything_mobile/shared/widgets/expressive_card.dart';

class JsonFormatterScreen extends StatefulWidget {
  final String heroTag;
  final String? initialText;
  const JsonFormatterScreen({
    super.key,
    required this.heroTag,
    this.initialText,
  });

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
  void initState() {
    super.initState();
    if (widget.initialText != null && widget.initialText!.isNotEmpty) {
      _input.text = widget.initialText!;
      _applyFormat(notify: false);
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _output.dispose();
    super.dispose();
  }

  void _applyFormat({bool notify = true}) {
    String? nextError;
    String nextOutput = '';
    try {
      nextOutput = _service.prettify(_input.text, indent: _indent);
    } on FormatException catch (e) {
      nextError = e.message;
    }
    if (notify) {
      setState(() {
        _error = nextError;
        _output.text = nextOutput;
      });
    } else {
      _error = nextError;
      _output.text = nextOutput;
    }
  }

  void _minify() {
    String? nextError;
    String nextOutput = '';
    try {
      nextOutput = _service.minify(_input.text);
    } on FormatException catch (e) {
      nextError = e.message;
    }
    setState(() {
      _error = nextError;
      _output.text = nextOutput;
    });
  }

  Future<void> _copy() async {
    if (_output.text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _output.text));
    if (!mounted) return;
    AppFeedback.copied(context, 'JSON copié');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return EditorialToolScaffold(
      title: 'Formateur JSON',
      heroTag: widget.heroTag,
      body: ListView(
        padding: const EdgeInsets.all(ExpressiveTokens.spacingLg),
        children: [
          const EditorialToolIntro(
            icon: Icons.data_object_rounded,
            title: 'Valider et indenter',
            description: 'Formatez, minifiez et vérifiez vos structures JSON.',
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
                        '{\n  "name": "Toolbox",\n  "version": "0.6.0"\n}',
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
                      showSelectedIcon: false,
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
                      onPressed: () => _applyFormat(),
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
