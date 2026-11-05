import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
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
import 'package:toolbox_everything_mobile/shared/widgets/editorial_tool_components.dart';
import 'package:toolbox_everything_mobile/shared/widgets/editorial_tool_scaffold.dart';
import 'package:toolbox_everything_mobile/shared/widgets/expressive_card.dart';

class QrCodeScreen extends StatefulWidget {
  final String heroTag;

  const QrCodeScreen({super.key, required this.heroTag});

  @override
  QrCodeScreenState createState() => QrCodeScreenState();
}

class QrCodeScreenState extends State<QrCodeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _textController = TextEditingController();
  String _qrData = '';
  bool _isDialogShowing = false;
  final GlobalKey _qrKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return EditorialToolScaffold(
      title: 'QR Code',
      heroTag: widget.heroTag,
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(icon: Icon(Icons.qr_code_2_rounded), text: 'Générer'),
          Tab(icon: Icon(Icons.qr_code_scanner_rounded), text: 'Scanner'),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildGeneratorTab(), _buildScannerTab()],
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
            description: 'Saisissez un lien ou du texte et exportez-le.',
          ),
          const SizedBox(height: 16),
          ExpressiveCard(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                labelText: 'Entrez le texte ou l’URL',
                prefixIcon: const Icon(Icons.link_rounded),
                suffixIcon: _qrData.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _textController.clear();
                          setState(() => _qrData = '');
                        },
                      )
                    : null,
              ),
              onChanged: (text) => setState(() => _qrData = text),
            ),
          ),
          const SizedBox(height: 16),
          if (_qrData.isNotEmpty)
            ExpressiveCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    key: _qrKey,
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
                    'Entrez du texte pour générer un QR Code',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScannerTab() {
    return MobileScanner(
      onDetect: (capture) {
        if (_isDialogShowing) return;

        final List<Barcode> barcodes = capture.barcodes;
        if (barcodes.isNotEmpty) {
          final String code = barcodes.first.rawValue ?? 'Aucune donnée';
          setState(() {
            _isDialogShowing = true;
          });
          showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('QR Code détecté'),
              content: SelectableText(code),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Fermer'),
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copier'),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    Navigator.of(dialogContext).pop();
                    AppFeedback.copied(context, 'Contenu QR copié !');
                  },
                ),
              ],
            ),
          ).then((_) {
            if (mounted) {
              setState(() => _isDialogShowing = false);
            }
          });
        }
      },
    );
  }
}
