import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_tokens.dart';
import 'package:toolbox_everything_mobile/core/services/app_feedback.dart';
import 'package:toolbox_everything_mobile/core/services/haptics_service.dart';
import 'package:toolbox_everything_mobile/core/services/timestamp_service.dart';
import 'package:toolbox_everything_mobile/shared/widgets/editorial_tool_components.dart';
import 'package:toolbox_everything_mobile/shared/widgets/editorial_tool_scaffold.dart';
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
  final TextEditingController _dateTextController = TextEditingController();

  bool _ms = false;
  DateTime? _decoded;
  String? _error;

  late DateTime _selectedDateTime;
  bool _dateAsUtc = false;
  String? _dateInputError;

  late final Timer _ticker;
  int _now = 0;

  @override
  void initState() {
    super.initState();
    final current = DateTime.now();
    _selectedDateTime = DateTime(
      current.year,
      current.month,
      current.day,
      current.hour,
      current.minute,
      current.second,
    );
    _dateTextController.text = _service.toReadable(_selectedDateTime);
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
    _dateTextController.dispose();
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
    HapticsService.perform(context, HapticType.selection);
    _tsController.text = _ms
        ? _service.nowMillis().toString()
        : _service.nowSeconds().toString();
    _decode();
  }

  Future<void> _pasteTimestamp() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) return;
    _tsController.text = text;
    _decode();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    _updatePickedDateTime(
      year: picked.year,
      month: picked.month,
      day: picked.day,
      hour: _selectedDateTime.hour,
      minute: _selectedDateTime.minute,
      second: _selectedDateTime.second,
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (picked == null || !mounted) return;
    _updatePickedDateTime(
      year: _selectedDateTime.year,
      month: _selectedDateTime.month,
      day: _selectedDateTime.day,
      hour: picked.hour,
      minute: picked.minute,
      second: 0,
    );
  }

  void _updatePickedDateTime({
    required int year,
    required int month,
    required int day,
    required int hour,
    required int minute,
    required int second,
  }) {
    final next = _dateAsUtc
        ? DateTime.utc(year, month, day, hour, minute, second)
        : DateTime(year, month, day, hour, minute, second);
    setState(() {
      _selectedDateTime = next;
      _dateInputError = null;
      _dateTextController.text = _service.toReadable(next, utc: _dateAsUtc);
    });
  }

  void _onDateTextChanged(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      setState(() => _dateInputError = 'Entrer une date ISO ou JJ/MM/AAAA');
      return;
    }
    final parsed = _service.tryParseDate(trimmed, utc: _dateAsUtc);
    if (parsed == null) {
      setState(() {
        _dateInputError =
            'Format attendu : 2026-11-18T14:30:00 ou 18/11/2026 14:30';
      });
      return;
    }
    setState(() {
      _selectedDateTime = parsed;
      _dateInputError = null;
    });
  }

  Future<void> _copy(String text, [String label = 'Copié']) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    AppFeedback.copied(context, label);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final nowStr = _ms
        ? _service.nowMillis().toString()
        : _service.nowSeconds().toString();
    final targetSec = _service.toTimestamp(_selectedDateTime).toString();
    final targetMs = _service
        .toTimestamp(_selectedDateTime, milliseconds: true)
        .toString();

    return EditorialToolScaffold(
      title: 'Timestamp ↔ date',
      heroTag: widget.heroTag,
      body: ListView(
        padding: const EdgeInsets.all(ExpressiveTokens.spacingLg),
        children: [
          const EditorialToolIntro(
            icon: Icons.schedule_rounded,
            title: 'Epoch ↔ date lisible',
            description:
                'Convertissez secondes ou millisecondes Unix en local et UTC.',
          ),
          const SizedBox(height: ExpressiveTokens.spacingLg),
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
                    Expanded(
                      child: Text(
                        'Timestamp → Date',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    SegmentedButton<bool>(
                      showSelectedIcon: false,
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
                  decoration: InputDecoration(
                    hintText: 'Entrer un timestamp',
                    suffixIcon: IconButton(
                      onPressed: _pasteTimestamp,
                      icon: const Icon(Icons.paste_rounded),
                      tooltip: 'Coller',
                    ),
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
                    value: _service.toReadable(_decoded!, utc: true),
                    onCopy: () =>
                        _copy(_service.toReadable(_decoded!, utc: true)),
                  ),
                  const Divider(),
                  _ResultRow(
                    label: 'Relatif',
                    value: _service.relativeFromNow(_decoded!),
                    onCopy: () => _copy(_service.relativeFromNow(_decoded!)),
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
                    Expanded(
                      child: Text(
                        'Date & heure → Timestamp',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    SegmentedButton<bool>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: false, label: Text('Local')),
                        ButtonSegment(value: true, label: Text('UTC')),
                      ],
                      selected: {_dateAsUtc},
                      onSelectionChanged: (s) {
                        HapticsService.perform(context, HapticType.selection);
                        final nextUtc = s.first;
                        setState(() {
                          _dateAsUtc = nextUtc;
                          _selectedDateTime = nextUtc
                              ? _selectedDateTime.toUtc()
                              : _selectedDateTime.toLocal();
                          _dateTextController.text = _service.toReadable(
                            _selectedDateTime,
                            utc: nextUtc,
                          );
                          _dateInputError = null;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today_rounded, size: 18),
                      label: Text(
                        '${_selectedDateTime.day.toString().padLeft(2, '0')}/'
                        '${_selectedDateTime.month.toString().padLeft(2, '0')}/'
                        '${_selectedDateTime.year}',
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.schedule_rounded, size: 18),
                      label: Text(
                        '${_selectedDateTime.hour.toString().padLeft(2, '0')}:'
                        '${_selectedDateTime.minute.toString().padLeft(2, '0')}:'
                        '${_selectedDateTime.second.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _dateTextController,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  onChanged: _onDateTextChanged,
                  decoration: InputDecoration(
                    labelText: 'Ou saisir/coller une date',
                    hintText: '2026-11-18T14:30:00 ou 18/11/2026 14:30',
                    errorText: _dateInputError,
                  ),
                ),
                if (_dateInputError == null) ...[
                  const SizedBox(height: 12),
                  _ResultRow(
                    label: 'Secondes',
                    value: targetSec,
                    onCopy: () => _copy(targetSec, 'Timestamp (s) copié'),
                  ),
                  const Divider(),
                  _ResultRow(
                    label: 'Millisec.',
                    value: targetMs,
                    onCopy: () => _copy(targetMs, 'Timestamp (ms) copié'),
                  ),
                ],
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
