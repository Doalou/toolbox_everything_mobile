import 'package:open_file/open_file.dart';
import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

class DownloaderScreen extends StatefulWidget {
  const DownloaderScreen({super.key});

  @override
  DownloaderScreenState createState() => DownloaderScreenState();
}

class DownloaderScreenState extends State<DownloaderScreen>
    with TickerProviderStateMixin {
  final TextEditingController _urlController = TextEditingController();
  final YoutubeExplode _yt = YoutubeExplode();

  late AnimationController _searchController;

  Video? _video;
  bool _isLoading = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  StreamInfo? _downloadingStreamInfo;
  List<VideoStreamInfo> _availableStreams = [];
  List<AudioStreamInfo> _availableAudio = [];
  List<VideoOnlyStreamInfo> _availableVideoOnlyInternal = [];

  @override
  void initState() {
    super.initState();
    _searchController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Animation visuelle supprimée
  }

  // Plus de demande de permission: on écrit dans le dossier spécifique à l'app

  @override
  void dispose() {
    _searchController.dispose();
    _urlController.dispose();
    _yt.close();
    super.dispose();
  }

  Future<void> _fetchVideoInfo() async {
    if (_urlController.text.trim().isEmpty) return;

    FocusScope.of(context).unfocus();
    _searchController.forward();

    setState(() {
      _isLoading = true;
      _video = null;
      _availableStreams.clear();
      _availableAudio.clear();
      _availableVideoOnlyInternal.clear();
      _isDownloading = false;
      _downloadProgress = 0.0;
      _downloadingStreamInfo = null;
    });

    try {
      final videoId = VideoId.parseVideoId(_urlController.text.trim());
      if (videoId == null) throw 'URL YouTube invalide';

      _video = await _yt.videos.get(videoId);

      // Récupérer les streams disponibles
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      _availableStreams = manifest.muxed.sortByVideoQuality();
      _availableAudio = manifest.audioOnly.sortByBitrate();
      _availableVideoOnlyInternal = manifest.videoOnly.sortByVideoQuality();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Vidéo trouvée: ${_video!.title}')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error fetching video info: $e');
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _searchController.reverse();
      }
    }
  }

  Future<void> _downloadStream(StreamInfo streamInfo, String format) async {
    if (_video == null) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _downloadingStreamInfo = streamInfo;
    });

    try {
      // Obtenir le répertoire de téléchargement
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        // Utilise le dossier externe spécifique à l'app (pas de permission requise)
        downloadsDir = await getExternalStorageDirectory();
      } else {
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      if (downloadsDir == null) {
        throw "Impossible de trouver le dossier de téléchargement";
      }

      // Préparer le chemin du fichier
      final sanitizedTitle = _video!.title
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
          .replaceAll(RegExp(r'\s+'), '_');

      final extension = streamInfo.container.name;
      final fileName =
          '${sanitizedTitle}_${streamInfo is VideoStreamInfo ? streamInfo.videoQuality.toString() : (streamInfo as AudioOnlyStreamInfo).bitrate.toString()}.$extension';
      final filePath = '${downloadsDir.path}/$fileName';
      final file = File(filePath);

      // Télécharger avec suivi de progression
      final stream = _yt.videos.streamsClient.get(streamInfo);
      final fileStream = file.openWrite();

      var downloaded = 0;
      final total = streamInfo.size.totalBytes;

      await for (final chunk in stream) {
        downloaded += chunk.length;
        fileStream.add(chunk);

        if (mounted) {
          setState(() {
            _downloadProgress = downloaded / total;
          });
        }
      }

      await fileStream.close();

      // Fallback fusion si l'utilisateur a choisi une "meilleure qualité" qui n'existe pas en muxed
      // (par ex: 1080p sans audio). Ici, si on a téléchargé une piste vidéo seule
      // (container parfois 'webm' avec codecs VP9/AV1) on tente d'attacher le meilleur audio disponible.
      if (streamInfo is VideoOnlyStreamInfo && _availableAudio.isNotEmpty) {
        final audioBest = _selectBestAudio(_availableAudio);
        // Télécharge l'audio
        final audioPath =
            '${downloadsDir.path}/${sanitizedTitle}_audio.${audioBest.container.name}';
        final audioFile = File(audioPath);
        final audioStream = _yt.videos.streamsClient.get(audioBest);
        final audioSink = audioFile.openWrite();
        await for (final chunk in audioStream) {
          audioSink.add(chunk);
        }
        await audioSink.close();

        // Sortie fusionnée en MP4 si possible
        final mergedPath =
            '${downloadsDir.path}/${sanitizedTitle}_${streamInfo.videoQualityLabel}.mp4';
        final cmd =
            "-y -i '${file.path}' -i '$audioPath' -c:v copy -c:a aac -shortest '$mergedPath'";
        final session = await FFmpegKit.execute(cmd);
        final rc = await session.getReturnCode();
        if (ReturnCode.isSuccess(rc)) {
          // Supprime fichiers temporaires vidéo et audio, conserve le MP4 fusionné
          try {
            await file.delete();
            await audioFile.delete();
          } catch (_) {}

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(
                      Icons.download_done,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Fusion réussie: ${mergedPath.split('/').last}\nDossier: ${downloadsDir.path}',
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: 'OUVRIR',
                  textColor: Colors.white,
                  onPressed: () => OpenFile.open(mergedPath),
                ),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Échec de la fusion vidéo+audio'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 1.0;
          _downloadingStreamInfo = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.download_done, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Téléchargé: $fileName\nDossier: ${downloadsDir.path}',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'OUVRIR',
              textColor: Colors.white,
              onPressed: () {
                OpenFile.open(filePath);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0.0;
          _downloadingStreamInfo = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Erreur de téléchargement: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${twoDigits(minutes)}m ${twoDigits(seconds)}s';
    } else {
      return '${minutes}m ${twoDigits(seconds)}s';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes} B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Téléchargeur YouTube'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              _urlController.clear();
              setState(() {
                _video = null;
                _availableStreams.clear();
                _availableAudio.clear();
                _availableVideoOnlyInternal.clear();
                _isDownloading = false;
                _downloadProgress = 0.0;
                _downloadingStreamInfo = null;
              });
            },
            icon: Icon(Icons.clear_all, color: colorScheme.primary),
            tooltip: 'Effacer',
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header moderne (sans animation)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFFF0000).withValues(alpha: 0.1),
                    const Color(0xFFCC0000).withValues(alpha: 0.08),
                    colorScheme.primaryContainer.withValues(alpha: 0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF0000).withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.download_for_offline,
                    size: 48,
                    color: const Color(0xFFFF0000),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Téléchargeur YouTube',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Téléchargez vos vidéos et musiques préférées',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Zone de saisie URL (sans animation)
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.link, color: colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'URL de la vidéo YouTube',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _urlController,
                            style: Theme.of(context).textTheme.bodyLarge,
                            decoration: InputDecoration(
                              hintText: 'https://youtube.com/watch?v=...',
                              border: InputBorder.none,
                              prefixIcon: Icon(
                                Icons.youtube_searched_for,
                                color: const Color(0xFFFF0000),
                              ),
                            ),
                            onSubmitted: (_) => _fetchVideoInfo(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FloatingActionButton(
                          heroTag: "youtube_search",
                          onPressed: _isLoading ? null : _fetchVideoInfo,
                          backgroundColor: const Color(0xFFFF0000),
                          foregroundColor: Colors.white,
                          mini: true,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.search),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (_video != null) ...[
              const SizedBox(height: 32),

              // Informations vidéo
              _buildVideoInfo(),

              const SizedBox(height: 24),

              // Options de téléchargement
              _buildDownloadOptions(),
            ],

            if (_isDownloading) ...[
              const SizedBox(height: 32),
              _buildDownloadProgress(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVideoInfo() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              _video!.thumbnails.highResUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 180,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  height: 180,
                  color: colorScheme.surfaceContainerHighest,
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (context, error, stack) {
                return Container(
                  height: 180,
                  color: colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.error_outline, size: 48),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _video!.title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _video!.author,
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.timer_outlined,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                _formatDuration(_video!.duration!),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Options de téléchargement',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (_availableStreams.isNotEmpty) _buildMuxedGroupedCategory(),
        if (_availableVideoOnlyInternal.isNotEmpty)
          _buildFusionGroupedCategory(),
        if (_availableAudio.isNotEmpty) _buildAudioGroupedCategory(),
      ],
    );
  }

  // Regroupe les flux muxed (vidéo+audio) par étiquette de qualité (ex: 1080p)
  Map<String, List<VideoStreamInfo>> _groupMuxedByQuality(
    List<VideoStreamInfo> streams,
  ) {
    final Map<String, List<VideoStreamInfo>> groups = {};
    for (final s in streams) {
      final label = s.videoQualityLabel;
      groups.putIfAbsent(label, () => []).add(s);
    }
    return groups;
  }

  // Choisit la "meilleure" option dans un groupe: priorité mp4 puis taille la plus grande
  VideoStreamInfo _selectBestMuxed(List<VideoStreamInfo> group) {
    final mp4 = group
        .where((s) => s.container.name.toLowerCase() == 'mp4')
        .toList();
    final candidates = mp4.isNotEmpty ? mp4 : group;
    candidates.sort((a, b) => b.size.totalBytes.compareTo(a.size.totalBytes));
    return candidates.first;
  }

  // Choisit le meilleur audio: priorité m4a puis bitrate le plus élevé
  AudioStreamInfo _selectBestAudio(List<AudioStreamInfo> audio) {
    final m4a = audio
        .where((a) => a.container.name.toLowerCase() == 'm4a')
        .toList();
    final candidates = m4a.isNotEmpty ? m4a : audio;
    candidates.sort(
      (a, b) => b.bitrate.bitsPerSecond.compareTo(a.bitrate.bitsPerSecond),
    );
    return candidates.first;
  }

  Widget _buildMuxedGroupedCategory() {
    final colorScheme = Theme.of(context).colorScheme;
    final groups = _groupMuxedByQuality(_availableStreams);
    // Ordonne les groupes par hauteur de résolution décroissante si possible, sinon par label
    final sortedKeys = groups.keys.toList()
      ..sort((a, b) {
        int parseHeight(String label) {
          final match = RegExp(r'(\d{3,4})p').firstMatch(label);
          return match != null ? int.parse(match.group(1)!) : 0;
        }

        return parseHeight(b).compareTo(parseHeight(a));
      });

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Icon(Icons.video_library_outlined, color: colorScheme.primary),
        title: const Text(
          'Vidéo + Audio (Muxed)',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        children: [
          for (final key in sortedKeys)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: colorScheme.outline.withOpacity(0.15),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              key,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: _isDownloading
                                ? null
                                : () {
                                    final best = _selectBestMuxed(groups[key]!);
                                    _downloadStream(best, 'auto');
                                  },
                            icon: const Icon(Icons.download_for_offline),
                            label: const Text('Télécharger la meilleure'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Liste des variantes disponibles pour cette qualité
                      ...groups[key]!.map((s) => _buildStreamTile(s)).toList(),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Regroupe les flux audio par codec pour un affichage plus clair
  Map<String, List<AudioOnlyStreamInfo>> _groupAudioByCodec(
    List<AudioOnlyStreamInfo> streams,
  ) {
    final Map<String, List<AudioOnlyStreamInfo>> groups = {};
    for (final s in streams) {
      final key = '${s.audioCodec.toUpperCase()} (${s.container.name})';
      groups.putIfAbsent(key, () => []).add(s);
    }
    return groups;
  }

  Widget _buildAudioGroupedCategory() {
    final colorScheme = Theme.of(context).colorScheme;
    final groups = _groupAudioByCodec(_availableAudio);
    final sortedKeys = groups.keys.toList()..sort();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Icon(Icons.audiotrack_outlined, color: colorScheme.primary),
        title: const Text(
          'Audio seul',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        children: [
          for (final key in sortedKeys)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: colorScheme.outline.withOpacity(0.15),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              key,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _isDownloading
                                ? null
                                : () {
                                    final best = _selectBestAudio(groups[key]!);
                                    _downloadStream(best, 'auto');
                                  },
                            icon: const Icon(Icons.download_for_offline),
                            label: const Text('Meilleure'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...groups[key]!.map((s) => _buildStreamTile(s)).toList(),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Regroupe les flux vidéo seuls et propose une fusion automatique avec la meilleure piste audio
  Map<String, List<VideoOnlyStreamInfo>> _groupVideoOnlyByQuality(
    List<VideoOnlyStreamInfo> streams,
  ) {
    final Map<String, List<VideoOnlyStreamInfo>> groups = {};
    for (final s in streams) {
      final label = s.videoQualityLabel;
      groups.putIfAbsent(label, () => []).add(s);
    }
    return groups;
  }

  VideoOnlyStreamInfo _selectBestVideoOnly(List<VideoOnlyStreamInfo> group) {
    final mp4 = group
        .where((s) => s.container.name.toLowerCase() == 'mp4')
        .toList();
    final candidates = mp4.isNotEmpty ? mp4 : group;
    candidates.sort((a, b) => b.size.totalBytes.compareTo(a.size.totalBytes));
    return candidates.first;
  }

  Widget _buildFusionGroupedCategory() {
    final colorScheme = Theme.of(context).colorScheme;
    final groups = _groupVideoOnlyByQuality(_availableVideoOnlyInternal);
    final sortedKeys = groups.keys.toList()
      ..sort((a, b) {
        int parseHeight(String label) {
          final match = RegExp(r'(\d{3,4})p').firstMatch(label);
          return match != null ? int.parse(match.group(1)!) : 0;
        }

        return parseHeight(b).compareTo(parseHeight(a));
      });

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Icon(
          Icons.video_settings_outlined,
          color: colorScheme.primary,
        ),
        title: const Text(
          'Vidéo + Audio (Fusion automatique)',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: const Text(
          'Utilisé quand aucune option muxed n\'est disponible à cette qualité',
        ),
        children: [
          for (final key in sortedKeys)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: colorScheme.outline.withOpacity(0.15),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              key,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: _isDownloading
                                ? null
                                : () {
                                    final best = _selectBestVideoOnly(
                                      groups[key]!,
                                    );
                                    _downloadStream(best, 'auto');
                                  },
                            icon: const Icon(Icons.download_for_offline),
                            label: const Text(
                              'Télécharger la meilleure (fusion)',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Variantes de cette qualité (toutes provoqueront une fusion)
                      ...groups[key]!.map((s) => _buildStreamTile(s)).toList(),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // _buildStreamCategory supprimé (remplacé par un regroupement intelligent)

  Widget _buildStreamTile(StreamInfo stream) {
    final colorScheme = Theme.of(context).colorScheme;
    String title;
    String subtitle;

    if (stream is VideoStreamInfo) {
      title = 'Vidéo - ${stream.videoQualityLabel}';
      subtitle =
          '${stream.videoResolution.width}x${stream.videoResolution.height}, ${stream.framerate.framesPerSecond}fps';
    } else if (stream is AudioOnlyStreamInfo) {
      title = 'Audio - ${stream.audioCodec}';
      subtitle = '${(stream.bitrate.kiloBitsPerSecond).round()} kbps';
    } else {
      title = 'Stream inconnu';
      subtitle = '';
    }

    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatFileSize(stream.size.totalBytes),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.download, color: colorScheme.primary),
            onPressed: _isDownloading
                ? null
                : () => _downloadStream(
                    stream,
                    'Format',
                  ), // Le format sera déterminé dans la méthode
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadProgress() {
    final colorScheme = Theme.of(context).colorScheme;
    String streamLabel = '';
    if (_downloadingStreamInfo is VideoStreamInfo) {
      streamLabel =
          'Vidéo - ${(_downloadingStreamInfo as VideoStreamInfo).videoQualityLabel}';
    } else if (_downloadingStreamInfo is AudioOnlyStreamInfo) {
      streamLabel =
          'Audio - ${(_downloadingStreamInfo as AudioOnlyStreamInfo).bitrate.kiloBitsPerSecond.round()}kbps';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Téléchargement en cours...',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(streamLabel, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: _downloadProgress,
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(_downloadProgress * 100).toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (_downloadingStreamInfo != null)
                Text(
                  '${_formatFileSize((_downloadProgress * _downloadingStreamInfo!.size.totalBytes).round())} / ${_formatFileSize(_downloadingStreamInfo!.size.totalBytes)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
