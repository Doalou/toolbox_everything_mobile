import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_shapes.dart';
import 'package:toolbox_everything_mobile/core/feature_flags/app_feature_flags.dart';
import 'package:toolbox_everything_mobile/core/services/app_feedback.dart';
import 'package:toolbox_everything_mobile/core/services/downloads_saver.dart';
import 'package:toolbox_everything_mobile/core/services/haptics_service.dart';
import 'package:toolbox_everything_mobile/core/services/qr_history_service.dart';
import 'package:toolbox_everything_mobile/core/services/timestamp_service.dart';
import 'package:toolbox_everything_mobile/shared/widgets/editorial_tool_components.dart';
import 'package:toolbox_everything_mobile/shared/widgets/editorial_tool_scaffold.dart';
import 'package:toolbox_everything_mobile/shared/widgets/expressive_card.dart';
import 'package:toolbox_everything_mobile/shared/widgets/status_badge.dart';
import 'package:url_launcher/url_launcher.dart';

enum _QrTemplate { text, wifi, vcard, email }

class QrCodeScreen extends StatefulWidget {
  final String heroTag;
  final String? initialData;
  final String? initialScanImagePath;

  const QrCodeScreen({
    super.key,
    required this.heroTag,
    this.initialData,
    this.initialScanImagePath,
  });

  @override
  QrCodeScreenState createState() => QrCodeScreenState();
}

