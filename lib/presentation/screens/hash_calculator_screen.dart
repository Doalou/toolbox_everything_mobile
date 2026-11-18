import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:toolbox_everything_mobile/core/design/editorial_tokens.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_shapes.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_tokens.dart';
import 'package:toolbox_everything_mobile/core/services/app_feedback.dart';
import 'package:toolbox_everything_mobile/core/services/haptics_service.dart';
import 'package:toolbox_everything_mobile/core/services/hash_service.dart';
import 'package:toolbox_everything_mobile/shared/widgets/editorial_tool_components.dart';
import 'package:toolbox_everything_mobile/shared/widgets/editorial_tool_scaffold.dart';
import 'package:toolbox_everything_mobile/shared/widgets/expressive_action_button.dart';
import 'package:toolbox_everything_mobile/shared/widgets/expressive_card.dart';
import 'package:toolbox_everything_mobile/shared/widgets/status_badge.dart';

enum HashInputType { text, hex, file }

class HashCalculatorScreen extends StatefulWidget {
  final String heroTag;
  final String? initialText;
  final String? initialFilePath;

  const HashCalculatorScreen({
    super.key,
    required this.heroTag,
    this.initialText,
    this.initialFilePath,
  });

  @override
  State<HashCalculatorScreen> createState() => _HashCalculatorScreenState();
}

class _HashCalculatorScreenState extends State<HashCalculatorScreen> {
  final HashService _hashService = const HashService();
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _expectedController = TextEditingController();

  Map<HashAlgorithm, String> _hashes = const {};
  HashInputType _inputType = HashInputType.text;
  bool _uppercase = false;

