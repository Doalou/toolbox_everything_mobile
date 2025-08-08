import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Animations visuelles retirées

class NumberConverterScreen extends StatefulWidget {
  const NumberConverterScreen({super.key});

  @override
  State<NumberConverterScreen> createState() => _NumberConverterScreenState();
}

class _NumberConverterScreenState extends State<NumberConverterScreen>
    with TickerProviderStateMixin {
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

  String _lastUpdated = '';
  late AnimationController _pulseController;
  bool _isUpdatingControllers = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    // Animation retirée; le contrôleur reste pour un léger feedback si besoin

    // Listeners pour la conversion automatique
    _controllers['decimal']!.addListener(() => _convertFrom('decimal'));
    _controllers['binary']!.addListener(() => _convertFrom('binary'));
    _controllers['hexadecimal']!.addListener(() => _convertFrom('hexadecimal'));
    _controllers['ascii']!.addListener(() => _convertFrom('ascii'));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _convertFrom(String sourceType) {
    if (_isUpdatingControllers) return;
    if (_lastUpdated == sourceType) return;
    _lastUpdated = sourceType;

    try {
      final String value = _controllers[sourceType]!.text.trim();
      if (value.isEmpty) {
        _clearAllExcept(sourceType);
        return;
      }

      int? decimalValue;
      String? asciiValue;

      // Conversion vers décimal d'abord
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
        _triggerPulse();
      } else {
        _clearAllExcept(sourceType);
      }
    } catch (e) {
      _clearAllExcept(sourceType);
    }

    _lastUpdated = '';
  }

  void _updateFields(int decimal, String? ascii, String except) {
    _isUpdatingControllers = true;
    try {
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
    } finally {
      _isUpdatingControllers = false;
    }
  }

  void _clearAllExcept(String except) {
    for (var entry in _controllers.entries) {
      if (entry.key != except) {
        entry.value.text = '';
      }
    }
  }

  void _triggerPulse() {
    _pulseController.forward().then((_) {
      _pulseController.reverse();
    });
  }

  void _clearAll() {
    for (var controller in _controllers.values) {
      controller.clear();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Convertisseur de nombres'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _clearAll,
            icon: Icon(Icons.clear_all, color: colorScheme.primary),
            tooltip: 'Effacer tout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header (sans animation)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primaryContainer.withValues(alpha: 0.8),
                    colorScheme.secondaryContainer.withValues(alpha: 0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(Icons.transform, size: 48, color: colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    'Convertisseur universel',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Binaire • Décimal • Hexadécimal • ASCII',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Champs de conversion
            Column(
              children: [
                // Décimal
                _buildConverterField(
                  'decimal',
                  'Décimal (base 10)',
                  Icons.filter_9_plus,
                  '255',
                  TextInputType.number,
                  r'^[0-9]*$',
                ),

                const SizedBox(height: 32),

                // Binaire
                _buildConverterField(
                  'binary',
                  'Binaire (base 2)',
                  Icons.code,
                  '11111111',
                  TextInputType.text,
                  r'^[01]*$',
                ),

                const SizedBox(height: 32),

                // Hexadécimal
                _buildConverterField(
                  'hexadecimal',
                  'Hexadécimal (base 16)',
                  Icons.tag,
                  '0xFF',
                  TextInputType.text,
                  r'^(0x|#)?[0-9A-Fa-f]*$',
                ),

                const SizedBox(height: 32),

                // ASCII
                _buildConverterField(
                  'ascii',
                  'ASCII (caractère)',
                  Icons.text_fields,
                  'A',
                  TextInputType.text,
                  r'^.?$',
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Exemples rapides
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
    final bool isActive = _focusNodes[key]!.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? colorScheme.primary
              : colorScheme.outline.withOpacity(0.2),
          width: isActive ? 2 : 1,
        ),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                if (_controllers[key]!.text.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: _controllers[key]!.text),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$label copié !'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.copy,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    tooltip: 'Copier',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: TextField(
                controller: _controllers[key],
                focusNode: _focusNodes[key],
                keyboardType: keyboardType,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(pattern)),
                  if (key == 'ascii') LengthLimitingTextInputFormatter(1),
                ],
              ),
            ),
          ],
        ),
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flash_on, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Exemples rapides',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: examples.map((example) {
              return InkWell(
                onTap: () {
                  _controllers['decimal']!.text = example['decimal']!;
                  _convertFrom('decimal');
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        example['decimal']!,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('→', style: TextStyle(color: colorScheme.primary)),
                      const SizedBox(width: 6),
                      Text(
                        example['label']!,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
