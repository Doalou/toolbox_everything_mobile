import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:yaml/yaml.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:convert';
import 'dart:io';

enum ConversionType {
  jsonToYaml,
  yamlToJson,
  csvToJson,
  jsonToCsv,
  markdownToHtml,
  htmlToMarkdown,
  textToPdf,
  csvToPdf,
}

class FileConverterScreen extends StatefulWidget {
  const FileConverterScreen({super.key});

  @override
  FileConverterScreenState createState() => FileConverterScreenState();
}

class FileConverterScreenState extends State<FileConverterScreen>
    with TickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();

  late AnimationController _convertController;
  late Animation<double> _convertAnimation;
  
  ConversionType _selectedConversion = ConversionType.jsonToYaml;
  bool _isConverting = false;
  String? _lastConvertedFile;

  @override
  void initState() {
    super.initState();
    
    _convertController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _convertAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _convertController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _convertController.dispose();
    _inputController.dispose();
    _outputController.dispose();
    super.dispose();
  }

  Future<void> _performConversion() async {
    if (_inputController.text.trim().isEmpty) return;

    setState(() {
      _isConverting = true;
    });

    _convertController.forward();

    try {
      String result = '';
      
      switch (_selectedConversion) {
        case ConversionType.jsonToYaml:
          result = _convertJsonToYaml(_inputController.text);
          break;
        case ConversionType.yamlToJson:
          result = _convertYamlToJson(_inputController.text);
          break;
        case ConversionType.csvToJson:
          result = _convertCsvToJson(_inputController.text);
          break;
        case ConversionType.jsonToCsv:
          result = _convertJsonToCsv(_inputController.text);
          break;
        case ConversionType.markdownToHtml:
          result = _convertMarkdownToHtml(_inputController.text);
          break;
        case ConversionType.htmlToMarkdown:
          result = _convertHtmlToMarkdown(_inputController.text);
          break;
        case ConversionType.textToPdf:
          await _convertTextToPdf(_inputController.text);
          result = 'PDF généré avec succès !';
          break;
        case ConversionType.csvToPdf:
          await _convertCsvToPdf(_inputController.text);
          result = 'PDF généré avec succès !';
          break;
      }

      setState(() {
        _outputController.text = result;
        _isConverting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text('Conversion réussie !'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _outputController.text = 'Erreur de conversion: $e';
        _isConverting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Erreur: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    _convertController.reverse();
  }

  String _convertJsonToYaml(String jsonText) {
    try {
      final dynamic jsonData = json.decode(jsonText);
      return _toYamlString(jsonData);
    } catch (e) {
      throw 'JSON invalide: $e';
    }
  }

  String _toYamlString(dynamic data, {int indent = 0}) {
    String yaml = '';
    String indentStr = '  ' * indent;
    
    if (data is Map) {
      for (var key in data.keys) {
        if (data[key] is Map || data[key] is List) {
        yaml += '$indentStr$key:\n';
          yaml += _toYamlString(data[key], indent: indent + 1);
        } else {
          yaml += '$indentStr$key: ${data[key]}\n';
        }
      }
    } else if (data is List) {
      for (var item in data) {
        if (item is Map || item is List) {
          yaml += '$indentStr-\n';
          yaml += _toYamlString(item, indent: indent + 1);
        } else {
          yaml += '$indentStr- $item\n';
        }
      }
    }
    
    return yaml;
  }

  String _convertYamlToJson(String yamlText) {
    try {
      final dynamic yamlData = loadYaml(yamlText);
      const jsonEncoder = JsonEncoder.withIndent('  ');
      return jsonEncoder.convert(yamlData);
    } catch (e) {
      throw 'YAML invalide: $e';
    }
  }

  String _convertCsvToJson(String csvText) {
    try {
      final lines = csvText.trim().split('\n');
      if (lines.isEmpty) throw 'CSV vide';
      
      final headers = lines[0].split(',').map((e) => e.trim()).toList();
      final jsonArray = <Map<String, String>>[];
      
      for (int i = 1; i < lines.length; i++) {
        final values = lines[i].split(',').map((e) => e.trim()).toList();
        final jsonObject = <String, String>{};
        
        for (int j = 0; j < headers.length && j < values.length; j++) {
          jsonObject[headers[j]] = values[j];
        }
        
        jsonArray.add(jsonObject);
      }
      
      const jsonEncoder = JsonEncoder.withIndent('  ');
      return jsonEncoder.convert(jsonArray);
    } catch (e) {
      throw 'CSV invalide: $e';
    }
  }

  String _convertJsonToCsv(String jsonText) {
    try {
      final dynamic jsonData = json.decode(jsonText);
      
      if (jsonData is! List) {
        throw 'Le JSON doit être un tableau d\'objets pour la conversion CSV';
      }
      
      if (jsonData.isEmpty) return '';
      
      final firstObject = jsonData[0];
      if (firstObject is! Map) {
        throw 'Les éléments du tableau doivent être des objets';
      }
      
      final headers = firstObject.keys.toList();
      final csvLines = <String>[];
      
      // En-têtes
      csvLines.add(headers.join(','));
      
      // Données
      for (final item in jsonData) {
        if (item is Map) {
          final values = headers.map((header) => item[header]?.toString() ?? '').toList();
          csvLines.add(values.join(','));
        }
      }
      
      return csvLines.join('\n');
    } catch (e) {
      throw 'Erreur de conversion JSON vers CSV: $e';
    }
  }

  String _convertMarkdownToHtml(String markdownText) {
    try {
      // Conversion basique Markdown vers HTML
      String html = markdownText
          .replaceAllMapped(RegExp(r'^# (.+)$', multiLine: true), (match) => '<h1>${match.group(1)}</h1>')
          .replaceAllMapped(RegExp(r'^## (.+)$', multiLine: true), (match) => '<h2>${match.group(1)}</h2>')
          .replaceAllMapped(RegExp(r'^### (.+)$', multiLine: true), (match) => '<h3>${match.group(1)}</h3>')
          .replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (match) => '<strong>${match.group(1)}</strong>')
          .replaceAllMapped(RegExp(r'\*(.+?)\*'), (match) => '<em>${match.group(1)}</em>')
          .replaceAllMapped(RegExp(r'`(.+?)`'), (match) => '<code>${match.group(1)}</code>')
          .replaceAllMapped(RegExp(r'\[(.+?)\]\((.+?)\)'), (match) => '<a href="${match.group(2)}">${match.group(1)}</a>');
      
      // Ajouter structure HTML de base
      return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Document converti</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
        h1, h2, h3 { color: #333; }
        code { background: #f5f5f5; padding: 2px 4px; border-radius: 3px; }
        a { color: #007bff; }
    </style>
</head>
<body>
$html
</body>
</html>
      ''';
    } catch (e) {
      throw 'Erreur de conversion Markdown vers HTML: $e';
    }
  }

  String _convertHtmlToMarkdown(String htmlText) {
    try {
      // Conversion basique HTML vers Markdown
      return htmlText
          .replaceAllMapped(RegExp(r'<h1[^>]*>(.+?)</h1>'), (match) => '# ${match.group(1)}\n')
          .replaceAllMapped(RegExp(r'<h2[^>]*>(.+?)</h2>'), (match) => '## ${match.group(1)}\n')
          .replaceAllMapped(RegExp(r'<h3[^>]*>(.+?)</h3>'), (match) => '### ${match.group(1)}\n')
          .replaceAllMapped(RegExp(r'<strong[^>]*>(.+?)</strong>'), (match) => '**${match.group(1)}**')
          .replaceAllMapped(RegExp(r'<em[^>]*>(.+?)</em>'), (match) => '*${match.group(1)}*')
          .replaceAllMapped(RegExp(r'<code[^>]*>(.+?)</code>'), (match) => '`${match.group(1)}`')
          .replaceAllMapped(RegExp(r'<a[^>]*href="([^"]*)"[^>]*>(.+?)</a>'), (match) => '[${match.group(2)}](${match.group(1)})')
          .replaceAll(RegExp(r'<[^>]+>'), '') // Supprimer les autres balises HTML
          .replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n'); // Nettoyer les lignes vides
    } catch (e) {
      throw 'Erreur de conversion HTML vers Markdown: $e';
    }
  }

  Future<void> _convertTextToPdf(String text) async {
    try {
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Document converti',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Paragraph(
                text: text,
                style: const pw.TextStyle(fontSize: 12, lineSpacing: 1.4),
              ),
              pw.Spacer(),
              pw.Text(
                'Généré le ${DateTime.now().toString().split('.')[0]}',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            ];
          },
        ),
      );
      
      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
    } catch (e) {
      throw 'Erreur de génération PDF: $e';
    }
  }

  Future<void> _convertCsvToPdf(String csvText) async {
    try {
      final lines = csvText.trim().split('\n');
      if (lines.isEmpty) throw 'CSV vide';
      
      final headers = lines[0].split(',').map((e) => e.trim()).toList();
      final data = <List<String>>[];
      
      for (int i = 1; i < lines.length; i++) {
        data.add(lines[i].split(',').map((e) => e.trim()).toList());
      }
      
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Tableau CSV',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.TableHelper.fromTextArray(
                headers: headers,
                data: data,
                cellStyle: const pw.TextStyle(fontSize: 10),
                headerStyle: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
                border: pw.TableBorder.all(),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
              ),
            ];
          },
        ),
      );
      
      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
    } catch (e) {
      throw 'Erreur de génération PDF depuis CSV: $e';
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'json', 'yaml', 'yml', 'csv', 'md', 'html'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        
        setState(() {
          _inputController.text = content;
          _lastConvertedFile = result.files.single.name;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fichier chargé: ${result.files.single.name}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _copyOutput() {
    if (_outputController.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _outputController.text));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.content_copy, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Résultat copié !'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _clearAll() {
    _inputController.clear();
    _outputController.clear();
    setState(() {
      _lastConvertedFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Convertisseur de fichiers'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          FadeInRight(
            delay: const Duration(milliseconds: 300),
            child: IconButton(
              onPressed: _clearAll,
              icon: Icon(
                Icons.clear_all,
                color: colorScheme.primary,
              ),
              tooltip: 'Effacer tout',
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header moderne
            FadeInDown(
              delay: const Duration(milliseconds: 200),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.transform,
                      size: 48,
                      color: const Color(0xFF673AB7),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Convertisseur de fichiers',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Convertissez entre différents formats de fichiers',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Sélecteur de type de conversion
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: _buildConversionSelector(),
            ),

            const SizedBox(height: 24),

            // Zone d'entrée
            FadeInUp(
              delay: const Duration(milliseconds: 500),
              child: _buildInputSection(),
            ),

            const SizedBox(height: 24),

            // Bouton de conversion
            FadeInUp(
              delay: const Duration(milliseconds: 600),
              child: _buildConvertButton(),
            ),

            const SizedBox(height: 24),

            // Zone de sortie
            if (_outputController.text.isNotEmpty)
              FadeInUp(
                delay: const Duration(milliseconds: 700),
                child: _buildOutputSection(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversionSelector() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
                children: [
              Icon(
                Icons.swap_horiz,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Type de conversion',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ConversionType.values.map((type) {
              final isSelected = _selectedConversion == type;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedConversion = type;
                    _outputController.clear();
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                    child: Row(
                    mainAxisSize: MainAxisSize.min,
                      children: [
                      Icon(
                        _getConversionIcon(type),
                        size: 16,
                        color: isSelected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getConversionName(type),
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurface,
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

  Widget _buildInputSection() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.input,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _lastConvertedFile != null 
                        ? 'Fichier: $_lastConvertedFile'
                        : 'Données d\'entrée',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _pickFile,
                  icon: Icon(
                    Icons.file_upload,
                    color: colorScheme.primary,
                  ),
                  tooltip: 'Charger un fichier',
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: TextField(
              controller: _inputController,
                    maxLines: null,
                    expands: true,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
              ),
              decoration: InputDecoration(
                hintText: _getInputHint(_selectedConversion),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConvertButton() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return AnimatedBuilder(
      animation: _convertAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 1 + (_convertAnimation.value * 0.05),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isConverting ? null : _performConversion,
              icon: _isConverting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.transform, size: 20),
              label: Text(
                _isConverting ? 'Conversion...' : 'Convertir',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF673AB7),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOutputSection() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.output,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Résultat de la conversion',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _copyOutput,
                  icon: Icon(
                    Icons.content_copy,
                    color: colorScheme.primary,
                  ),
                  tooltip: 'Copier',
                  ),
                ],
              ),
            ),
          SizedBox(
            height: 200,
            child: TextField(
              controller: _outputController,
              maxLines: null,
              expands: true,
              readOnly: true,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getConversionIcon(ConversionType type) {
    switch (type) {
      case ConversionType.jsonToYaml:
      case ConversionType.yamlToJson:
        return Icons.code;
      case ConversionType.csvToJson:
      case ConversionType.jsonToCsv:
        return Icons.table_chart;
      case ConversionType.markdownToHtml:
      case ConversionType.htmlToMarkdown:
        return Icons.web;
      case ConversionType.textToPdf:
      case ConversionType.csvToPdf:
        return Icons.picture_as_pdf;
    }
  }

  String _getConversionName(ConversionType type) {
    switch (type) {
      case ConversionType.jsonToYaml:
        return 'JSON → YAML';
      case ConversionType.yamlToJson:
        return 'YAML → JSON';
      case ConversionType.csvToJson:
        return 'CSV → JSON';
      case ConversionType.jsonToCsv:
        return 'JSON → CSV';
      case ConversionType.markdownToHtml:
        return 'Markdown → HTML';
      case ConversionType.htmlToMarkdown:
        return 'HTML → Markdown';
      case ConversionType.textToPdf:
        return 'Texte → PDF';
      case ConversionType.csvToPdf:
        return 'CSV → PDF';
    }
  }

  String _getInputHint(ConversionType type) {
    switch (type) {
      case ConversionType.jsonToYaml:
        return '{"nom": "exemple", "valeur": 123}';
      case ConversionType.yamlToJson:
        return 'nom: exemple\nvaleur: 123';
      case ConversionType.csvToJson:
        return 'nom,age,ville\nJean,30,Paris\nMarie,25,Lyon';
      case ConversionType.jsonToCsv:
        return '[{"nom": "Jean", "age": 30}, {"nom": "Marie", "age": 25}]';
      case ConversionType.markdownToHtml:
        return '# Titre\n\n**Texte en gras** et *italique*';
      case ConversionType.htmlToMarkdown:
        return '<h1>Titre</h1>\n<p><strong>Texte en gras</strong></p>';
      case ConversionType.textToPdf:
        return 'Entrez votre texte à convertir en PDF...';
      case ConversionType.csvToPdf:
        return 'nom,age,ville\nJean,30,Paris\nMarie,25,Lyon';
    }
  }
} 