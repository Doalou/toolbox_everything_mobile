import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_tokens.dart';
import 'package:toolbox_everything_mobile/core/services/app_feedback.dart';
import 'package:toolbox_everything_mobile/core/services/uuid_service.dart';
import 'package:toolbox_everything_mobile/shared/widgets/editorial_tool_components.dart';
import 'package:toolbox_everything_mobile/shared/widgets/editorial_tool_scaffold.dart';
import 'package:toolbox_everything_mobile/shared/widgets/expressive_action_button.dart';
import 'package:toolbox_everything_mobile/shared/widgets/expressive_card.dart';

class UuidGeneratorScreen extends StatefulWidget {
  final String heroTag;
  const UuidGeneratorScreen({super.key, required this.heroTag});

  @override
  State<UuidGeneratorScreen> createState() => _UuidGeneratorScreenState();
}

class _UuidGeneratorScreenState extends State<UuidGeneratorScreen> {
  final UuidService _service = UuidService();
  List<String> _uuids = [];
  int _count = 5;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  void _generate() {
    setState(() {
      _uuids = _service.v4Many(_count);
    });
  }

  Future<void> _copy(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    AppFeedback.copied(context, 'UUID copié');
  }

  Future<void> _copyAll() async {
    await Clipboard.setData(ClipboardData(text: _uuids.join('\n')));
    if (!mounted) return;
    AppFeedback.copied(context, '${_uuids.length} UUID copiés');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return EditorialToolScaffold(
      title: 'Générateur UUID',
      heroTag: widget.heroTag,
      actions: [
        IconButton(
          tooltip: 'Tout copier',
          onPressed: _uuids.isEmpty ? null : _copyAll,
          icon: const Icon(Icons.copy_all_rounded),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(ExpressiveTokens.spacingLg),
        children: [
          const EditorialToolIntro(
            icon: Icons.fingerprint_rounded,
            title: 'Identifiants uniques v4',
            description: 'Générez jusqu’à 100 UUID v4 cryptographiques.',
          ),
          const SizedBox(height: ExpressiveTokens.spacingLg),
          ExpressiveCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quantité',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _count.toDouble(),
                        min: 1,
                        max: 100,
                        divisions: 99,
                        label: '$_count',
                        onChanged: (v) => setState(() => _count = v.round()),
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: Text(
                        '$_count',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ExpressiveActionButton.iconLabel(
                  icon: Icons.refresh_rounded,
                  label: 'Générer $_count UUID',
                  onPressed: _generate,
                ),
              ],
            ),
          ),
          const SizedBox(height: ExpressiveTokens.spacingLg),
          ..._uuids.map(
            (u) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ExpressiveCard(
                onTap: () => _copy(u),
                padding: const EdgeInsets.symmetric(
                  horizontal: ExpressiveTokens.spacing,
                  vertical: ExpressiveTokens.spacingMd,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.fingerprint_rounded,
                      color: scheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        u,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.copy_rounded,
                      color: scheme.onSurfaceVariant,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
