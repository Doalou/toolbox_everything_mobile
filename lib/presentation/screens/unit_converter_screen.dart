import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_shapes.dart';
import 'package:toolbox_everything_mobile/core/models/unit_conversion.dart';
import 'package:toolbox_everything_mobile/core/services/app_feedback.dart';
import 'package:toolbox_everything_mobile/core/services/conversion_service.dart';
import 'package:toolbox_everything_mobile/core/services/haptics_service.dart';
import 'package:toolbox_everything_mobile/shared/widgets/editorial_tool_components.dart';
import 'package:toolbox_everything_mobile/shared/widgets/editorial_tool_scaffold.dart';
import 'package:toolbox_everything_mobile/shared/widgets/expressive_card.dart';

class UnitConverterScreen extends StatefulWidget {
  final String heroTag;
  final String? initialValue;

  const UnitConverterScreen({
    super.key,
    required this.heroTag,
    this.initialValue,
  });

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

  double? _activeSourceValue;

  @override
  void initState() {
    super.initState();
    _selectedCategory = _conversionService.categories.first;
    _fromUnit = _selectedCategory.units[2]; // Mètre
    _toUnit = _selectedCategory.units[3]; // Kilomètre
    if (widget.initialValue != null && widget.initialValue!.trim().isNotEmpty) {
      _fromController.text = widget.initialValue!.trim();
      _performConversion(_fromController.text);
    }
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _fromFocus.dispose();
    _toFocus.dispose();
    super.dispose();
  }

  double? _parseNumber(String raw) {
    final normalized = raw.trim().replaceAll(',', '.').replaceAll(' ', '');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  void _performConversion(String value, {bool fromTo = true}) {
    if (value.trim().isEmpty) {
      setState(() {
        _toController.clear();
        _fromController.clear();
        _activeSourceValue = null;
      });
      return;
    }

    final input = _parseNumber(value);
    if (input == null) {
      setState(() {
        _activeSourceValue = null;
        if (fromTo) {
          _toController.clear();
        } else {
          _fromController.clear();
        }
      });
      return;
    }

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

    final formatted = _conversionService.formatValue(result);
    setState(() {
      if (fromTo) {
        _toController.text = formatted;
        _activeSourceValue = input;
      } else {
        _fromController.text = formatted;
        _activeSourceValue = result;
      }
    });
  }

  void _swapUnits() {
    HapticsService.perform(context, HapticType.selection);
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

  void _selectCategory(ConversionCategory category) {
    HapticsService.perform(context, HapticType.selection);
    setState(() {
      _selectedCategory = category;
      _fromUnit = category.units.first;
      _toUnit = category.units.length > 1
          ? category.units[1]
          : category.units.first;
    });
    if (_fromController.text.isNotEmpty) {
      _performConversion(_fromController.text);
    } else {
      setState(() {
        _toController.clear();
        _activeSourceValue = null;
      });
    }
  }

  void _copyValue(String text, [String label = 'Valeur copiée']) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    AppFeedback.copied(context, label);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sourceValue = _activeSourceValue;

    return EditorialToolScaffold(
      title: 'Convertisseur d\'unités',
      heroTag: widget.heroTag,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _IntroCard(),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _conversionService.categories.map((category) {
                final selected = identical(category, _selectedCategory);
                return ChoiceChip(
                  label: Text(category.name),
                  selected: selected,
                  onSelected: (_) => _selectCategory(category),
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
            if (sourceValue != null) ...[
              const SizedBox(height: 16),
              ExpressiveCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.view_list_rounded,
                          size: 20,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Toutes les équivalences',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Touchez une ligne pour copier le résultat.',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    ..._selectedCategory.units.map((unit) {
                      final converted = _conversionService.convert(
                        sourceValue,
                        _fromUnit,
                        unit,
                        _selectedCategory,
                      );
                      final formatted = _conversionService.formatValue(
                        converted,
                      );
                      final unitDisplay = unit.symbol.isEmpty
                          ? formatted
                          : '$formatted ${unit.symbol}';
                      final isSource = unit.name == _fromUnit.name;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Material(
                          color: isSource
                              ? colorScheme.primaryContainer.withValues(
                                  alpha: 0.45,
                                )
                              : colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(
                            ExpressiveShapes.medium,
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(
                              ExpressiveShapes.medium,
                            ),
                            onTap: () => _copyValue(
                              formatted,
                              '${unit.name} copié ($unitDisplay)',
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      unit.symbol.isEmpty
                                          ? unit.name
                                          : '${unit.name} (${unit.symbol})',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: isSource
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      unitDisplay,
                                      textAlign: TextAlign.end,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontFamily: 'monospace',
                                            fontWeight: FontWeight.w700,
                                            color: colorScheme.primary,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _unitColumn({required bool isFrom}) {
    final controller = isFrom ? _fromController : _toController;
    final node = isFrom ? _fromFocus : _toFocus;
    final selectedUnit = isFrom ? _fromUnit : _toUnit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<Unit>(
          initialValue: selectedUnit,
          isExpanded: true,
          items: _selectedCategory.units.map((unit) {
            final label = unit.symbol.isEmpty
                ? unit.name
                : '${unit.name} (${unit.symbol})';
            return DropdownMenuItem(
              value: unit,
              child: Text(label, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (unit) {
            if (unit == null) return;
            setState(() {
              if (isFrom) {
                _fromUnit = unit;
              } else {
                _toUnit = unit;
              }
            });
            _performConversion(_fromController.text);
          },
          decoration: InputDecoration(
            labelText: isFrom ? 'Unité source' : 'Unité cible',
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          focusNode: node,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          textInputAction: isFrom ? TextInputAction.next : TextInputAction.done,
          decoration: InputDecoration(
            labelText: isFrom ? 'Valeur' : 'Résultat',
            suffixText: selectedUnit.symbol.isEmpty
                ? null
                : selectedUnit.symbol,
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  tooltip: 'Copier',
                  onPressed: () => _copyValue(controller.text),
                ),
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  tooltip: 'Effacer',
                  onPressed: () {
                    controller.clear();
                    if (isFrom) {
                      _toController.clear();
                    } else {
                      _fromController.clear();
                    }
                    setState(() => _activeSourceValue = null);
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
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return const EditorialToolIntro(
      icon: Icons.swap_horiz_rounded,
      title: 'Convertir des unités',
      description: '10 catégories hors ligne : longueur, masse, volume, vitesse, pression…',
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
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
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
