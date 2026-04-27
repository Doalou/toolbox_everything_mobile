import 'package:flutter/material.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_tokens.dart';
import 'package:toolbox_everything_mobile/core/services/regex_service.dart';
import 'package:toolbox_everything_mobile/shared/widgets/expressive_card.dart';
import 'package:toolbox_everything_mobile/shared/widgets/status_badge.dart';

class RegexTesterScreen extends StatefulWidget {
  final String heroTag;
  const RegexTesterScreen({super.key, required this.heroTag});

  @override
  State<RegexTesterScreen> createState() => _RegexTesterScreenState();
}

class _RegexTesterScreenState extends State<RegexTesterScreen> {
  final TextEditingController _patternController = TextEditingController();
  final TextEditingController _inputController = TextEditingController();
  final RegexService _service = const RegexService();

  bool _multiline = false;
  bool _caseSensitive = true;
  bool _dotAll = false;

  List<RegexMatchInfo> _matches = const [];
  String? _error;

  @override
  void dispose() {
    _patternController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  void _evaluate() {
    setState(() {
      _error = null;
      _matches = const [];
    });
    if (_patternController.text.isEmpty) return;
    try {
      _matches = _service.findAll(
        _patternController.text,
        _inputController.text,
        multiLine: _multiline,
        caseSensitive: _caseSensitive,
        dotAll: _dotAll,
      );
    } on FormatException catch (e) {
      _error = e.message;
    }
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
              'Regex tester',
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
                Text('Pattern', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextField(
                  controller: _patternController,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  onChanged: (_) => _evaluate(),
                  decoration: const InputDecoration(
                    hintText: r'\b\w+@\w+\.\w+\b',
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Multi-ligne'),
                      selected: _multiline,
                      onSelected: (v) {
                        setState(() => _multiline = v);
                        _evaluate();
                      },
                    ),
                    FilterChip(
                      label: const Text('Sensible casse'),
                      selected: _caseSensitive,
                      onSelected: (v) {
                        setState(() => _caseSensitive = v);
                        _evaluate();
                      },
                    ),
                    FilterChip(
                      label: const Text('Dot-all'),
                      selected: _dotAll,
                      onSelected: (v) {
                        setState(() => _dotAll = v);
                        _evaluate();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: ExpressiveTokens.spacingLg),
          ExpressiveCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Texte de test',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _inputController,
                  minLines: 4,
                  maxLines: 10,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  onChanged: (_) => _evaluate(),
                  decoration: const InputDecoration(
                    hintText: 'Coller le texte à tester ici…',
                  ),
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
          else
            ExpressiveCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${_matches.length} correspondance(s)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      StatusBadge(
                        label: '${_matches.length}',
                        tone: _matches.isEmpty
                            ? BadgeTone.neutral
                            : BadgeTone.success,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_matches.isEmpty)
                    Text(
                      'Aucune correspondance.',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    )
                  else
                    ..._matches
                        .take(50)
                        .map(
                          (m) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: scheme.tertiaryContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${m.start}-${m.end}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: scheme.onTertiaryContainer,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: SelectableText(
                                    m.text,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  if (_matches.length > 50)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '… (${_matches.length - 50} non affichés)',
                        style: TextStyle(color: scheme.onSurfaceVariant),
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
