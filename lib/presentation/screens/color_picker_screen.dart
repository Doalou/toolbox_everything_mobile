import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:toolbox_everything_mobile/core/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ColorPickerScreen extends StatefulWidget {
  final String heroTag;

  const ColorPickerScreen({super.key, required this.heroTag});

  @override
  State<ColorPickerScreen> createState() => _ColorPickerScreenState();
}

class _ColorPickerScreenState extends State<ColorPickerScreen> {
  Color _selectedColor = const Color(0xFF6750A4);
  List<Color> _recentColors = [];
  static const int _maxRecentColors = 12;
  static const String _prefsKey = 'recent_colors';

  @override
  void initState() {
    super.initState();
    _loadRecentColors();
  }

  Future<void> _loadRecentColors() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_prefsKey) ?? [];
    setState(() {
      _recentColors = saved
          .map((hex) => Color(int.parse(hex, radix: 16)))
          .take(_maxRecentColors)
          .toList();
    });
  }

  Future<void> _saveRecentColors() async {
    final prefs = await SharedPreferences.getInstance();
    final hexList = _recentColors
        .map((c) => c.toARGB32().toRadixString(16).padLeft(8, '0'))
        .toList();
    await prefs.setStringList(_prefsKey, hexList);
  }

  void _addToRecent(Color color) {
    setState(() {
      _recentColors.removeWhere((c) => c.toARGB32() == color.toARGB32());
      _recentColors.insert(0, color);
      if (_recentColors.length > _maxRecentColors) {
        _recentColors = _recentColors.take(_maxRecentColors).toList();
      }
    });
    _saveRecentColors();
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    Fluttertoast.showToast(msg: '$label copié !');
  }

  String get _hexValue =>
      '#${_selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

  String get _rgbValue =>
      'rgb(${_selectedColor.r.round()}, ${_selectedColor.g.round()}, ${_selectedColor.b.round()})';

  String get _rgbaValue =>
      'rgba(${_selectedColor.r.round()}, ${_selectedColor.g.round()}, ${_selectedColor.b.round()}, ${_selectedColor.a.toStringAsFixed(2)})';

  String get _hslValue {
    final hsl = HSLColor.fromColor(_selectedColor);
    return 'hsl(${hsl.hue.round()}, ${(hsl.saturation * 100).round()}%, ${(hsl.lightness * 100).round()}%)';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Hero(
          tag: widget.heroTag,
          child: Material(
            type: MaterialType.transparency,
            child: Text(
              'Sélecteur de couleurs',
              style: Theme.of(context).appBarTheme.titleTextStyle,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.palette, color: colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choisissez une couleur',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sélectionnez et copiez en HEX, RGB ou HSL.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onPrimaryContainer
                                        .withValues(alpha: 0.8),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Color picker card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ColorPicker(
                      pickerColor: _selectedColor,
                      onColorChanged: (color) {
                        setState(() => _selectedColor = color);
                      },
                      enableAlpha: true,
                      hexInputBar: true,
                      displayThumbColor: true,
                      pickerAreaHeightPercent: 0.6,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => _addToRecent(_selectedColor),
                      icon: const Icon(Icons.save),
                      label: const Text('Enregistrer dans les récents'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Preview & formats
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: _selectedColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.outline.withValues(alpha: 0.3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _selectedColor.withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Aperçu couleur',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _hexValue,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildFormatRow(context, 'HEX', _hexValue),
                    _buildFormatRow(context, 'RGB', _rgbValue),
                    _buildFormatRow(context, 'RGBA', _rgbaValue),
                    _buildFormatRow(context, 'HSL', _hslValue),
                  ],
                ),
              ),
            ),

            // Recent colors
            if (_recentColors.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.history,
                              color: colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Couleurs récentes',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _recentColors.map((color) {
                          return GestureDetector(
                            onTap: () => setState(() => _selectedColor = color),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: colorScheme.outline
                                      .withValues(alpha: 0.3),
                                  width: color.toARGB32() ==
                                          _selectedColor.toARGB32()
                                      ? 3
                                      : 1,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFormatRow(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                  ),
            ),
          ),
          IconButton(
            onPressed: () => _copyToClipboard(value, label),
            icon: const Icon(Icons.copy, size: 18),
            tooltip: 'Copier $label',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
