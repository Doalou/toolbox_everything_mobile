import 'package:flutter/material.dart';
import 'package:toolbox_everything_mobile/core/models/unit_conversion.dart';
import 'package:toolbox_everything_mobile/core/services/conversion_service.dart';

class UnitConverterScreen extends StatefulWidget {
  const UnitConverterScreen({super.key});

  @override
  _UnitConverterScreenState createState() => _UnitConverterScreenState();
}

class _UnitConverterScreenState extends State<UnitConverterScreen> {
  final ConversionService _conversionService = ConversionService();
  late ConversionCategory _selectedCategory;
  late Unit _fromUnit;
  late Unit _toUnit;
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

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
      ? _conversionService.convert(input, _fromUnit, _toUnit, _selectedCategory)
      : _conversionService.convert(input, _toUnit, _fromUnit, _selectedCategory);

    if (fromTo) {
      _toController.text = result.toStringAsFixed(2);
    } else {
      _fromController.text = result.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Convertisseur d\'unités')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<ConversionCategory>(
              value: _selectedCategory,
              items: _conversionService.categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category.name),
                );
              }).toList(),
              onChanged: (category) {
                setState(() {
                  _selectedCategory = category!;
                  _fromUnit = _selectedCategory.units.first;
                  _toUnit = _selectedCategory.units.last;
                  _fromController.clear();
                  _toController.clear();
                });
              },
              decoration: const InputDecoration(
                labelText: 'Catégorie',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildUnitColumn(true)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Icon(Icons.swap_horiz),
                ),
                Expanded(child: _buildUnitColumn(false)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildUnitColumn(bool isFrom) {
    return Column(
      children: [
        DropdownButtonFormField<Unit>(
          value: isFrom ? _fromUnit : _toUnit,
          items: _selectedCategory.units.map((unit) {
            return DropdownMenuItem(
              value: unit,
              child: Text(unit.name),
            );
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
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: isFrom ? _fromController : _toController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            _performConversion(value, fromTo: isFrom);
          },
        ),
      ],
    );
  }
} 