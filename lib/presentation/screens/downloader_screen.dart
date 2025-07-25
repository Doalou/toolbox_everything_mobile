import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DownloaderScreen extends StatefulWidget {
  const DownloaderScreen({super.key});

  @override
  _DownloaderScreenState createState() => _DownloaderScreenState();
}

class _DownloaderScreenState extends State<DownloaderScreen> {
  final TextEditingController _urlController = TextEditingController();
  final YoutubeExplode _yt = YoutubeExplode();
  Video? _video;
  StreamManifest? _manifest;
  bool _isLoading = false;

  // State for individual download tracking
  StreamInfo? _currentlyDownloading;
  final Map<StreamInfo, double> _downloadProgresses = {};

  Future<void> _fetchVideoInfo() async {
    if (_urlController.text.isEmpty) return;
    FocusScope.of(context).unfocus(); // Hide keyboard

    setState(() {
      _isLoading = true;
      _video = null;
      _manifest = null;
      _currentlyDownloading = null;
      _downloadProgresses.clear();
    });

    try {
      var videoId = VideoId.parseVideoId(_urlController.text);
      if (videoId == null) throw 'URL invalide ou non supportée';
      
      _video = await _yt.videos.get(videoId);
      _manifest = await _yt.videos.streamsClient.getManifest(videoId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadStream(StreamInfo streamInfo) async {
    if (_currentlyDownloading != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Un autre téléchargement est déjà en cours.')));
      return;
    }
    setState(() {
      _currentlyDownloading = streamInfo;
      _downloadProgresses[streamInfo] = 0.0;
    });

    // 1. Gérer les permissions (principalement pour mobile)
    if (Platform.isAndroid || Platform.isIOS) {
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission de stockage refusée')));
        return;
      }
    }

    // 2. Obtenir le répertoire de téléchargement en fonction de la plateforme
    Directory? directory;
    try {
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        directory = await getDownloadsDirectory();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plateforme non supportée pour le téléchargement')));
        return;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur pour obtenir le dossier: $e')));
      return;
    }

    if (directory == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible de trouver le dossier de téléchargement.')));
        return;
    }
    
    // 3. Nettoyer le nom du fichier et télécharger
    String sanitizedTitle = _video!.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final filePath = '${directory.path}/$sanitizedTitle.${streamInfo.container.name}';
    final file = File(filePath);
    
    try {
        final stream = _yt.videos.streamsClient.get(streamInfo);
        final fileStream = file.openWrite();
        final totalByte = streamInfo.size.totalBytes;
        var receivedBytes = 0;

        await for (final data in stream) {
          receivedBytes += data.length;
          setState(() {
            _downloadProgresses[streamInfo] = receivedBytes / totalByte;
          });
          fileStream.add(data);
        }
        await fileStream.flush();
        await fileStream.close();
        
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Téléchargement terminé: $filePath')));
    } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur de téléchargement: $e')));
    } finally {
        setState(() {
          _currentlyDownloading = null;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Téléchargeur YouTube')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildUrlInput(),
            const SizedBox(height: 16),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
            if (_video != null) _buildVideoInfoCard(),
            if (_manifest != null) _buildStreamList(),
          ],
        ),
      ),
    );
  }

  Widget _buildUrlInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _urlController,
            decoration: InputDecoration(
              labelText: 'URL de la vidéo YouTube',
              hintText: 'https://youtu.be/...',
              suffixIcon: IconButton(
                icon: const Icon(Icons.paste),
                onPressed: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (data != null) {
                    _urlController.text = data.text ?? '';
                  }
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _isLoading ? null : _fetchVideoInfo,
          child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 3)) : const Text('Analyser'),
        ),
      ],
    );
  }
  
  Widget _buildVideoInfoCard() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Image.network(_video!.thumbnails.mediumResUrl, height: 80, width: 120, fit: BoxFit.cover),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_video!.title, style: Theme.of(context).textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(_video!.author, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(_video!.duration.toString().split('.').first.padLeft(8, '0'), style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamList() {
    final streams = _manifest!.streams.toList();
    
    return Expanded(
      child: ListView.builder(
        itemCount: streams.length,
        itemBuilder: (context, index) {
          final stream = streams[index];
          final progress = _downloadProgresses[stream] ?? 0.0;
          final isDownloadingThis = _currentlyDownloading == stream;

          // Determine icon based on stream type
          IconData icon = Icons.videocam;
          if (stream is MuxedStreamInfo) {
            icon = Icons.video_collection;
          } else if (stream is AudioOnlyStreamInfo) {
            icon = Icons.audiotrack;
          }

          return Card(
            child: ListTile(
              leading: Icon(icon),
              title: Text('${stream.qualityLabel} - ${(stream.size.totalMegaBytes).toStringAsFixed(2)} MB'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stream.container.name.toUpperCase()),
                  if (isDownloadingThis) LinearProgressIndicator(value: progress),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.downloading),
                onPressed: isDownloadingThis ? null : () => _downloadStream(stream),
              ),
            ),
          );
        },
      ),
    );
  }
} 