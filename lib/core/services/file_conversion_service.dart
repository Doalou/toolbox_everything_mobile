import 'dart:convert';
import 'package:yaml/yaml.dart';

class FileConversionService {
  const FileConversionService();

  String jsonToYaml(String jsonText) {
    try {
      final dynamic jsonData = json.decode(jsonText);
      return _toYamlString(jsonData).trimRight();
    } catch (e) {
      throw FormatException('JSON invalide : $e');
    }
  }

  String _toYamlString(dynamic data, {int indent = 0}) {
    final indentStr = '  ' * indent;
    final buffer = StringBuffer();

    if (data is Map) {
      if (data.isEmpty) return '$indentStr{}\n';
      for (final entry in data.entries) {
        final key = _formatYamlKey(entry.key.toString());
        final value = entry.value;
        if (value is Map) {
          if (value.isEmpty) {
            buffer.writeln('$indentStr$key: {}');
          } else {
            buffer.writeln('$indentStr$key:');
            buffer.write(_toYamlString(value, indent: indent + 1));
          }
        } else if (value is List) {
          if (value.isEmpty) {
            buffer.writeln('$indentStr$key: []');
          } else {
            buffer.writeln('$indentStr$key:');
            buffer.write(_toYamlString(value, indent: indent + 1));
          }
        } else {
          buffer.writeln('$indentStr$key: ${_formatYamlScalar(value)}');
        }
      }
    } else if (data is List) {
      if (data.isEmpty) return '$indentStr[]\n';
      for (final item in data) {
        if (item is Map || item is List) {
          buffer.writeln('$indentStr-');
          buffer.write(_toYamlString(item, indent: indent + 1));
        } else {
          buffer.writeln('$indentStr- ${_formatYamlScalar(item)}');
        }
      }
    } else {
      buffer.writeln('$indentStr${_formatYamlScalar(data)}');
    }

    return buffer.toString();
  }

  String _formatYamlKey(String key) {
    if (key.isEmpty ||
        key.contains(':') ||
        key.contains('#') ||
        key.contains('\n') ||
        key.trim() != key) {
      return json.encode(key);
    }
    return key;
  }

  String _formatYamlScalar(dynamic value) {
    if (value == null) return 'null';
    if (value is bool || value is num) return value.toString();
    final str = value.toString();
    if (str.isEmpty) return '""';
    final needsQuotes =
        str.contains(':') ||
        str.contains('#') ||
        str.contains('\n') ||
        str.contains('\r') ||
        str.contains('"') ||
        str.contains("'") ||
        str.startsWith(' ') ||
        str.endsWith(' ') ||
        str.startsWith('-') ||
        str.startsWith('[') ||
        str.startsWith('{') ||
        const {
          'true',
          'false',
          'null',
          'yes',
          'no',
        }.contains(str.toLowerCase()) ||
        num.tryParse(str) != null;
    return needsQuotes ? json.encode(str) : str;
  }

  String yamlToJson(String yamlText) {
    try {
      final dynamic yamlData = loadYaml(yamlText);
      const jsonEncoder = JsonEncoder.withIndent('  ');
      return jsonEncoder.convert(_normalizeYamlNode(yamlData));
    } catch (e) {
      throw FormatException('YAML invalide : $e');
    }
  }

  dynamic _normalizeYamlNode(dynamic node) {
    if (node is YamlMap) {
      return {
        for (final entry in node.entries)
          entry.key.toString(): _normalizeYamlNode(entry.value),
      };
    }
    if (node is YamlList) {
      return node.map(_normalizeYamlNode).toList();
    }
    return node;
  }

  String csvToJson(String csvText) {
    final rows = parseCsv(csvText);
    if (rows.isEmpty) {
      throw const FormatException('CSV vide');
    }

    final headers = rows.first.map((e) => e.trim()).toList();
    final jsonArray = <Map<String, String>>[];

    for (var i = 1; i < rows.length; i++) {
      final values = rows[i];
      if (values.length == 1 && values.first.trim().isEmpty) continue;
      final jsonObject = <String, String>{};
      for (var j = 0; j < headers.length; j++) {
        jsonObject[headers[j]] = j < values.length ? values[j] : '';
      }
      jsonArray.add(jsonObject);
    }

    const jsonEncoder = JsonEncoder.withIndent('  ');
    return jsonEncoder.convert(jsonArray);
  }