  String? _selectedFileName;
  int? _selectedFileSize;
  bool _isHashingFile = false;
  double _fileProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_onInputChanged);
    if (widget.initialFilePath != null &&
        widget.initialFilePath!.trim().isNotEmpty) {
      _inputType = HashInputType.file;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _hashFilePath(widget.initialFilePath!);
        }
      });
    } else if (widget.initialText != null && widget.initialText!.isNotEmpty) {
      _inputController.text = widget.initialText!;
      _calculateHashesSync();
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _expectedController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    if (_inputType == HashInputType.file) return;
    if (_inputController.text.isNotEmpty) {
      _calculateHashesSync();
    } else {
      setState(() => _hashes = const {});
    }
  }

  void _calculateHashesSync() {
    if (_inputController.text.isEmpty) {
      setState(() => _hashes = const {});
      return;
    }

    try {
      final Map<HashAlgorithm, String> nextHashes;
      if (_inputType == HashInputType.text) {
        nextHashes = _hashService.hashUtf8(_inputController.text);
      } else {
        final cleanHex = _inputController.text
            .replaceAll(' ', '')
            .replaceAll('0x', '');
        if (cleanHex.isEmpty || cleanHex.length.isOdd) {
          setState(() => _hashes = const {});
          return;
        }
        final bytes = Uint8List.fromList(
          List.generate(
            cleanHex.length ~/ 2,
            (i) => int.parse(cleanHex.substring(i * 2, i * 2 + 2), radix: 16),
          ),
        );
        nextHashes = _hashService.hashBytes(bytes);
      }

      setState(() {
        _hashes = nextHashes;
      });
    } catch (e) {
      AppFeedback.show(
        context,
        'Erreur lors du calcul : $e',
        tone: FeedbackTone.error,
      );
    }
  }

  Future<void> _pickAndHashFile() async {
    try {
      final result = await FilePicker.pickFiles();
      if (result.isEmpty || result.single.path == null || !mounted) return;
      await _hashFilePath(result.single.path!, displayName: result.single.name);
    } catch (e) {
      if (mounted) {
        AppFeedback.show(
          context,
          'Impossible d’ouvrir le fichier : $e',
          tone: FeedbackTone.error,
        );
      }
    }
  }

  Future<void> _hashFilePath(String path, {String? displayName}) async {
    final file = File(path);
    final name =
        displayName ??
        path.split(RegExp(r'[/\\]')).lastWhere((s) => s.isNotEmpty);
    int? size;
    try {
      if (await file.exists()) {
        size = await file.length();
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _selectedFileName = name;
      _selectedFileSize = size;
      _isHashingFile = true;
      _fileProgress = 0.0;
      _hashes = const {};
    });

    try {
      final computed = await _hashService.hashFile(
        path,
        onProgress: (p) {
          if (mounted) {
            setState(() => _fileProgress = p);
          }
        },
      );
      if (!mounted) return;
      setState(() {
        _hashes = computed;
        _isHashingFile = false;
        _fileProgress = 1.0;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isHashingFile = false;
      });
      AppFeedback.show(
        context,
        'Erreur de lecture du fichier : $e',
        tone: FeedbackTone.error,
      );
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes o';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} Ko';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} Mo';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} Go';
  }

  String _displayValue(HashAlgorithm algo) {
    final raw = _hashes[algo] ?? '';
    return _uppercase ? raw.toUpperCase() : raw;
  }

  void _copyHash(HashAlgorithm algo) {
    final text = _displayValue(algo);
    if (text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: text));
      AppFeedback.copied(context, 'Hash ${algo.label} copié !');
    }
  }

  void _clearAll() {
    HapticsService.perform(context, HapticType.light);
    _inputController.clear();
    _expectedController.clear();
    setState(() {
      _hashes = const {};
      _selectedFileName = null;
      _selectedFileSize = null;
      _fileProgress = 0.0;
      _isHashingFile = false;
    });
  }

  IconData _getHashIcon(HashAlgorithm algo) => switch (algo) {
    HashAlgorithm.md5 => Icons.fingerprint_rounded,
    HashAlgorithm.sha1 => Icons.verified_user_rounded,
    HashAlgorithm.sha256 => Icons.security_rounded,
    HashAlgorithm.sha512 => Icons.enhanced_encryption_rounded,
  };

  Color _getHashSeed(HashAlgorithm algo) => switch (algo) {
    HashAlgorithm.md5 => ExpressivePalette.lemonZest,
    HashAlgorithm.sha1 => ExpressivePalette.sunsetCoral,
    HashAlgorithm.sha256 => ExpressivePalette.violetVibrant,
    HashAlgorithm.sha512 => ExpressivePalette.tealOptimist,
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final expectedText = _expectedController.text.trim();
    final matchedAlgo = _hashes.isNotEmpty && expectedText.isNotEmpty
        ? _hashService.matchExpected(_hashes, expectedText)
        : null;

    return EditorialToolScaffold(
      title: 'Calculateur de hash',
      heroTag: widget.heroTag,
      actions: [
        IconButton(
          onPressed: () {
            HapticsService.perform(context, HapticType.selection);
            setState(() => _uppercase = !_uppercase);
          },
          icon: Icon(
            _uppercase ? Icons.text_fields_rounded : Icons.title_rounded,
            color: _uppercase ? colorScheme.primary : colorScheme.onSurface,
          ),
          tooltip: _uppercase
              ? 'Afficher en minuscules'
              : 'Afficher en majuscules',
        ),
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
              icon: Icons.fingerprint_rounded,
              title: 'Calculer une empreinte',
              description:
                  'MD5, SHA-1, SHA-256 et SHA-512 pour texte ou fichier.',
            ),
            const SizedBox(height: 16),
            SegmentedButton<HashInputType>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: HashInputType.text,
                  icon: Icon(Icons.text_fields_rounded, size: 17),
                  label: Text(
                    'UTF-8',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ButtonSegment(
                  value: HashInputType.hex,
                  icon: Icon(Icons.code_rounded, size: 17),
                  label: Text(
                    'Hexa',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ButtonSegment(
                  value: HashInputType.file,
                  icon: Icon(Icons.insert_drive_file_rounded, size: 17),
                  label: Text(
                    'Fichier',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              selected: {_inputType},
              onSelectionChanged: (newSelection) {
                HapticsService.perform(context, HapticType.selection);
                setState(() {
                  _inputType = newSelection.first;
                  _hashes = const {};
                });
                if (_inputType != HashInputType.file) {
                  _onInputChanged();
                }
              },
            ),
            const SizedBox(height: 16),
            if (_inputType == HashInputType.file)
              _buildFilePickerCard(colorScheme)
            else
              ExpressiveCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _inputType == HashInputType.text
                              ? Icons.text_fields_rounded
                              : Icons.code_rounded,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _inputType == HashInputType.text
                              ? 'Texte à hasher'
                              : 'Données hexadécimales',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _inputController,
                      maxLines: 4,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontFamily: _inputType == HashInputType.hex
                            ? 'monospace'
                            : null,
                      ),
                      decoration: InputDecoration(
                        hintText: _inputType == HashInputType.text
                            ? 'Saisissez votre texte ici…'
                            : 'Ex : 48656C6C6F',
                      ),
                      inputFormatters: _inputType == HashInputType.hex
                          ? [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9A-Fa-f\s]'),
                              ),
                            ]
                          : null,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            for (final algo in HashAlgorithm.values) ...[
              _buildHashResult(algo),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 4),
            _buildChecksumVerifierCard(
              colorScheme,
              expectedText: expectedText,
              matchedAlgo: matchedAlgo,
            ),
            if (_inputType != HashInputType.file) ...[
              const SizedBox(height: 16),
              _buildQuickExamples(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilePickerCard(ColorScheme colorScheme) {
    return ExpressiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.folder_open_rounded,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Calcul en streaming sur fichier',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_selectedFileName != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(ExpressiveShapes.medium),
              ),
              child: Row(
                children: [
                  Icon(Icons.description_rounded, color: colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedFileName!,
                          style: Theme.of(context).textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_selectedFileSize != null)
                          Text(
                            _formatSize(_selectedFileSize!),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_isHashingFile) ...[
            LinearProgressIndicator(value: _fileProgress),
            const SizedBox(height: 6),
            Text(
              'Lecture en cours (${(_fileProgress * 100).round()} %)...',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
          ],
          ExpressiveActionButton.iconLabel(
            icon: Icons.upload_file_rounded,
            label: _selectedFileName == null
                ? 'Choisir un fichier'
                : 'Choisir un autre fichier',
            onPressed: _isHashingFile ? null : _pickAndHashFile,
          ),
        ],
      ),
    );
  }

  Widget _buildChecksumVerifierCard(
    ColorScheme colorScheme, {
    required String expectedText,
    required HashAlgorithm? matchedAlgo,
  }) {
    return ExpressiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.verified_rounded,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Vérifier une empreinte (Checksum)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _expectedController,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Coller un hash attendu pour comparer…',
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.paste_rounded, size: 18),
                    tooltip: 'Coller',
                    onPressed: () async {
                      final data = await Clipboard.getData(
                        Clipboard.kTextPlain,
                      );
                      final text = data?.text?.trim();
                      if (text != null && text.isNotEmpty) {
                        setState(() => _expectedController.text = text);
                      }
                    },
                  ),
                  if (expectedText.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      tooltip: 'Effacer',
                      onPressed: () {
                        setState(() => _expectedController.clear());
                      },
                    ),
                ],
              ),
            ),
          ),
          if (expectedText.isNotEmpty && _hashes.isNotEmpty) ...[
            const SizedBox(height: 12),
            StatusBanner(
              message: matchedAlgo != null
                  ? 'Empreinte valide · correspond à ${matchedAlgo.label}'
                  : 'Aucune correspondance avec les empreintes calculées',
              icon: matchedAlgo != null
                  ? Icons.check_circle_rounded
                  : Icons.error_outline_rounded,
              tone: matchedAlgo != null ? BadgeTone.success : BadgeTone.danger,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHashResult(HashAlgorithm algo) {
    final baseScheme = Theme.of(context).colorScheme;
    final hashScheme = EditorialPalette.expressiveSeedScheme(
      _getHashSeed(algo),
      baseScheme.brightness,
    );
    final result = _displayValue(algo);

    return ExpressiveCard(
      onTap: result.isNotEmpty ? () => _copyHash(algo) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: hashScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(ExpressiveShapes.small),
                ),
                child: Icon(
                  _getHashIcon(algo),
                  size: 18,
                  color: hashScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 10),
              Text(algo.label, style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              if (result.isNotEmpty)
                IconButton.filledTonal(
                  onPressed: () => _copyHash(algo),
                  icon: const Icon(Icons.content_copy_rounded, size: 16),
                  tooltip: 'Copier',
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: baseScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(ExpressiveShapes.medium),
            ),
            child: SelectableText(
              result.isNotEmpty ? result : 'Hash ${algo.label} apparaîtra ici…',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                color: result.isNotEmpty
                    ? baseScheme.onSurface
                    : baseScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickExamples() {
    final colorScheme = Theme.of(context).colorScheme;

    const examples = [
      {'text': 'Hello World', 'label': 'Texte simple'},
      {'text': 'password123', 'label': 'Mot de passe'},
      {'text': 'Lorem ipsum dolor', 'label': 'Phrase'},
      {'text': '{"key": "value"}', 'label': 'JSON'},
    ];

    return ExpressiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flash_on_rounded,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Exemples rapides',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: examples.map((example) {
              return ActionChip(
                onPressed: () {
                  HapticsService.perform(context, HapticType.selection);
                  setState(() => _inputType = HashInputType.text);
                  _inputController.text = example['text']!;
                },
                avatar: const Icon(Icons.bolt_rounded, size: 16),
                label: Text('${example['label']} (${example['text']})'),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
