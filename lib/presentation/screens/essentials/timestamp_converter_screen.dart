import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_tokens.dart';
import 'package:toolbox_everything_mobile/core/services/timestamp_service.dart';
import 'package:toolbox_everything_mobile/shared/widgets/expressive_action_button.dart';
import 'package:toolbox_everything_mobile/shared/widgets/expressive_card.dart';

class TimestampConverterScreen extends StatefulWidget {
  final String heroTag;
  const TimestampConverterScreen({super.key, required this.heroTag});

  @override
  State<TimestampConverterScreen> createState() =>
      _TimestampConverterScreenState();
}

class _TimestampConverterScreenState extends State<TimestampConverterScreen> {
  final TimestampService _service = const TimestampService();
  final TextEditingController _tsController = TextEditingController();
  bool _ms = false;
  DateTime? _decoded;
  String? _error;

  late final Timer _ticker;
  int _now = 0;

  @override
  void initState() {
    super.initState();
    _now = _service.nowSeconds();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = _service.nowSeconds());
    });
    _tsController.text = _now.toString();
    _decode();
  }

  @override
  void dispose() {
    _ticker.cancel();
    _tsController.dispose();
    super.dispose();
  }

  void _decode() {
    setState(() {
      _error = null;
      _decoded = null;
    });
    final raw = int.tryParse(_tsController.text.trim());
    if (raw == null) {
      setState(() => _error = 'Entrer un entier');
      return;
    }
    try {
      _decoded = _service.fromTimestamp(raw, milliseconds: _ms);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  void _useNow() {
    _tsController.text = _ms
        ? _service.nowMillis().toString()
        : _service.nowSeconds().toString();
    _decode();
  }

  Future<void> _copy(String text, [String label = 'Copié']) async {
    await Clipboard.setData(ClipboardData(text: text));
    Fluttertoast.showToast(msg: label);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final nowStr = _ms
        ? _service.nowMillis().toString()
        : _service.nowSeconds().toString();
    return Scaffold(
      appBar: AppBar(
        title: Hero(
          tag: widget.heroTag,
          child: Material(
            type: MaterialType.transparency,
            child: Text(
              'Timestamp ↔ Date',
              style: Theme.of(context).appBarTheme.titleTextStyle,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(ExpressiveTokens.spacingLg),
        children: [
          ExpressiveCard.hero(
            color: scheme.primaryContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Maintenant',
                  style: TextStyle(color: scheme.onPrimaryContainer),
                ),
                const SizedBox(height: 4),
                Text(
                  nowStr,
                  style: TextStyle(
                    color: scheme.onPrimaryContainer,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _service.toReadable(
                    DateTime.fromMillisecondsSinceEpoch(_now * 1000),
                  ),
                  style: TextStyle(
                    color: scheme.onPrimaryContainer.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: () => _copy(nowStr, 'Timestamp copié'),
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Copier'),
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
                Row(
                  children: [
                    Text(
                      'Timestamp',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text('s')),
                        ButtonSegment(value: true, label: Text('ms')),
                      ],
                      selected: {_ms},
                      onSelectionChanged: (s) {
                        setState(() => _ms = s.first);
                        _decode();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tsController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontFamily: 'monospace'),
                  onChanged: (_) => _decode(),
                  decoration: const InputDecoration(
                    hintText: 'Entrer un timestamp',
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    ExpressiveActionButton.iconLabel(
                      icon: Icons.access_time_rounded,
                      label: 'Maintenant',
                      onPressed: _useNow,
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
              child: Text(
                _error!,
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            )
          else if (_decoded != null)
            ExpressiveCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ResultRow(
                    label: 'ISO 8601',
                    value: _service.toIso(_decoded!),
                    onCopy: () => _copy(_service.toIso(_decoded!)),
                  ),
                  const Divider(),
                  _ResultRow(
                    label: 'Local',
                    value: _service.toReadable(_decoded!),
                    onCopy: () => _copy(_service.toReadable(_decoded!)),
                  ),
                  const Divider(),
                  _ResultRow(
                    label: 'UTC',
                    value: _decoded!.toUtc().toString(),
                    onCopy: () => _copy(_decoded!.toUtc().toString()),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onCopy;

  const _ResultRow({
    required this.label,
    required this.value,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
          ),
          IconButton(
            onPressed: onCopy,
            icon: const Icon(Icons.copy_rounded, size: 18),
            tooltip: 'Copier',
          ),
        ],
      ),
    );
  }
}
