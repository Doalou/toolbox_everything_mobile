import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toolbox_everything_mobile/core/models/unit_conversion.dart';
import 'package:toolbox_everything_mobile/core/services/conversion_service.dart';

class UnitConverterScreen extends StatefulWidget {
  final String heroTag;

  const UnitConverterScreen({super.key, required this.heroTag});

  @override
  UnitConverterScreenState createState() => UnitConverterScreenState();
}

class UnitConverterScreenState extends State<UnitConverterScreen> {
  final ConversionService _conversionService = ConversionService();
  late ConversionCategory _selectedCategory;
  late Unit _fromUnit;
  late Unit _toUnit;
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final FocusNode _fromFocus = FocusNode();
  final FocusNode _toFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _selectedCategory = _conversionService.categories.first;
    _fromUnit = _selectedCategory.units.first;
    _toUnit = _selectedCategory.units.last;
  }

  void _performConversion(String value, {bool fromTo = true}) {
    if (value.isEmpty) {
      _toController.clear();
      _fromController.clear();
      return;
    }

    double? input = double.tryParse(value);
    if (input == null) return;

    double result = fromTo
        ? _conversionService.convert(
            input,
            _fromUnit,
            _toUnit,
            _selectedCategory,
          )
        : _conversionService.convert(
            input,
            _toUnit,
            _fromUnit,
            _selectedCategory,
          );

    if (fromTo) {
      _toController.text = result.toStringAsFixed(2);
    } else {
      _fromController.text = result.toStringAsFixed(2);
    }
  }

  void _swapUnits() {
    setState(() {
      final Unit tmp = _fromUnit;
      _fromUnit = _toUnit;
      _toUnit = tmp;
      final String t = _fromController.text;
      _fromController.text = _toController.text;
      _toController.text = t;
    });
    _performConversion(_fromController.text);
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
              'Convertisseur d\'unités',
              style: Theme.of(context).appBarTheme.titleTextStyle,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Bandeau d'intro harmonisé Material You
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
                    child: Icon(Icons.swap_horiz, color: colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Convertissez rapidement vos unités',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choisissez une catégorie, sélectionnez les unités et entrez une valeur.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
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

            // Catégories (chips)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _conversionService.categories.map((c) {
                final selected = identical(c, _selectedCategory);
                return ChoiceChip(
                  label: Text(c.name),
                  selected: selected,
                  onSelected: (v) {
                    setState(() {
                      _selectedCategory = c;
                      _fromUnit = _selectedCategory.units.first;
                      _toUnit = _selectedCategory.units.last;
                      _fromController.clear();
                      _toController.clear();
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Carte de conversion
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final bool stack = constraints.maxWidth < 420;
                    if (stack) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildUnitColumn(true),
                          const SizedBox(height: 8),
                          Center(
                            child: Material(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: _swapUnits,
                                child: const Padding(
                                  padding: EdgeInsets.all(10.0),
                                  child: Icon(Icons.swap_vert),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildUnitColumn(false),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: _buildUnitColumn(true)),
                        const SizedBox(width: 8),
                        Material(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _swapUnits,
                            child: const Padding(
                              padding: EdgeInsets.all(10.0),
                              child: Icon(Icons.swap_horiz),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: _buildUnitColumn(false)),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitColumn(bool isFrom) {
    final TextEditingController controller = isFrom
        ? _fromController
        : _toController;
    final FocusNode node = isFrom ? _fromFocus : _toFocus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<Unit>(
          initialValue: isFrom ? _fromUnit : _toUnit,
          items: _selectedCategory.units.map((unit) {
            return DropdownMenuItem(value: unit, child: Text(unit.name));
          }).toList(),
          onChanged: (unit) {
            setState(() {
              if (isFrom) {
                _fromUnit = unit!;
              } else {
                _toUnit = unit!;
              }
              _performConversion(_fromController.text);
            });
          },
          decoration: InputDecoration(
            labelText: isFrom ? 'Unité source' : 'Unité cible',
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          focusNode: node,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: isFrom ? TextInputAction.next : TextInputAction.done,
          decoration: InputDecoration(
            labelText: isFrom ? 'Valeur' : 'Résultat',
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  tooltip: 'Copier',
                  onPressed: () {
                    final text = controller.text;
                    if (text.isNotEmpty) {
                      Clipboard.setData(ClipboardData(text: text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copié !'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  tooltip: 'Effacer',
                  onPressed: () {
                    controller.clear();
                    if (isFrom) _toController.clear();
                  },
                ),
              ],
            ),
          ),
          onChanged: (value) => _performConversion(value, fromTo: isFrom),
        ),
      ],
    );
  }
}
