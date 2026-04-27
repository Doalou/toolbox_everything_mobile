import 'package:flutter/material.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_tokens.dart';
import 'package:toolbox_everything_mobile/core/services/diff_service.dart';
import 'package:toolbox_everything_mobile/shared/widgets/expressive_card.dart';
import 'package:toolbox_everything_mobile/shared/widgets/status_badge.dart';

class TextDiffScreen extends StatefulWidget {
  final String heroTag;
  const TextDiffScreen({super.key, required this.heroTag});

  @override
  State<TextDiffScreen> createState() => _TextDiffScreenState();
}

class _TextDiffScreenState extends State<TextDiffScreen> {
  final TextEditingController _left = TextEditingController();
  final TextEditingController _right = TextEditingController();
  final DiffService _service = const DiffService();
  List<DiffLine> _diff = const [];

  @override
  void dispose() {
    _left.dispose();
    _right.dispose();
    super.dispose();
  }

  void _compute() {
    setState(() {
      _diff = _service.diff(_left.text, _right.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final summary = _service.summary(_diff);
    return Scaffold(
      appBar: AppBar(
        title: Hero(
          tag: widget.heroTag,
          child: Material(
            type: MaterialType.transparency,
            child: Text(
              'Diff texte',
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
                Text('Avant', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextField(
                  controller: _left,
                  minLines: 4,
                  maxLines: 10,
                  onChanged: (_) => _compute(),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: ExpressiveTokens.spacing),
          ExpressiveCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Après', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextField(
                  controller: _right,
                  minLines: 4,
                  maxLines: 10,
                  onChanged: (_) => _compute(),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: ExpressiveTokens.spacingLg),
          if (_diff.isNotEmpty)
            ExpressiveCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Différences',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      StatusBadge(
                        label: '+${summary.added}',
                        tone: BadgeTone.success,
                      ),
                      const SizedBox(width: 6),
                      StatusBadge(
                        label: '-${summary.removed}',
                        tone: BadgeTone.danger,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._diff.map((line) {
                    Color? bg;
                    Color? fg;
                    String prefix = '  ';
                    switch (line.op) {
                      case DiffOp.add:
                        bg = scheme.tertiaryContainer;
                        fg = scheme.onTertiaryContainer;
                        prefix = '+ ';
                        break;
                      case DiffOp.remove:
                        bg = scheme.errorContainer;
                        fg = scheme.onErrorContainer;
                        prefix = '- ';
                        break;
                      case DiffOp.keep:
                        break;
                    }
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      color: bg,
                      child: Text(
                        '$prefix${line.text}',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          color: fg ?? scheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
