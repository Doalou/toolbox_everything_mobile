import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_shapes.dart';
import 'package:toolbox_everything_mobile/core/feature_flags/app_feature_flags.dart';
import 'package:toolbox_everything_mobile/core/services/app_feedback.dart';
import 'package:toolbox_everything_mobile/core/services/file_conversion_service.dart';
import 'package:toolbox_everything_mobile/core/services/haptics_service.dart';
import 'package:toolbox_everything_mobile/shared/widgets/editorial_tool_components.dart';
import 'package:toolbox_everything_mobile/shared/widgets/editorial_tool_scaffold.dart';
import 'package:toolbox_everything_mobile/shared/widgets/expressive_action_button.dart';
import 'package:toolbox_everything_mobile/shared/widgets/expressive_card.dart';

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
  final String heroTag;

  const FileConverterScreen({super.key, required this.heroTag});

  @override
  FileConverterScreenState createState() => FileConverterScreenState();
}

class FileConverterScreenState extends State<FileConverterScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  final FileConversionService _conversionService =
      const FileConversionService();

  ConversionType _selectedConversion = ConversionType.jsonToYaml;
  bool _isConverting = false;
  String? _lastConvertedFile;

  List<ConversionType> get _availableConversions => [
    ConversionType.jsonToYaml,
    ConversionType.yamlToJson,
    ConversionType.csvToJson,
    ConversionType.jsonToCsv,
    ConversionType.markdownToHtml,
    ConversionType.htmlToMarkdown,
    if (AppFeatureFlags.pdfExport) ...[
      ConversionType.textToPdf,
      ConversionType.csvToPdf,
    ],
  ];

  @override
  void dispose() {
    _inputController.dispose();
    _outputController.dispose();
    super.dispose();
  }

  Future<void> _performConversion() async {
    final rawInput = _inputController.text;
    if (rawInput.trim().isEmpty) return;

    setState(() {
      _isConverting = true;
    });

    try {
      String result = '';

      switch (_selectedConversion) {
        case ConversionType.jsonToYaml:
          result = _conversionService.jsonToYaml(rawInput);
        case ConversionType.yamlToJson:
          result = _conversionService.yamlToJson(rawInput);
        case ConversionType.csvToJson:
          result = _conversionService.csvToJson(rawInput);
        case ConversionType.jsonToCsv:
          result = _conversionService.jsonToCsv(rawInput);
        case ConversionType.markdownToHtml:
          result = _conversionService.markdownToHtml(rawInput);
        case ConversionType.htmlToMarkdown:
          result = _conversionService.htmlToMarkdown(rawInput);
        case ConversionType.textToPdf:
          await _convertTextToPdf(rawInput);
          result = 'PDF généré avec succès !';
        case ConversionType.csvToPdf:
          await _convertCsvToPdf(rawInput);
          result = 'PDF généré avec succès !';
      }

      if (!mounted) return;
      setState(() {
        _outputController.text = result;
        _isConverting = false;
      });

      AppFeedback.show(
        context,
        'Conversion réussie !',
        tone: FeedbackTone.success,
      );
    } on FormatException catch (e) {
      if (!mounted) return;
      setState(() {
        _outputController.text = 'Erreur : ${e.message}';
        _isConverting = false;
      });
      AppFeedback.show(context, e.message, tone: FeedbackTone.error);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _outputController.text = 'Erreur de conversion : $e';
        _isConverting = false;
      });
      AppFeedback.show(context, 'Erreur : $e', tone: FeedbackTone.error);
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
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      throw FormatException('Erreur de génération PDF : $e');
    }
  }

  Future<void> _convertCsvToPdf(String csvText) async {
    try {
      final rows = _conversionService.parseCsv(csvText);
      if (rows.isEmpty) throw const FormatException('CSV vide');

      final headers = rows.first.map((e) => e.trim()).toList();
      final data = rows.skip(1).toList();

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

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      throw FormatException('Erreur de génération PDF depuis CSV : $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'json', 'yaml', 'yml', 'csv', 'md', 'html'],
      );

      if (result.isNotEmpty && result.single.path != null) {
        final file = File(result.single.path!);
        final content = await file.readAsString();

        if (!mounted) return;
        setState(() {
          _inputController.text = content;
          _lastConvertedFile = result.single.name;
        });

        AppFeedback.show(
          context,
          'Fichier chargé : ${result.single.name}',
          tone: FeedbackTone.success,
          icon: Icons.upload_file_rounded,
        );
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.show(
          context,
          'Erreur lors du chargement : $e',
          tone: FeedbackTone.error,
        );
      }
    }
  }

  void _copyOutput() {
    if (_outputController.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _outputController.text));
      AppFeedback.copied(context, 'Résultat copié !');
    }
  }

  void _clearAll() {
    HapticsService.perform(context, HapticType.light);
    _inputController.clear();
    _outputController.clear();
    setState(() {
      _lastConvertedFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return EditorialToolScaffold(
      title: 'Convertisseur de fichiers',
      heroTag: widget.heroTag,
      actions: [
        IconButton(
          onPressed: _clearAll,
          icon: Icon(Icons.clear_all_rounded, color: colorScheme.primary),
          tooltip: 'Effacer tout',
        ),
      ],
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const EditorialToolIntro(
              icon: Icons.transform_rounded,
              title: 'Convertir un fichier',
              description: 'JSON, YAML, CSV, Markdown, HTML et export PDF.',
            ),
            const SizedBox(height: 16),
            _buildConversionSelector(),
            const SizedBox(height: 16),
            _buildInputSection(),
            const SizedBox(height: 16),
            ExpressiveActionButton.iconLabel(
              icon: Icons.transform_rounded,
              label: _isConverting ? 'Conversion…' : 'Convertir maintenant',
              loading: _isConverting,
              onPressed: _isConverting ? null : _performConversion,
            ),
            if (_outputController.text.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildOutputSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConversionSelector() {
    final colorScheme = Theme.of(context).colorScheme;

    return ExpressiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.swap_horiz_rounded,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Format de conversion',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableConversions.map((type) {
              final isSelected = _selectedConversion == type;
              return ChoiceChip(
                avatar: Icon(
                  _getConversionIcon(type),
                  size: 16,
                  color: isSelected
                      ? colorScheme.onSecondaryContainer
                      : colorScheme.primary,
                ),
                label: Text(_getConversionName(type)),
                selected: isSelected,
                onSelected: (_) {
                  HapticsService.perform(context, HapticType.selection);
                  setState(() {
                    _selectedConversion = type;
                    _outputController.clear();
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    final colorScheme = Theme.of(context).colorScheme;

    return ExpressiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.input_rounded, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _lastConvertedFile != null
                      ? 'Fichier : $_lastConvertedFile'
                      : 'Données d’entrée',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: _pickFile,
                icon: const Icon(Icons.upload_file_rounded, size: 18),
                label: const Text('Importer'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _inputController,
            minLines: 7,
            maxLines: 14,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
            decoration: InputDecoration(
              hintText: _getInputHint(_selectedConversion),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutputSection() {
    final colorScheme = Theme.of(context).colorScheme;

    return ExpressiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.output_rounded, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Résultat de la conversion',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton.filledTonal(
                onPressed: _copyOutput,
                icon: const Icon(Icons.content_copy_rounded, size: 18),
                tooltip: 'Copier',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(ExpressiveShapes.large),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: SelectableText(
              _outputController.text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getConversionName(ConversionType type) => switch (type) {
    ConversionType.jsonToYaml => 'JSON → YAML',
    ConversionType.yamlToJson => 'YAML → JSON',
    ConversionType.csvToJson => 'CSV → JSON',
    ConversionType.jsonToCsv => 'JSON → CSV',
    ConversionType.markdownToHtml => 'MD → HTML',
    ConversionType.htmlToMarkdown => 'HTML → MD',
    ConversionType.textToPdf => 'Texte → PDF',
    ConversionType.csvToPdf => 'CSV → PDF',
  };

  IconData _getConversionIcon(ConversionType type) => switch (type) {
    ConversionType.jsonToYaml ||
    ConversionType.yamlToJson => Icons.data_object_rounded,
    ConversionType.csvToJson ||
    ConversionType.jsonToCsv => Icons.table_chart_rounded,
    ConversionType.markdownToHtml ||
    ConversionType.htmlToMarkdown => Icons.code_rounded,
    ConversionType.textToPdf ||
    ConversionType.csvToPdf => Icons.picture_as_pdf_rounded,
  };

  String _getInputHint(ConversionType type) => switch (type) {
    ConversionType.jsonToYaml => '{\n  "nom": "Jean",\n  "age": 30\n}',
    ConversionType.yamlToJson => 'nom: Jean\nage: 30\nville: Paris',
    ConversionType.csvToJson => 'nom,age,ville\n"Jean, Jr.",30,Paris',
    ConversionType.jsonToCsv => '[\n  {"nom": "Jean", "age": "30"}\n]',
    ConversionType.markdownToHtml => '# Titre\n\nTexte en **gras**.',
    ConversionType.htmlToMarkdown => '<h1>Titre</h1>\n<p>Texte</p>',
    ConversionType.textToPdf => 'Saisissez votre texte à exporter en PDF…',
    ConversionType.csvToPdf => 'nom,age,ville\nJean,30,Paris',
  };
}
