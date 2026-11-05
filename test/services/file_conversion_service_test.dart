import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:toolbox_everything_mobile/core/services/file_conversion_service.dart';

void main() {
  const service = FileConversionService();

  group('FileConversionService', () {
    test('JSON -> YAML escapes special strings and preserves primitives', () {
      const jsonInput = '''
{
  "name": "Toolbox: Expressive",
  "tag": "#material3",
  "active": true,
  "count": 42,
  "items": ["alpha", "beta:1"]
}
''';

      final yamlOutput = service.jsonToYaml(jsonInput);

      expect(yamlOutput, contains('name: "Toolbox: Expressive"'));
      expect(yamlOutput, contains('tag: "#material3"'));
      expect(yamlOutput, contains('active: true'));
      expect(yamlOutput, contains('count: 42'));
      expect(yamlOutput, contains('- "beta:1"'));
    });

    test('YAML -> JSON parses nested structures', () {
      const yamlInput = '''
app: Toolbox
version: 4
features:
  - m3e
  - offline
''';

      final jsonOutput = service.yamlToJson(yamlInput);
      final decoded = jsonDecode(jsonOutput) as Map<String, dynamic>;

      expect(decoded['app'], 'Toolbox');
      expect(decoded['version'], 4);
      expect(decoded['features'], ['m3e', 'offline']);
    });

    test('CSV -> JSON handles RFC 4180 quoted commas and escaped quotes', () {
      const csvInput =
          'name,description,score\n'
          'Alice,"Bonjour, ""monde""",95\n'
          'Bob,Simple,80';

      final jsonOutput = service.csvToJson(csvInput);
      final decoded = jsonDecode(jsonOutput) as List<dynamic>;

      expect(decoded, hasLength(2));
      expect(decoded[0]['name'], 'Alice');
      expect(decoded[0]['description'], 'Bonjour, "monde"');
      expect(decoded[0]['score'], '95');
      expect(decoded[1]['name'], 'Bob');
    });

    test('JSON -> CSV quotes cells containing commas or quotes', () {
      const jsonInput = '''
[
  {"city": "Paris, FR", "note": "C'est \\"super\\""},
  {"city": "Lyon", "note": "OK"}
]
''';

      final csvOutput = service.jsonToCsv(jsonInput);

      final lines = csvOutput.trim().split('\n');
      expect(lines[0], 'city,note');
      expect(lines[1], '"Paris, FR","C\'est ""super"""');
      expect(lines[2], 'Lyon,OK');
    });

    test('Markdown <-> HTML round-trip basic elements', () {
      const md = '# Titre\n\nTexte avec **gras** et *italique*.';
      final html = service.markdownToHtml(md);

      expect(html, contains('<h1>Titre</h1>'));
      expect(html, contains('<strong>gras</strong>'));
      expect(html, contains('<em>italique</em>'));

      final backToMd = service.htmlToMarkdown(html);
      expect(backToMd, contains('# Titre'));
      expect(backToMd, contains('**gras**'));
    });
  });
}
