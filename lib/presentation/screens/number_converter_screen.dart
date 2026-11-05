import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toolbox_everything_mobile/core/services/app_feedback.dart';
import 'package:toolbox_everything_mobile/shared/widgets/editorial_tool_components.dart';
import 'package:toolbox_everything_mobile/shared/widgets/editorial_tool_scaffold.dart';
import 'package:toolbox_everything_mobile/shared/widgets/expressive_card.dart';

class NumberConverterScreen extends StatefulWidget {
  final String heroTag;

  const NumberConverterScreen({super.key, required this.heroTag});

  @override
  State<NumberConverterScreen> createState() => _NumberConverterScreenState();
}

class _NumberConverterScreenState extends State<NumberConverterScreen> {
  final Map<String, TextEditingController> _controllers = {
    'decimal': TextEditingController(),
    'binary': TextEditingController(),
    'hexadecimal': TextEditingController(),
    'ascii': TextEditingController(),
  };

  final Map<String, FocusNode> _focusNodes = {
    'decimal': FocusNode(),
    'binary': FocusNode(),
    'hexadecimal': FocusNode(),
    'ascii': FocusNode(),
  };

  bool _isUpdatingControllers = false;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _convertFrom(String sourceType) {
    if (_isUpdatingControllers) return;

    final String value = _controllers[sourceType]!.text.trim();
    if (value.isEmpty) {
      _clearAllExcept(sourceType);
      return;
    }

    int? decimalValue;
    String? asciiValue;

    try {
      switch (sourceType) {
        case 'decimal':
          decimalValue = int.tryParse(value);
          break;
        case 'binary':
          decimalValue = int.tryParse(value, radix: 2);
          break;
        case 'hexadecimal':
          final cleanHex = value.replaceAll('0x', '').replaceAll('#', '');
          decimalValue = int.tryParse(cleanHex, radix: 16);
          break;
        case 'ascii':
          if (value.length == 1) {
            decimalValue = value.codeUnitAt(0);
            asciiValue = value;
          }
          break;
      }

      if (decimalValue != null &&
          decimalValue >= 0 &&
          decimalValue <= 1114111) {
        _updateFields(decimalValue, asciiValue, sourceType);
      } else {
        _clearAllExcept(sourceType);
      }
    } catch (_) {
      _clearAllExcept(sourceType);
    }
  }

  void _onChanged(String sourceType) {
    if (_isUpdatingControllers) return;
    _convertFrom(sourceType);
  }

  void _updateFields(int decimal, String? ascii, String except) {
    _isUpdatingControllers = true;
    try {
      setState(() {
        if (except != 'decimal') {
          _controllers['decimal']!.text = decimal.toString();
        }
        if (except != 'binary') {
          _controllers['binary']!.text = decimal.toRadixString(2);
        }
        if (except != 'hexadecimal') {
          _controllers['hexadecimal']!.text =
              '0x${decimal.toRadixString(16).toUpperCase()}';
        }
        if (except != 'ascii') {
          if (decimal >= 32 && decimal <= 126) {
            _controllers['ascii']!.text = String.fromCharCode(decimal);
          } else if (ascii != null) {
            _controllers['ascii']!.text = ascii;
          } else {
            _controllers['ascii']!.text = '(non-printable)';
          }
        }
      });
    } finally {
      _isUpdatingControllers = false;
    }
  }

  void _clearAllExcept(String except) {
    setState(() {
      for (final entry in _controllers.entries) {
        if (entry.key != except) {
          entry.value.text = '';
        }
      }
    });
  }

  void _clearAll() {
    for (final controller in _controllers.values) {
      controller.clear();
    }
    setState(() {});
  }

  String _groupBinaryForDisplay(String bin) {
    if (bin.isEmpty) return '';
    final remainder = bin.length % 4;
    final padded = remainder == 0
        ? bin
        : bin.padLeft(bin.length + (4 - remainder), '0');
    final buffer = StringBuffer();
    for (int i = 0; i < padded.length; i += 4) {
      if (i > 0) buffer.write(' ');
      buffer.write(padded.substring(i, i + 4));
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return EditorialToolScaffold(
      title: 'Convertisseur de nombres',
      heroTag: widget.heroTag,
      actions: [
        IconButton(
          onPressed: _clearAll,
          icon: Icon(Icons.clear_all_rounded, color: colorScheme.primary),
          tooltip: 'Effacer tout',
        ),
      ],
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const EditorialToolIntro(
              icon: Icons.transform_rounded,
              title: 'Convertir un nombre',
              description: 'Binaire, décimal, hexadécimal et ASCII.',
            ),
            const SizedBox(height: 16),
            _buildConverterField(
              'decimal',
              'Décimal (base 10)',
              Icons.filter_9_plus_rounded,
              '255',
              TextInputType.number,
              r'^[0-9]*$',
            ),
            const SizedBox(height: 14),
            _buildConverterField(
              'binary',
              'Binaire (base 2)',
              Icons.code_rounded,
              '11111111',
              TextInputType.text,
              r'^[01]*$',
            ),
            const SizedBox(height: 14),
            _buildConverterField(
              'hexadecimal',
              'Hexadécimal (base 16)',
              Icons.tag_rounded,
              '0xFF',
              TextInputType.text,
              r'^(0x|#)?[0-9A-Fa-f]*$',
            ),
            const SizedBox(height: 14),
            _buildConverterField(
              'ascii',
              'ASCII (caractère)',
              Icons.text_fields_rounded,
              'A',
              TextInputType.text,
              r'^.?$',
            ),
            const SizedBox(height: 16),
            _buildQuickExamples(),
          ],
        ),
      ),
    );
  }

  Widget _buildConverterField(
    String key,
    String label,
    IconData icon,
    String hint,
    TextInputType keyboardType,
    String pattern,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return ExpressiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: ShapeDecoration(
                  color: colorScheme.primaryContainer,
                  shape: const StadiumBorder(),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (_controllers[key]!.text.isNotEmpty)
                IconButton(
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: _controllers[key]!.text),
                    );
                    AppFeedback.copied(context, '$label copié');
                  },
                  icon: Icon(
                    Icons.copy_rounded,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  tooltip: 'Copier',
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controllers[key],
            focusNode: _focusNodes[key],
            keyboardType: keyboardType,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(hintText: hint),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(pattern)),
              if (key == 'ascii') LengthLimitingTextInputFormatter(1),
            ],
            onChanged: (_) => _onChanged(key),
          ),
          if (key == 'binary' && _controllers['binary']!.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: ShapeDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    _groupBinaryForDisplay(_controllers['binary']!.text),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: ShapeDecoration(
                    color: colorScheme.secondaryContainer,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    '${_controllers['binary']!.text.length} bits',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickExamples() {
    final colorScheme = Theme.of(context).colorScheme;

    final List<Map<String, String>> examples = [
      {'decimal': '65', 'label': 'A'},
      {'decimal': '97', 'label': 'a'},
      {'decimal': '255', 'label': 'MAX'},
      {'decimal': '189', 'label': '½'},
    ];

    return ExpressiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Exemples rapides',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: examples.map((example) {
              return ActionChip(
                label: Text('${example['decimal']} → ${example['label']}'),
                onPressed: () {
                  _controllers['decimal']!.text = example['decimal']!;
                  _convertFrom('decimal');
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
