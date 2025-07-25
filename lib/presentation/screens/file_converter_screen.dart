import 'package:flutter/material.dart';
import 'package:yaml/yaml.dart';
import 'dart:convert';

class FileConverterScreen extends StatefulWidget {
  const FileConverterScreen({super.key});

  @override
  _FileConverterScreenState createState() => _FileConverterScreenState();
}

class _FileConverterScreenState extends State<FileConverterScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();

  void _convertJsonToYaml() {
    try {
      final dynamic jsonData = json.decode(_inputController.text);
      // This is a simplified conversion. For complex cases, a dedicated library would be better.
      // We manually build a YAML-like string.
      _outputController.text = _toYamlString(jsonData);
    } catch (e) {
      _outputController.text = 'JSON invalide: $e';
    }
  }

  String _toYamlString(dynamic jsonData, {int indent = 0}) {
    String yaml = '';
    String indentStr = '  ' * indent;
    if (jsonData is Map) {
      for (var key in jsonData.keys) {
        yaml += '$indentStr$key:\n';
        yaml += _toYamlString(jsonData[key], indent: indent + 1);
      }
    } else if (jsonData is List) {
      for (var item in jsonData) {
        yaml += '$indentStr- ';
        var itemYaml = _toYamlString(item, indent: indent + 1);
        if (item is Map || item is List) {
            yaml += '\n' + itemYaml;
        } else {
            yaml += itemYaml + '\n';
        }
      }
    } else {
      yaml = '$indentStr$jsonData\n';
    }
    return yaml;
  }

  void _convertYamlToJson() {
    try {
      final dynamic yamlData = loadYaml(_inputController.text);
      const jsonEncoder = JsonEncoder.withIndent('  ');
      _outputController.text = jsonEncoder.convert(yamlData);
    } catch (e) {
      _outputController.text = 'YAML invalide: $e';
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Convertisseur JSON/YAML')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  labelText: 'Entrée (JSON ou YAML)',
                  hintText: 'Collez votre contenu ici...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _convertJsonToYaml, 
                  icon: const Icon(Icons.arrow_downward),
                  label: const Text('JSON -> YAML')
                ),
                ElevatedButton.icon(
                  onPressed: _convertYamlToJson, 
                  icon: const Icon(Icons.arrow_upward),
                  label: const Text('YAML -> JSON')
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _outputController,
                readOnly: true,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  labelText: 'Sortie',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 