class QrCodeScreenState extends State<QrCodeScreen>
    with SingleTickerProviderStateMixin {
  final QrHistoryService _historyService = const QrHistoryService();
  final TimestampService _timestampService = const TimestampService();

  late TabController _tabController;

  // Contrôleurs de templates
  _QrTemplate _template = _QrTemplate.text;
  final TextEditingController _textController = TextEditingController();

  // Wi-Fi
  final TextEditingController _wifiSsidController = TextEditingController();
  final TextEditingController _wifiPassController = TextEditingController();
  String _wifiSecurity = 'WPA';
  bool _wifiHidden = false;

  // Contact vCard
  final TextEditingController _vcardNameController = TextEditingController();
  final TextEditingController _vcardPhoneController = TextEditingController();
  final TextEditingController _vcardEmailController = TextEditingController();
  final TextEditingController _vcardOrgController = TextEditingController();
  final TextEditingController _vcardUrlController = TextEditingController();

  // E-mail
  final TextEditingController _emailToController = TextEditingController();
  final TextEditingController _emailSubjectController = TextEditingController();
  final TextEditingController _emailBodyController = TextEditingController();

  String _qrData = '';
  bool _isResultSheetOpen = false;
  bool _scannerActivated = false;
  MobileScannerController? _scannerController;
  List<QrHistoryEntry> _history = [];

  @override
  void initState() {
    super.initState();
    final startOnScanner =
        widget.initialScanImagePath != null &&
        widget.initialScanImagePath!.trim().isNotEmpty;
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: startOnScanner ? 1 : 0,
    );
    _tabController.addListener(_onTabChanged);

    if (widget.initialData != null && widget.initialData!.isNotEmpty) {
      _textController.text = widget.initialData!;
      _qrData = widget.initialData!;
    }

    _loadHistory();

    if (startOnScanner) {
      _scannerActivated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _analyzeImageFile(widget.initialScanImagePath!);
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scannerController?.dispose();
    _textController.dispose();
    _wifiSsidController.dispose();
    _wifiPassController.dispose();
    _vcardNameController.dispose();
    _vcardPhoneController.dispose();
    _vcardEmailController.dispose();
    _vcardOrgController.dispose();
    _vcardUrlController.dispose();
    _emailToController.dispose();
    _emailSubjectController.dispose();
    _emailBodyController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!mounted) return;
    if (_tabController.index == 1 && !_scannerActivated) {
      setState(() {
        _scannerActivated = true;
        _scannerController ??= MobileScannerController();
      });
    } else if (_tabController.index != 1 && _scannerController != null) {
      unawaited(_scannerController!.stop());
    } else if (_tabController.index == 1 && _scannerController != null) {
      unawaited(_scannerController!.start());
    }
  }

  Future<void> _loadHistory() async {
    try {
      final list = await _historyService.load();
      if (mounted) setState(() => _history = list);
    } catch (_) {}
  }

  Future<void> _recordGenerated() async {
    if (_qrData.trim().isEmpty) return;
    final next = await _historyService.add(_qrData, isScanned: false);
    if (mounted) setState(() => _history = next);
  }

  void _rebuildPayload() {
    final next = switch (_template) {
      _QrTemplate.text => _textController.text,
      _QrTemplate.wifi => _historyService.buildWifiPayload(
        ssid: _wifiSsidController.text,
        password: _wifiPassController.text,
        security: _wifiSecurity,
        hidden: _wifiHidden,
      ),
      _QrTemplate.vcard => _historyService.buildVCardPayload(
        fullName: _vcardNameController.text,
        phone: _vcardPhoneController.text,
        email: _vcardEmailController.text,
        org: _vcardOrgController.text,
        url: _vcardUrlController.text,
      ),
      _QrTemplate.email => _historyService.buildEmailPayload(
        to: _emailToController.text,
        subject: _emailSubjectController.text,
        body: _emailBodyController.text,
      ),
    };
    setState(() => _qrData = next);
  }

  Future<Uint8List> _renderQrPngBytes() async {
    final qrPainter = QrPainter(
      data: _qrData,
      version: QrVersions.auto,
      gapless: true,
    );
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(300, 300);
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    qrPainter.paint(canvas, size);
    final picture = recorder.endRecording();
    final image = await picture.toImage(300, 300);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _copyQrImageToClipboard() async {
    if (_qrData.isEmpty) return;
    await _recordGenerated();
    try {
      final bytes = await _renderQrPngBytes();
      await Pasteboard.writeImage(bytes);
      if (mounted) {
        AppFeedback.copied(context, 'QR Code copié dans le presse-papiers');
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.show(
          context,
          'Impossible de copier l’image : $e',
          tone: FeedbackTone.error,
        );
      }
    }
  }

  Future<void> _saveQrCode() async {
    if (_qrData.isEmpty) return;
    await _recordGenerated();
    try {
      final workingDirectory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'qr_code_$timestamp.png';
      final file = File('${workingDirectory.path}/$fileName');

      final bytes = await _renderQrPngBytes();
      await file.writeAsBytes(bytes);
      final savedPath = await DownloadsSaver.saveFileToDownloads(
        file.path,
        displayName: fileName,
        mimeType: 'image/png',
      );

      if (mounted) {
        AppFeedback.show(
          context,
          'QR Code enregistré : $savedPath',
          tone: FeedbackTone.success,
          icon: Icons.download_done_rounded,
        );
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.show(
          context,
          'Erreur lors de la sauvegarde : $e',
          tone: FeedbackTone.error,
        );
      }
    }
  }

  Future<void> _exportQrToPdf() async {
    if (_qrData.isEmpty || !AppFeatureFlags.pdfExport) return;
    await _recordGenerated();
    try {
      final bytes = await _renderQrPngBytes();

      final pdf = pw.Document();
      final pwImage = pw.MemoryImage(bytes);

      pdf.addPage(
        pw.Page(
          build: (context) => pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('QR Code', style: const pw.TextStyle(fontSize: 18)),
              pw.SizedBox(height: 12),
              pw.Image(pwImage, width: 240, height: 240),
              pw.SizedBox(height: 12),
              pw.Text(
                _qrData,
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
      );

      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'qr_code_$timestamp.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());
      final savedPath = await DownloadsSaver.saveFileToDownloads(
        file.path,
        displayName: fileName,
        mimeType: 'application/pdf',
      );

      if (mounted) {
        AppFeedback.show(
          context,
          'PDF exporté : $savedPath',
          tone: FeedbackTone.success,
          icon: Icons.picture_as_pdf_rounded,
        );
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.show(
          context,
          'Erreur export PDF : $e',
          tone: FeedbackTone.error,
        );
      }
    }
  }

  Future<void> _pickAndAnalyzeImage() async {
    try {
      final result = await FilePicker.pickFiles(type: FileType.image);
      if (result.isEmpty || result.single.path == null || !mounted) return;
      await _analyzeImageFile(result.single.path!);
    } catch (e) {
      if (mounted) {
        AppFeedback.show(
          context,
          'Impossible d’analyser l’image : $e',
          tone: FeedbackTone.error,
        );
      }
    }
  }

  Future<void> _analyzeImageFile(String path) async {
    final controller =
        _scannerController ?? MobileScannerController(autoStart: false);
    final createdTemp = _scannerController == null;
    try {
      final capture = await controller.analyzeImage(path);
      final barcodes = capture?.barcodes ?? const [];
      final raw = barcodes.isNotEmpty ? barcodes.first.rawValue : null;
      if (!mounted) return;
      if (raw == null || raw.isEmpty) {
        AppFeedback.show(
          context,
          'Aucun QR Code détecté dans cette image.',
          tone: FeedbackTone.warning,
        );
        return;
      }
      await _handleDetectedCode(raw);
    } finally {
      if (createdTemp) {
        unawaited(controller.dispose());
      }
    }
  }

  Future<void> _handleDetectedCode(String raw) async {
    if (_isResultSheetOpen || !mounted) return;
    _isResultSheetOpen = true;
    HapticsService.perform(context, HapticType.medium);

    final updated = await _historyService.add(raw, isScanned: true);
    if (mounted) setState(() => _history = updated);
    if (!mounted) {
      _isResultSheetOpen = false;
      return;
    }

    final parsed = _historyService.parseQrData(raw);
    final scheme = Theme.of(context).colorScheme;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(_iconForType(parsed.type), color: scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'QR Code détecté',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  StatusBadge(label: parsed.typeLabel, tone: BadgeTone.accent),
                ],
              ),
              const SizedBox(height: 14),
              if (parsed.type == QrContentType.wifi) ...[
                _DetailLine(label: 'Réseau (SSID)', value: parsed.ssid ?? '—'),
                _DetailLine(label: 'Sécurité', value: parsed.security ?? 'WPA'),
                if (parsed.password != null && parsed.password!.isNotEmpty)
                  _DetailLine(label: 'Mot de passe', value: parsed.password!),
                const SizedBox(height: 8),
              ] else if (parsed.type == QrContentType.vcard) ...[
                if (parsed.fullName != null)
                  _DetailLine(label: 'Nom', value: parsed.fullName!),
                if (parsed.phone != null)
                  _DetailLine(label: 'Téléphone', value: parsed.phone!),
                if (parsed.email != null)
                  _DetailLine(label: 'E-mail', value: parsed.email!),
                const SizedBox(height: 8),
              ],
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(ExpressiveShapes.medium),
                ),
                child: SelectableText(
                  raw,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (parsed.type == QrContentType.url && parsed.url != null)
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _launchExternal(parsed.url!);
                      },
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('Ouvrir le lien'),
                    ),
                  if (parsed.type == QrContentType.wifi &&
                      parsed.password != null &&
                      parsed.password!.isNotEmpty)
                    FilledButton.icon(
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: parsed.password!),
                        );
                        Navigator.pop(sheetContext);
                        AppFeedback.copied(context, 'Mot de passe Wi-Fi copié');
                      },
                      icon: const Icon(Icons.wifi_password_rounded, size: 18),
                      label: const Text('Copier le mot de passe'),
                    ),
                  if (parsed.type == QrContentType.email && parsed.url != null)
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _launchExternal(parsed.url!);
                      },
                      icon: const Icon(Icons.mail_rounded, size: 18),
                      label: const Text('Envoyer un e-mail'),
                    ),
                  if (parsed.type == QrContentType.phone && parsed.url != null)
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _launchExternal(parsed.url!);
                      },
                      icon: const Icon(Icons.phone_rounded, size: 18),
                      label: const Text('Appeler'),
                    ),
                  FilledButton.tonalIcon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: raw));
                      Navigator.pop(sheetContext);
                      AppFeedback.copied(context, 'Contenu QR copié !');
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Copier'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _loadIntoGenerator(raw);
                    },
                    icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                    label: const Text('Modifier'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    _isResultSheetOpen = false;
  }

  Future<void> _launchExternal(String target) async {
    final uri = Uri.tryParse(target);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        AppFeedback.show(
          context,
          'Impossible d’ouvrir : $target',
          tone: FeedbackTone.error,
        );
      }
    }
  }

  void _loadIntoGenerator(String data) {
    setState(() {
      _template = _QrTemplate.text;
      _textController.text = data;
      _qrData = data;
    });
    _tabController.animateTo(0);
  }

  IconData _iconForType(QrContentType type) => switch (type) {
    QrContentType.url => Icons.link_rounded,
    QrContentType.wifi => Icons.wifi_rounded,
    QrContentType.vcard => Icons.contact_page_rounded,
    QrContentType.email => Icons.mail_rounded,
    QrContentType.phone => Icons.phone_rounded,
    QrContentType.text => Icons.notes_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return EditorialToolScaffold(
      title: 'QR Code',
      heroTag: widget.heroTag,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(54),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              shape: StadiumBorder(
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(
                    height: 38,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_2_rounded, size: 17),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Générer',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    height: 38,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_scanner_rounded, size: 17),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Scanner',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    height: 38,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_rounded, size: 17),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Historique',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGeneratorTab(),
          _buildScannerTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildGeneratorTab() {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const EditorialToolIntro(
            icon: Icons.qr_code_rounded,
            title: 'Générer un QR Code',
            description: 'Texte, lien, Wi-Fi, contact vCard ou e-mail.',
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                avatar: const Icon(Icons.link_rounded, size: 16),
                label: const Text('Texte / URL'),
                selected: _template == _QrTemplate.text,
                onSelected: (_) {
                  setState(() => _template = _QrTemplate.text);
                  _rebuildPayload();
                },
              ),
              ChoiceChip(
                avatar: const Icon(Icons.wifi_rounded, size: 16),
                label: const Text('Wi-Fi'),
                selected: _template == _QrTemplate.wifi,
                onSelected: (_) {
                  setState(() => _template = _QrTemplate.wifi);
                  _rebuildPayload();
                },
              ),
              ChoiceChip(
                avatar: const Icon(Icons.contact_page_rounded, size: 16),
                label: const Text('Contact'),
                selected: _template == _QrTemplate.vcard,
                onSelected: (_) {
                  setState(() => _template = _QrTemplate.vcard);
                  _rebuildPayload();
                },
              ),
              ChoiceChip(
                avatar: const Icon(Icons.mail_rounded, size: 16),
                label: const Text('E-mail'),
                selected: _template == _QrTemplate.email,
                onSelected: (_) {
                  setState(() => _template = _QrTemplate.email);
                  _rebuildPayload();
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          ExpressiveCard(child: _buildTemplateFields()),
          const SizedBox(height: 16),
          if (_qrData.isNotEmpty)
            ExpressiveCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        ExpressiveShapes.largeIncreased,
                      ),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: QrImageView(
                      data: _qrData,
                      version: QrVersions.auto,
                      size: 200.0,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: _copyQrImageToClipboard,
                        icon: const Icon(Icons.copy_rounded),
                        label: const Text('Copier'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _saveQrCode,
                        icon: const Icon(Icons.save_alt_rounded),
                        label: const Text('Enregistrer'),
                      ),
                      if (AppFeatureFlags.pdfExport)
                        OutlinedButton.icon(
                          onPressed: _exportQrToPdf,
                          icon: const Icon(Icons.picture_as_pdf_rounded),
                          label: const Text('PDF'),
                        ),
                    ],
                  ),
                ],
              ),
            )
          else
            ExpressiveCard(
              padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 24),
              child: Column(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: ShapeDecoration(
                      color: colorScheme.secondaryContainer,
                      shape: const StadiumBorder(),
                    ),
                    child: Icon(
                      Icons.qr_code_rounded,
                      size: 34,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Complétez les champs ci-dessus pour générer le QR Code',
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTemplateFields() {
    switch (_template) {
      case _QrTemplate.text:
        return TextField(
          controller: _textController,
          maxLines: 3,
          minLines: 1,
          decoration: InputDecoration(
            labelText: 'Entrez le texte ou l’URL',
            prefixIcon: const Icon(Icons.link_rounded),
            suffixIcon: _textController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _textController.clear();
                      _rebuildPayload();
                    },
                  )
                : null,
          ),
          onChanged: (_) => _rebuildPayload(),
        );
      case _QrTemplate.wifi:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _wifiSsidController,
              decoration: const InputDecoration(
                labelText: 'Nom du réseau (SSID)',
                prefixIcon: Icon(Icons.wifi_rounded),
              ),
              onChanged: (_) => _rebuildPayload(),
            ),
            const SizedBox(height: 10),
            if (_wifiSecurity != 'nopass') ...[
              TextField(
                controller: _wifiPassController,
                decoration: const InputDecoration(
                  labelText: 'Mot de passe Wi-Fi',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
                onChanged: (_) => _rebuildPayload(),
              ),
              const SizedBox(height: 10),
            ],
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 'WPA', label: Text('WPA/WPA2')),
                ButtonSegment(value: 'WEP', label: Text('WEP')),
                ButtonSegment(value: 'nopass', label: Text('Ouvert')),
              ],
              selected: {_wifiSecurity},
              onSelectionChanged: (s) {
                setState(() => _wifiSecurity = s.first);
                _rebuildPayload();
              },
            ),
            const SizedBox(height: 6),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Réseau masqué'),
              value: _wifiHidden,
              onChanged: (v) {
                setState(() => _wifiHidden = v);
                _rebuildPayload();
              },
            ),
          ],
        );
      case _QrTemplate.vcard:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _vcardNameController,
              decoration: const InputDecoration(
                labelText: 'Nom complet *',
                prefixIcon: Icon(Icons.person_rounded),
              ),
              onChanged: (_) => _rebuildPayload(),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _vcardPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                prefixIcon: Icon(Icons.phone_rounded),
              ),
              onChanged: (_) => _rebuildPayload(),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _vcardEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                prefixIcon: Icon(Icons.mail_rounded),
              ),
              onChanged: (_) => _rebuildPayload(),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _vcardOrgController,
              decoration: const InputDecoration(
                labelText: 'Organisation / Entreprise',
                prefixIcon: Icon(Icons.business_rounded),
              ),
              onChanged: (_) => _rebuildPayload(),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _vcardUrlController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Site web',
                prefixIcon: Icon(Icons.language_rounded),
              ),
              onChanged: (_) => _rebuildPayload(),
            ),
          ],
        );
      case _QrTemplate.email:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailToController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Destinataire *',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
              onChanged: (_) => _rebuildPayload(),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailSubjectController,
              decoration: const InputDecoration(
                labelText: 'Objet',
                prefixIcon: Icon(Icons.subject_rounded),
              ),
              onChanged: (_) => _rebuildPayload(),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailBodyController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Message',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
              onChanged: (_) => _rebuildPayload(),
            ),
          ],
        );
    }
  }

  Widget _buildScannerTab() {
    if (!_scannerActivated) {
      return const Center(child: CircularProgressIndicator());
    }
    _scannerController ??= MobileScannerController();
    final controller = _scannerController!;
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        MobileScanner(
          controller: controller,
          onDetect: (capture) {
            final barcodes = capture.barcodes;
            if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
              _handleDetectedCode(barcodes.first.rawValue!);
            }
          },
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: Center(
            child: Material(
              color: scheme.surface.withValues(alpha: 0.92),
              shape: const StadiumBorder(),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ValueListenableBuilder<MobileScannerState>(
                      valueListenable: controller,
                      builder: (_, state, _) {
                        final on = state.torchState == TorchState.on;
                        return IconButton(
                          onPressed: controller.toggleTorch,
                          icon: Icon(
                            on
                                ? Icons.flash_on_rounded
                                : Icons.flash_off_rounded,
                            color: on ? scheme.primary : scheme.onSurface,
                          ),
                          tooltip: 'Lampe torche',
                        );
                      },
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: controller.switchCamera,
                      icon: const Icon(Icons.cameraswitch_rounded),
                      tooltip: 'Changer de caméra',
                    ),
                    const SizedBox(width: 6),
                    FilledButton.tonalIcon(
                      onPressed: _pickAndAnalyzeImage,
                      icon: const Icon(Icons.photo_library_rounded, size: 18),
                      label: const Text('Galerie'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    final colorScheme = Theme.of(context).colorScheme;

    if (_history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history_toggle_off_rounded,
                size: 48,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                'Historique QR vide',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Vos QR Codes générés ou scannés apparaîtront ici.',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      itemCount: _history.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (itemContext, index) {
        if (index == 0) {
          return Row(
            children: [
              Expanded(
                child: Text(
                  '${_history.length} entrée(s) récente(s)',
                  style: Theme.of(itemContext).textTheme.titleSmall,
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  await _historyService.clear();
                  if (mounted) {
                    setState(() => _history = []);
                    AppFeedback.show(context, 'Historique QR effacé');
                  }
                },
                icon: Icon(
                  Icons.delete_sweep_rounded,
                  size: 18,
                  color: colorScheme.error,
                ),
                label: Text(
                  'Tout effacer',
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            ],
          );
        }

        final entry = _history[index - 1];
        final parsed = _historyService.parseQrData(entry.data);
        return ExpressiveCard(
          onTap: () => _loadIntoGenerator(entry.data),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _iconForType(entry.type),
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StatusBadge(
                          label: entry.isScanned ? 'Scanné' : 'Généré',
                          tone: entry.isScanned
                              ? BadgeTone.success
                              : BadgeTone.accent,
                        ),
                        StatusBadge(
                          label: parsed.typeLabel,
                          tone: BadgeTone.neutral,
                        ),
                        Text(
                          _timestampService.relativeFromNow(entry.createdAt),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: entry.data));
                      AppFeedback.copied(context, 'Contenu copié');
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    tooltip: 'Copier',
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: () async {
                      final next = await _historyService.remove(entry.id);
                      if (mounted) setState(() => _history = next);
                    },
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: colorScheme.error,
                    ),
                    tooltip: 'Supprimer',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                entry.data,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailLine extends StatelessWidget {
  final String label;
  final String value;

  const _DetailLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label : ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
