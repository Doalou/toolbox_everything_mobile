import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toolbox_everything_mobile/core/models/unit_conversion.dart';
import 'package:toolbox_everything_mobile/core/services/conversion_service.dart';
import 'package:toolbox_everything_mobile/shared/widgets/expressive_card.dart';

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

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _fromFocus.dispose();
    _toFocus.dispose();
    super.dispose();
  }

  void _performConversion(String value, {bool fromTo = true}) {
    if (value.isEmpty) {
      _toController.clear();
      _fromController.clear();
      return;
    }

    final input = double.tryParse(value);
    if (input == null) return;

    final result = fromTo
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
      final unit = _fromUnit;
      _fromUnit = _toUnit;
      _toUnit = unit;
      final text = _fromController.text;
      _fromController.text = _toController.text;
      _toController.text = text;
    });
    _performConversion(_fromController.text);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
            _IntroCard(scheme: scheme),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _conversionService.categories.map((category) {
                final selected = identical(category, _selectedCategory);
                return ChoiceChip(
                  label: Text(category.name),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      _selectedCategory = category;
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
            ExpressiveCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ConversionCardHeader(category: _selectedCategory.name),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stack = constraints.maxWidth < 420;
                      if (stack) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _unitColumn(isFrom: true),
                            const SizedBox(height: 8),
                            Center(child: _SwapButton(onTap: _swapUnits)),
                            const SizedBox(height: 8),
                            _unitColumn(isFrom: false),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: _unitColumn(isFrom: true)),
                          const SizedBox(width: 8),
                          _SwapButton(onTap: _swapUnits, horizontal: true),
                          const SizedBox(width: 8),
                          Expanded(child: _unitColumn(isFrom: false)),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _unitColumn({required bool isFrom}) {
    final controller = isFrom ? _fromController : _toController;
    final node = isFrom ? _fromFocus : _toFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<Unit>(
          initialValue: isFrom ? _fromUnit : _toUnit,
          items: _selectedCategory.units.map((unit) {
            return DropdownMenuItem(value: unit, child: Text(unit.name));
          }).toList(),
          onChanged: (unit) {
            if (unit == null) return;
            setState(() {
              if (isFrom) {
                _fromUnit = unit;
              } else {
                _toUnit = unit;
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
                    if (text.isEmpty) return;
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copié !'),
                        duration: Duration(seconds: 1),
                      ),
                    );
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

class _IntroCard extends StatelessWidget {
  final ColorScheme scheme;

  const _IntroCard({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.swap_horiz, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Convertissez rapidement vos unités',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choisissez une catégorie, sélectionnez les unités et entrez une valeur.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onPrimaryContainer.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversionCardHeader extends StatelessWidget {
  final String category;

  const _ConversionCardHeader({required this.category});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: ShapeDecoration(
            color: scheme.primary.withValues(alpha: 0.14),
            shape: const StadiumBorder(),
          ),
          child: Icon(Icons.straighten_rounded, color: scheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Conversion',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                category,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SwapButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool horizontal;

  const _SwapButton({required this.onTap, this.horizontal = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.primaryContainer,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            horizontal ? Icons.swap_horiz_rounded : Icons.swap_vert_rounded,
            color: scheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}