  /// Parseur CSV conforme RFC 4180 (gère les champs entre guillemets contenant
  /// des virgules, des guillemets doublés `""` et des retours à la ligne).
  List<List<String>> parseCsv(String input) {
    final text = input.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
    if (text.isEmpty) return const [];

    final rows = <List<String>>[];
    var currentRow = <String>[];
    final currentField = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < text.length; i++) {
      final char = text[i];
      if (inQuotes) {
        if (char == '"') {
          if (i + 1 < text.length && text[i + 1] == '"') {
            currentField.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          currentField.write(char);
        }
      } else {
        if (char == '"') {
          inQuotes = true;
        } else if (char == ',') {
          currentRow.add(currentField.toString());
          currentField.clear();
        } else if (char == '\n') {
          currentRow.add(currentField.toString());
          currentField.clear();
          rows.add(currentRow);
          currentRow = <String>[];
        } else {
          currentField.write(char);
        }
      }
    }

    currentRow.add(currentField.toString());
    if (currentRow.isNotEmpty) {
      rows.add(currentRow);
    }
    return rows;
  }

  String jsonToCsv(String jsonText) {
    final dynamic jsonData;
    try {
      jsonData = json.decode(jsonText);
    } catch (e) {
      throw FormatException('JSON invalide : $e');
    }

    if (jsonData is! List) {
      throw const FormatException(
        'Le JSON doit être un tableau d\'objets pour la conversion CSV',
      );
    }

    if (jsonData.isEmpty) return '';

    final firstObject = jsonData.first;
    if (firstObject is! Map) {
      throw const FormatException(
        'Les éléments du tableau doivent être des objets JSON',
      );
    }

    final headers = <String>{
      for (final item in jsonData)
        if (item is Map) ...item.keys.map((k) => k.toString()),
    }.toList();

    final csvLines = <String>[headers.map(_escapeCsvField).join(',')];

    for (final item in jsonData) {
      if (item is Map) {
        final values = headers
            .map((header) => _escapeCsvField(item[header]?.toString() ?? ''))
            .toList();
        csvLines.add(values.join(','));
      }
    }

    return csvLines.join('\n');
  }

  String _escapeCsvField(String value) {
    if (value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  String markdownToHtml(String markdownText) {
    final html = markdownText
        .replaceAllMapped(
          RegExp(r'^### (.+)$', multiLine: true),
          (match) => '<h3>${match.group(1)}</h3>',
        )
        .replaceAllMapped(
          RegExp(r'^## (.+)$', multiLine: true),
          (match) => '<h2>${match.group(1)}</h2>',
        )
        .replaceAllMapped(
          RegExp(r'^# (.+)$', multiLine: true),
          (match) => '<h1>${match.group(1)}</h1>',
        )
        .replaceAllMapped(
          RegExp(r'\*\*(.+?)\*\*'),
          (match) => '<strong>${match.group(1)}</strong>',
        )
        .replaceAllMapped(
          RegExp(r'\*(.+?)\*'),
          (match) => '<em>${match.group(1)}</em>',
        )
        .replaceAllMapped(
          RegExp(r'`(.+?)`'),
          (match) => '<code>${match.group(1)}</code>',
        )
        .replaceAllMapped(
          RegExp(r'\[(.+?)\]\((.+?)\)'),
          (match) => '<a href="${match.group(2)}">${match.group(1)}</a>',
        );

    return '''<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Document converti</title>
  <style>
    body { font-family: system-ui, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; line-height: 1.6; }
    code { background: #f4f4f6; padding: 2px 6px; border-radius: 4px; }
    a { color: #2544D8; }
  </style>
</head>
<body>
$html
</body>
</html>''';
  }

  String htmlToMarkdown(String htmlText) {
    return htmlText
        .replaceAllMapped(
          RegExp(r'<h1[^>]*>(.+?)</h1>', dotAll: true),
          (match) => '# ${match.group(1)?.trim()}\n',
        )
        .replaceAllMapped(
          RegExp(r'<h2[^>]*>(.+?)</h2>', dotAll: true),
          (match) => '## ${match.group(1)?.trim()}\n',
        )
        .replaceAllMapped(
          RegExp(r'<h3[^>]*>(.+?)</h3>', dotAll: true),
          (match) => '### ${match.group(1)?.trim()}\n',
        )
        .replaceAllMapped(
          RegExp(r'<strong[^>]*>(.+?)</strong>', dotAll: true),
          (match) => '**${match.group(1)}**',
        )
        .replaceAllMapped(
          RegExp(r'<em[^>]*>(.+?)</em>', dotAll: true),
          (match) => '*${match.group(1)}*',
        )
        .replaceAllMapped(
          RegExp(r'<code[^>]*>(.+?)</code>', dotAll: true),
          (match) => '`${match.group(1)}`',
        )
        .replaceAllMapped(
          RegExp(r'<a[^>]*href="([^"]*)"[^>]*>(.+?)</a>', dotAll: true),
          (match) => '[${match.group(2)}](${match.group(1)})',
        )
        .replaceAll(RegExp(r'<style[^>]*>.*?</style>', dotAll: true), '')
        .replaceAll(RegExp(r'<head[^>]*>.*?</head>', dotAll: true), '')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n')
        .trim();
  }
}
