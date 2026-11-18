import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_shapes.dart';
import 'package:toolbox_everything_mobile/core/models/note_item.dart';
import 'package:url_launcher/url_launcher.dart';

class SimpleMarkdownView extends StatefulWidget {
  final String content;
  final void Function(int lineIndex)? onToggleChecklistLine;

  const SimpleMarkdownView({
    super.key,
    required this.content,
    this.onToggleChecklistLine,
  });

  @override
  State<SimpleMarkdownView> createState() => _SimpleMarkdownViewState();
}

class _SimpleMarkdownViewState extends State<SimpleMarkdownView> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  Future<void> _openUrl(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null || !uri.hasScheme) return;
    if (uri.scheme != 'http' &&
        uri.scheme != 'https' &&
        uri.scheme != 'mailto') {
      return;
    }
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (widget.content.trim().isEmpty) {
      return Text(
        'Aucun contenu à prévisualiser.',
        style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      );
    }

    final lines = widget.content.split('\n');
    final widgets = <Widget>[];
    var i = 0;

    while (i < lines.length) {
      final line = lines[i];
      final trimmed = line.trim();

      // Bloc de code ```
      if (trimmed.startsWith('```')) {
        final buffer = StringBuffer();
        i++;
        while (i < lines.length && !lines[i].trim().startsWith('```')) {
          if (buffer.isNotEmpty) buffer.writeln();
          buffer.write(lines[i]);
          i++;
        }
        widgets.add(
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(ExpressiveShapes.medium),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: SelectableText(
              buffer.toString(),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
        );
        i++;
        continue;
      }

      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 8));
        i++;
        continue;
      }

      // Ligne horizontale ---
      if (RegExp(r'^(-{3,}|\*{3,}|_{3,})$').hasMatch(trimmed)) {
        widgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(),
          ),
        );
        i++;
        continue;
      }

      // Titres # / ## / ###
      if (trimmed.startsWith('### ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Text(
              trimmed.substring(4),
              style: textTheme.titleMedium?.copyWith(
                fontFamily: 'Fraunces',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
        i++;
        continue;
      }
      if (trimmed.startsWith('## ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Text(
              trimmed.substring(3),
              style: textTheme.titleLarge?.copyWith(
                fontFamily: 'Fraunces',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
        i++;
        continue;
      }
      if (trimmed.startsWith('# ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 6),
            child: Text(
              trimmed.substring(2),
              style: textTheme.headlineSmall?.copyWith(
                fontFamily: 'Fraunces',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
        i++;
        continue;
      }

      // Citation >
      if (trimmed.startsWith('> ')) {
        widgets.add(
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: scheme.primary, width: 3)),
              color: scheme.surfaceContainerLow,
            ),
            child: Text.rich(
              _buildInlineSpan(
                trimmed.substring(2),
                baseStyle: (textTheme.bodyMedium ?? const TextStyle()).copyWith(
                  fontStyle: FontStyle.italic,
                  color: scheme.onSurfaceVariant,
                  height: 1.5,
                ),
                scheme: scheme,
              ),
            ),
          ),
        );
        i++;
        continue;
      }

      // Case à cocher - [ ] / - [x]
      final checkMatch = NoteItem.checklistPattern.firstMatch(line);
      if (checkMatch != null) {
        final lineIndex = i;
        final isChecked = (checkMatch.group(1) ?? '').toLowerCase() == 'x';
        final label = checkMatch.group(2) ?? '';
        final baseStyle = (textTheme.bodyLarge ?? const TextStyle()).copyWith(
          height: 1.45,
          decoration: isChecked ? TextDecoration.lineThrough : null,
          color: isChecked ? scheme.onSurfaceVariant : scheme.onSurface,
        );
        widgets.add(
          InkWell(
            borderRadius: BorderRadius.circular(ExpressiveShapes.small),
            onTap: widget.onToggleChecklistLine == null
                ? null
                : () => widget.onToggleChecklistLine!(lineIndex),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: isChecked,
                    visualDensity: VisualDensity.compact,
                    onChanged: widget.onToggleChecklistLine == null
                        ? null
                        : (_) => widget.onToggleChecklistLine!(lineIndex),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text.rich(
                      _buildInlineSpan(
                        label,
                        baseStyle: baseStyle,
                        scheme: scheme,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        i++;
        continue;
      }

      // Puce - ou *
      final bulletMatch = RegExp(r'^\s*[-*]\s+(.*)$').firstMatch(line);
      if (bulletMatch != null) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    height: 1.45,
                  ),
                ),
                Expanded(
                  child: Text.rich(
                    _buildInlineSpan(
                      bulletMatch.group(1) ?? '',
                      baseStyle: (textTheme.bodyLarge ?? const TextStyle())
                          .copyWith(height: 1.5),
                      scheme: scheme,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        i++;
        continue;
      }

      // Paragraphe normal
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text.rich(
            _buildInlineSpan(
              line,
              baseStyle: (textTheme.bodyLarge ?? const TextStyle()).copyWith(
                height: 1.55,
              ),
              scheme: scheme,
            ),
          ),
        ),
      );
      i++;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widgets,
    );
  }

  TextSpan _buildInlineSpan(
    String text, {
    required TextStyle baseStyle,
    required ColorScheme scheme,
  }) {
    final tokenRegex = RegExp(
      r'(\*\*(.+?)\*\*|\*(.+?)\*|`(.+?)`|\[([^\]]+)\]\(([^)]+)\))',
    );
    final spans = <InlineSpan>[];
    var lastIndex = 0;

    for (final match in tokenRegex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
      }
      if (match.group(2) != null) {
        spans.add(
          TextSpan(
            text: match.group(2),
            style: baseStyle.copyWith(fontWeight: FontWeight.w700),
          ),
        );
      } else if (match.group(3) != null) {
        spans.add(
          TextSpan(
            text: match.group(3),
            style: baseStyle.copyWith(fontStyle: FontStyle.italic),
          ),
        );
      } else if (match.group(4) != null) {
        spans.add(
          TextSpan(
            text: ' ${match.group(4)} ',
            style: baseStyle.copyWith(
              fontFamily: 'monospace',
              fontSize: (baseStyle.fontSize ?? 15) * 0.9,
              backgroundColor: scheme.surfaceContainerHigh,
              color: scheme.primary,
            ),
          ),
        );
      } else if (match.group(5) != null && match.group(6) != null) {
        final url = match.group(6)!;
        final recognizer = TapGestureRecognizer()..onTap = () => _openUrl(url);
        _recognizers.add(recognizer);
        spans.add(
          TextSpan(
            text: match.group(5),
            recognizer: recognizer,
            style: baseStyle.copyWith(
              color: scheme.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        );
      }
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }

    return TextSpan(style: baseStyle, children: spans);
  }
}
