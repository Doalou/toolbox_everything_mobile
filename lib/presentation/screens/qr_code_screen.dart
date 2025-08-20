import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:super_clipboard/super_clipboard.dart';
import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';

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

  // Copie du texte retirée sur demande

  Future<void> _copyQrImageToClipboard() async {
    if (_qrData.isEmpty) return;

    try {
      final clipboard = SystemClipboard.instance;
      if (clipboard == null) {
        Fluttertoast.showToast(msg: 'Presse-papiers non disponible');
        return;
      }

      // Rendre le QR en image PNG en mémoire
      final qrPainter = QrPainter(
        data: _qrData,
        version: QrVersions.auto,
        // QrPainter moderne utilise eyeStyle/dataModuleStyle pour les couleurs
        gapless: true,
      );
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(300, 300);
      qrPainter.paint(canvas, size);
      final picture = recorder.endRecording();
      final image = await picture.toImage(300, 300);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final item = DataWriterItem();
      item.add(Formats.png(bytes));
      await clipboard.write([item]);

      Fluttertoast.showToast(msg: 'QR Code copié dans le presse-papiers');
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Impossible de copier l\'image: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _saveQrCode() async {
    if (_qrData.isEmpty) return;

    try {
      // Demander les permissions de stockage
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        Fluttertoast.showToast(msg: 'Permission de stockage requise');
        return;
      }

      final qrPainter = QrPainter(
        data: _qrData,
        version: QrVersions.auto,
        gapless: true,
      );

      // Obtenir le dossier Downloads
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        // Sur Android, essayer d'accéder au dossier Downloads
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          downloadsDir = Directory('${externalDir.path}/../Download');
          if (!await downloadsDir.exists()) {
            downloadsDir = Directory('${externalDir.path}/../Downloads');
          }
        }
      } else if (Platform.isIOS) {
        // Sur iOS, utiliser le dossier Documents
        downloadsDir = await getApplicationDocumentsDirectory();
      } else {
        // Sur d'autres plateformes, utiliser le dossier Documents
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      if (downloadsDir == null || !await downloadsDir.exists()) {
        // Fallback vers le dossier Documents
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'qr_code_$timestamp.png';
      final file = File('${downloadsDir.path}/$fileName');

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = const Size(300, 300);

      qrPainter.paint(canvas, size);
      final picture = recorder.endRecording();
      final image = await picture.toImage(300, 300);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      await file.writeAsBytes(bytes);

      Fluttertoast.showToast(
        msg: 'QR Code sauvegardé dans ${downloadsDir.path}',
        toastLength: Toast.LENGTH_LONG,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Erreur lors de la sauvegarde: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _exportQrToPdf() async {
    if (_qrData.isEmpty) return;
    try {
      // Rendre le QR en PNG en mémoire
      final qrPainter = QrPainter(
        data: _qrData,
        version: QrVersions.auto,
        gapless: true,
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(300, 300);
      qrPainter.paint(canvas, size);
      final picture = recorder.endRecording();
      final image = await picture.toImage(300, 300);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final pdf = pw.Document();
      final pwImage = pw.MemoryImage(bytes);

      pdf.addPage(
        pw.Page(
          build: (context) => pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('QR Code', style: pw.TextStyle(fontSize: 18)),
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

      // Choisir un dossier accessible sans permission (dossier app)
      Directory dir;
      if (Platform.isAndroid) {
        final d = await getExternalStorageDirectory();
        if (d == null) throw 'Dossier externe indisponible';
        dir = d;
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'qr_code_$timestamp.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      Fluttertoast.showToast(
        msg: 'PDF exporté dans ${dir.path}',
        toastLength: Toast.LENGTH_LONG,
      );

      // Optionnel: partage direct du PDF
      // await Printing.sharePdf(bytes: await pdf.save(), filename: fileName);
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Erreur export PDF: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Hero(
          tag: widget.heroTag,
          child: Material(
            type: MaterialType.transparency,
            child: Text(
              'Générateur/Lecteur de QR Code',
              style: Theme.of(context).appBarTheme.titleTextStyle,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.create), text: 'Générer'),
            Tab(icon: Icon(Icons.camera_alt), text: 'Scanner'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Generator Tab
          _buildGeneratorTab(),
          // Scanner Tab
          _buildScannerTab(),
        ],
      ),
    );
  }

  Widget _buildGeneratorTab() {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _textController,
            decoration: InputDecoration(
              labelText: 'Entrez le texte ou l\'URL',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _textController.clear();
                  setState(() {
                    _qrData = '';
                  });
                },
              ),
            ),
            onChanged: (text) {
              setState(() {
                _qrData = text;
              });
            },
          ),
          const SizedBox(height: 20),
          if (_qrData.isNotEmpty) ...[
            Expanded(
              child: Column(
                children: [
                  // QR Code
                  Container(
                    key: _qrKey,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: QrImageView(
                      data: _qrData,
                      version: QrVersions.auto,
                      size: 200.0,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Boutons d'action (Wrap pour éviter les débordements)
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _copyQrImageToClipboard,
                        icon: const Icon(Icons.copy),
                        label: const Text('Copier'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primaryContainer,
                          foregroundColor: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _saveQrCode,
                        icon: const Icon(Icons.save),
                        label: const Text('Enregistrer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.secondaryContainer,
                          foregroundColor: colorScheme.onSecondaryContainer,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _exportQrToPdf,
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Exporter PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.tertiaryContainer,
                          foregroundColor: colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.qr_code,
                      size: 80,
                      color: colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Entrez du texte pour générer un QR Code',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
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
            builder: (context) => AlertDialog(
              title: const Text('QR Code détecté'),
              content: Text(code),
              actions: [
                TextButton(
                  child: const Text('Copier'),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    Navigator.of(context).pop();
                    Fluttertoast.showToast(msg: "Copié !");
                  },
                ),
                TextButton(
                  child: const Text('Fermer'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ).then((_) {
            setState(() {
              _isDialogShowing = false;
            });
          });
        }
      },
    );
  }
}
