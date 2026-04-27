import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_tokens.dart';
import 'package:toolbox_everything_mobile/core/services/jwt_service.dart';
import 'package:toolbox_everything_mobile/shared/widgets/expressive_card.dart';
import 'package:toolbox_everything_mobile/shared/widgets/status_badge.dart';

class JwtDecoderScreen extends StatefulWidget {
  final String heroTag;
  const JwtDecoderScreen({super.key, required this.heroTag});

  @override
  State<JwtDecoderScreen> createState() => _JwtDecoderScreenState();
}

class _JwtDecoderScreenState extends State<JwtDecoderScreen> {
  final TextEditingController _input = TextEditingController();
  final JwtService _service = const JwtService();
  DecodedJwt? _decoded;
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _decode() {
    setState(() {
      _error = null;
      _decoded = null;
    });
    if (_input.text.trim().isEmpty) return;
    try {
      _decoded = _service.decode(_input.text.trim());
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      _input.text = data!.text!;
      _decode();
    }
  }

  Future<void> _copy(Map<String, dynamic> map) async {
    final str = const JsonEncoder.withIndent('  ').convert(map);
    await Clipboard.setData(ClipboardData(text: str));
    Fluttertoast.showToast(msg: 'Copié');
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
              'JWT Decoder',
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
              const StatusBadge(
                label: 'Sans vérif. signature',
                icon: Icons.warning_amber_rounded,
                tone: BadgeTone.warning,
              ),
            ],
          ),
          const SizedBox(height: ExpressiveTokens.spacingLg),
          ExpressiveCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Token', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextField(
                  controller: _input,
                  minLines: 4,
                  maxLines: 10,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  onChanged: (_) => _decode(),
                  decoration: const InputDecoration(
                    hintText: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.…',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _paste,
                      icon: const Icon(Icons.paste_rounded),
                      label: const Text('Coller'),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        _input.clear();
                        _decode();
                      },
                      icon: const Icon(Icons.clear_rounded),
                      label: const Text('Effacer'),
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
          else if (_decoded != null) ...[
            if (_decoded!.expiresAt != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: StatusBanner(
                  message: _decoded!.isExpired
                      ? 'Token expiré le ${_decoded!.expiresAt!.toLocal()}'
                      : 'Expire le ${_decoded!.expiresAt!.toLocal()}',
                  icon: _decoded!.isExpired
                      ? Icons.error_outline
                      : Icons.schedule,
                  tone: _decoded!.isExpired ? BadgeTone.danger : BadgeTone.info,
                ),
              ),
            _JwtSection(
              label: 'Header',
              data: _decoded!.header,
              onCopy: () => _copy(_decoded!.header),
            ),
            const SizedBox(height: 12),
            _JwtSection(
              label: 'Payload',
              data: _decoded!.payload,
              onCopy: () => _copy(_decoded!.payload),
            ),
            const SizedBox(height: 12),
            ExpressiveCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Signature',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    _decoded!.signature,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _JwtSection extends StatelessWidget {
  final String label;
  final Map<String, dynamic> data;
  final VoidCallback onCopy;

  const _JwtSection({
    required this.label,
    required this.data,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final pretty = const JsonEncoder.withIndent('  ').convert(data);
    return ExpressiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              IconButton(
                onPressed: onCopy,
                icon: const Icon(Icons.copy_rounded),
                tooltip: 'Copier',
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            pretty,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
