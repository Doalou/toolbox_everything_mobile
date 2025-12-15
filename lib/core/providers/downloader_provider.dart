import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:toolbox_everything_mobile/core/services/download_service_universal.dart';
import 'package:toolbox_everything_mobile/core/services/notification_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:toolbox_everything_mobile/core/services/downloads_saver.dart';

enum DownloaderState { initial, loading, success, error }

/// État de l'activité de téléchargement, indépendant de la recherche/manifest
enum DownloadActivityState { idle, downloading, completed, error }

class DownloaderProvider with ChangeNotifier {
  final YoutubeExplode _yt = YoutubeExplode();

  DownloaderState _state = DownloaderState.initial;
  DownloaderState get state => _state;

  Video? _video;
  Video? get video => _video;

  List<VideoStreamInfo> _muxedStreams = [];
  List<VideoStreamInfo> get muxedStreams => _muxedStreams;

  List<AudioOnlyStreamInfo> _audioStreams = [];
  List<AudioOnlyStreamInfo> get audioStreams => _audioStreams;

  List<VideoOnlyStreamInfo> _videoOnlyStreams = [];
  List<VideoOnlyStreamInfo> get videoOnlyStreams => _videoOnlyStreams;

  // Préférences de sortie (gérées en interne)
  bool _preferMp4Output = true;
  bool _showMkvOutputs = false;
  bool get showMkvOutputs => _showMkvOutputs;
  bool get preferMp4Output => _preferMp4Output;
  void setShowMkvOutputs(bool value) {
    if (_showMkvOutputs == value) return;
    _showMkvOutputs = value;
    notifyListeners();
    _savePrefs();
  }

  void setPreferMp4Output(bool value) {
    if (_preferMp4Output == value) return;
    _preferMp4Output = value;
    notifyListeners();
    _savePrefs();
  }

  static const String _prefsKeyShowMkv = 'downloader_show_mkv';
  static const String _prefsKeyPreferMp4 = 'downloader_prefer_mp4';

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _showMkvOutputs = prefs.getBool(_prefsKeyShowMkv) ?? _showMkvOutputs;
      _preferMp4Output = prefs.getBool(_prefsKeyPreferMp4) ?? _preferMp4Output;
      notifyListeners();
    } catch (_) {}
  }

  // Utilitaires internes pour MP3
  String _ensureUniquePath(String path) {
    if (!File(path).existsSync()) return path;
    final directory = path.substring(0, path.lastIndexOf('/'));
    final filename = path.substring(
      path.lastIndexOf('/') + 1,
      path.lastIndexOf('.'),
    );
    final extension = path.substring(path.lastIndexOf('.'));
    int i = 1;
    while (File('$directory/$filename($i)$extension').existsSync()) {
      i++;
    }
    return '$directory/$filename($i)$extension';
  }

  String _bytesToMBText(int bytes) {
    return (bytes / (1024 * 1024)).toStringAsFixed(2);
  }

  Future<void> _downloadStreamToPath({
    required YoutubeExplode yt,
    required StreamInfo streamInfo,
    required String outputPath,
    required DownloadCancelToken cancelToken,
    required void Function(int received, int total) onReceive,
  }) async {
    final file = File(outputPath);
    final sink = file.openWrite();
    final Stream<List<int>> stream = yt.videos.streamsClient.get(streamInfo);
    final totalBytes = streamInfo.size.totalBytes;
    int downloaded = 0;
    await for (final List<int> chunk in stream) {
      if (cancelToken.isCancelled) {
        await sink.close();
        await file.delete();
        throw 'Annulé';
      }
      downloaded += chunk.length;
      sink.add(chunk);
      if (downloaded == totalBytes || downloaded % (256 * 1024) == 0) {
        onReceive(downloaded, totalBytes);
      }
    }
    await sink.close();
    onReceive(totalBytes, totalBytes);
  }

  Future<void> _savePrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKeyShowMkv, _showMkvOutputs);
      await prefs.setBool(_prefsKeyPreferMp4, _preferMp4Output);
    } catch (_) {}
  }

  List<StreamInfo> get videoDownloadOptions {
    // Liste combinée
    final List<StreamInfo> combined = [..._muxedStreams, ..._videoOnlyStreams];
    // Tri par qualité décroissante, en priorisant les muxed pour une même qualité
    combined.sort((a, b) {
      int qa = 0;
      int qb = 0;
      if (a is VideoStreamInfo) {
        qa = int.tryParse(a.qualityLabel.replaceAll('p', '')) ?? 0;
      }
      if (b is VideoStreamInfo) {
        qb = int.tryParse(b.qualityLabel.replaceAll('p', '')) ?? 0;
      }
      if (qa != qb) return qb.compareTo(qa);
      final aIsMuxed = a is VideoStreamInfo && a is! VideoOnlyStreamInfo;
      final bIsMuxed = b is VideoStreamInfo && b is! VideoOnlyStreamInfo;
      if (aIsMuxed == bIsMuxed) return 0;
      return aIsMuxed ? -1 : 1;
    });
    if (!_showMkvOutputs) {
      return combined.where((s) => willResultInMp4(s)).toList();
    }
    return combined;
  }

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  double _progress = 0.0;
  double get progress => _progress;

  DownloadCancelToken? _cancelToken;

  String? _lastOutputPath;
  String? get lastOutputPath => _lastOutputPath;
  String? _currentDownloadTitle;
  String? get currentDownloadTitle => _currentDownloadTitle;

  int _bytesReceived = 0;
  int _bytesTotal = 0;
  DateTime? _downloadStart;
  DateTime? _lastUiProgressEmittedAt;
  double _lastUiProgressEmittedValue = -1.0;

  // Exposés UI
  String get downloadedMbText => _bytesReceived == 0
      ? '0.00 MB'
      : '${(_bytesReceived / (1024 * 1024)).toStringAsFixed(2)} MB';
  String get totalMbText => _bytesTotal == 0
      ? '—'
      : '${(_bytesTotal / (1024 * 1024)).toStringAsFixed(2)} MB';
  String get speedText {
    if (_downloadStart == null) return '— MB/s';
    final secs =
        DateTime.now().difference(_downloadStart!).inMilliseconds / 1000.0;
    if (secs <= 0) return '— MB/s';
    final mbPerSec = (_bytesReceived / secs) / (1024 * 1024);
    return mbPerSec.isFinite ? '${mbPerSec.toStringAsFixed(2)} MB/s' : '— MB/s';
  }

  String get etaText {
    if (_bytesTotal <= 0 || _downloadStart == null) return 'ETA —:—';
    final secs =
        DateTime.now().difference(_downloadStart!).inMilliseconds / 1000.0;
    if (secs <= 0) return 'ETA —:—';
    final bytesPerSec = _bytesReceived / secs;
    if (bytesPerSec <= 0) return 'ETA —:—';
    final remaining = _bytesTotal - _bytesReceived;
    final remainingSecs = (remaining / bytesPerSec).clamp(0, 24 * 3600).toInt();
    final m = (remainingSecs ~/ 60).toString().padLeft(2, '0');
    final s = (remainingSecs % 60).toString().padLeft(2, '0');
    return 'ETA $m:$s';
  }

  bool _isFetching = false;
  bool get isFetching => _isFetching;

  int? _notificationId;

  // État dédié à l'activité de téléchargement (indépendant de l'état de recherche)
  DownloadActivityState _downloadActivity = DownloadActivityState.idle;
  DownloadActivityState get downloadActivity => _downloadActivity;
  bool get hasDownloadStatus =>
      _downloadActivity != DownloadActivityState.idle ||
      _lastOutputPath != null;

  Future<void> fetchVideoInfo(String url) async {
    if (url.trim().isEmpty) return;

    _isFetching = true;
    _state = DownloaderState.loading;
    notifyListeners();

    try {
      final videoId = VideoId.parseVideoId(url.trim());
      if (videoId == null) throw 'URL YouTube invalide';

      _video = await _yt.videos.get(videoId);
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);

      _muxedStreams = manifest.muxed.sortByVideoQuality();
      _audioStreams = manifest.audioOnly.sortByBitrate();
      _videoOnlyStreams = manifest.videoOnly.sortByVideoQuality();

      _state = DownloaderState.success;
    } catch (e) {
      _state = DownloaderState.error;
      _errorMessage = e.toString();
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }

  void downloadPreset(String preset) {
    if (_video == null) return;

    StreamInfo? stream;

    switch (preset) {
      case '720p':
      case '1080p':
        final quality = preset; // '720p' or '1080p'
        // 1) tenter muxed (audio+vidéo)
        stream = _muxedStreams
            .where((s) => s.qualityLabel == quality)
            .firstOrNull;
        // 2) sinon, tenter une piste vidéo seule correspondante (fusion FFmpeg)
        stream ??= _videoOnlyStreams
            .where((s) => s.qualityLabel == quality)
            .firstOrNull;
        // 3) fallback: meilleur stream dispo (muxed en priorité)
        stream ??= _muxedStreams.isNotEmpty
            ? _muxedStreams.first
            : (_videoOnlyStreams.isNotEmpty ? _videoOnlyStreams.first : null);

        // Si on préfère MP4, éviter un résultat MKV en rebasculant vers meilleur muxed
        if (_preferMp4Output &&
            stream is VideoOnlyStreamInfo &&
            !willResultInMp4(stream)) {
          if (_muxedStreams.isNotEmpty) {
            stream = _muxedStreams.first;
          }
        }
        break;

      case '128k':
      case '256k':
        final bitrate = (preset == '128k') ? 128 : 256;
        // Recherche du stream audio le plus proche
        stream = _audioStreams
            .where((s) => (s.bitrate.kiloBitsPerSecond - bitrate).abs() < 20)
            .firstOrNull;

        // Fallback: Meilleur audio disponible
        if (stream == null && _audioStreams.isNotEmpty) {
          stream = _audioStreams.first;
        }
        break;
    }

    if (stream != null) {
      startDownload(stream);
    } else {
      _state = DownloaderState.error;
      _errorMessage =
          "Aucun flux correspondant n'a pu être trouvé pour ce préréglage.";
      notifyListeners();
    }
  }

  void downloadBestQuality() {
    if (_muxedStreams.isNotEmpty) {
      startDownload(_muxedStreams.first);
    } else if (_videoOnlyStreams.isNotEmpty) {
      // Basculer sur fusion: meilleure vidéo + meilleur audio
      final bestVideo = _videoOnlyStreams.first;
      startDownload(bestVideo);
    } else {
      _state = DownloaderState.error;
      _errorMessage = 'Aucun flux compatible pour cette vidéo.';
      notifyListeners();
    }
  }

  Future<void> startDownload(
    StreamInfo streamInfo, {
    AudioOnlyStreamInfo? preferredAudio,
  }) async {
    if (_video == null) return;

    _downloadActivity = DownloadActivityState.downloading;
    _progress = 0.0;
    _currentDownloadTitle = _video!.title;
    notifyListeners();

    _notificationId =
        DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF; // ID 32-bit

    // S'assurer que les permissions de notification sont accordées (Android 13+)
    try {
      await NotificationService.instance.ensurePermission();
    } catch (_) {}

    _cancelToken = DownloadCancelToken();
    _downloadStart = DateTime.now();
    _bytesReceived = 0;
    _bytesTotal = 0;

    try {
      // Si vidéo seule, sélectionner automatiquement la meilleure piste audio disponible pour fusionner
      final AudioOnlyStreamInfo? companionAudio =
          streamInfo is VideoOnlyStreamInfo
          ? (preferredAudio ?? _pickBestAudioFor(streamInfo))
          : null;

      if (streamInfo is VideoOnlyStreamInfo && companionAudio == null) {
        _state = DownloaderState.error;
        _errorMessage =
            "Cette vidéo ne propose pas de piste audio compatible pour la fusion. Choisissez un flux MP4 muxed ou un autre preset.";
        notifyListeners();
        return;
      }

      final outputPath = await DownloadServiceDirect.download(
        streamInfo: streamInfo,
        audioStreamInfo: companionAudio,
        videoTitle: _video!.title,
        cancelToken: _cancelToken!,
        notificationId: _notificationId!,
        onProgress: (received, total) {
          _updateProgressUI(received, total);
        },
      );

      if (_cancelToken!.isCancelled) {
        _downloadActivity = DownloadActivityState.error;
        _errorMessage = 'Téléchargement annulé';
      } else {
        _lastOutputPath = outputPath;
        _downloadActivity = DownloadActivityState.completed;
      }
    } catch (e) {
      _downloadActivity = DownloadActivityState.error;
      _errorMessage = e.toString();
    } finally {
      _notificationId = null;
      notifyListeners();
    }
  }

  void _updateProgressUI(int received, int total) {
    _bytesReceived = received;
    _bytesTotal = total;
    _progress = total > 0 ? received / total : 0.0;

    final now = DateTime.now();
    if (_shouldEmitProgress(now, _progress)) {
      _lastUiProgressEmittedAt = now;
      _lastUiProgressEmittedValue = _progress;
      notifyListeners();
    }
  }

  bool _shouldEmitProgress(DateTime now, double percent) {
    if (_lastUiProgressEmittedAt == null) return true;
    final ms = now.difference(_lastUiProgressEmittedAt!).inMilliseconds;
    if (ms >= 120) return true; // ~8 Hz
    if ((percent - _lastUiProgressEmittedValue) >= 0.01) return true; // +1%
    if (percent >= 0.999) return true; // flush at end
    return false;
  }

  Future<void> startMergedDownload({
    required VideoOnlyStreamInfo video,
    required AudioOnlyStreamInfo audio,
  }) async {
    await startDownload(video, preferredAudio: audio);
  }

  Future<void> startAudioMp3Conversion(AudioOnlyStreamInfo source) async {
    if (_video == null) return;

    _downloadActivity = DownloadActivityState.downloading;
    _progress = 0.0;
    _currentDownloadTitle = '${_video!.title} (MP3)';
    notifyListeners();

    _notificationId = DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF;

    try {
      await NotificationService.instance.ensurePermission();
    } catch (_) {}

    _cancelToken = DownloadCancelToken();
    _downloadStart = DateTime.now();
    _bytesReceived = 0;
    _bytesTotal = source.size.totalBytes;

    try {
      // 1) Télécharger l'audio source (sans isolate) vers un fichier temporaire
      final downloadsDir = await getApplicationDocumentsDirectory();
      final sanitizedTitle = _video!.title
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
          .replaceAll(RegExp(r'\s+'), '_');
      final tempIn = _ensureUniquePath(
        '${downloadsDir.path}/${sanitizedTitle}_src.${source.container.name}',
      );

      await NotificationService.instance.startProgress(
        _notificationId!,
        title: 'Téléchargement audio...',
        body: _video!.title,
      );

      final yt = YoutubeExplode();
      try {
        await _downloadStreamToPath(
          yt: yt,
          streamInfo: source,
          outputPath: tempIn,
          cancelToken: _cancelToken!,
          onReceive: (received, total) {
            _updateProgressUI(received, total);
            final percent = (received * 100 ~/ (total == 0 ? 1 : total)).clamp(
              0,
              100,
            );
            NotificationService.instance.updateProgress(
              _notificationId!,
              title: 'Téléchargement $percent%',
              body: '${_bytesToMBText(received)} / ${_bytesToMBText(total)} MB',
              progress: percent,
              maxProgress: 100,
            );
          },
        );
      } finally {
        yt.close();
      }

      if (_cancelToken!.isCancelled) {
        throw 'Annulé';
      }

      // 2) Convertir en MP3 via FFmpegKit
      final tempOut = _ensureUniquePath(
        '${downloadsDir.path}/$sanitizedTitle.mp3',
      );
      await NotificationService.instance.updateProgress(
        _notificationId!,
        title: 'Conversion MP3...',
        body: _video!.title,
        progress: 99,
        maxProgress: 100,
      );

      final session = await FFmpegKit.execute(
        '-y -hide_banner -loglevel info -i "$tempIn" -vn -c:a libmp3lame -q:a 2 "$tempOut"',
      );
      final returnCode = await session.getReturnCode();
      if (!ReturnCode.isSuccess(returnCode)) {
        final logs = await session.getAllLogs();
        final logText = logs.map((l) => l.getMessage()).join('\n');
        await NotificationService.instance.fail(
          _notificationId!,
          title: 'Échec conversion',
          body: 'Voir logs',
        );
        throw 'Conversion MP3 échouée. Logs FFmpeg:\n$logText';
      }

      // 3) Déplacer vers Téléchargements et terminer
      final savedPath = await DownloadsSaver.saveFileToDownloads(
        tempOut,
        displayName: '$sanitizedTitle.mp3',
      );

      _lastOutputPath = savedPath;
      _downloadActivity = DownloadActivityState.completed;
      await NotificationService.instance.complete(
        _notificationId!,
        title: 'Conversion MP3 terminée',
        body: _video!.title,
      );
    } catch (e) {
      _downloadActivity = DownloadActivityState.error;
      _errorMessage = e.toString();
    } finally {
      _notificationId = null;
      notifyListeners();
    }
  }

  AudioOnlyStreamInfo? _pickBestAudioFor(VideoOnlyStreamInfo video) {
    if (_audioStreams.isEmpty) return null;
    final videoExt = video.container.name.toLowerCase();
    final List<AudioOnlyStreamInfo> candidates = List.of(_audioStreams);
    int pref(AudioOnlyStreamInfo a) {
      final ext = a.container.name.toLowerCase();
      if (videoExt == 'mp4') {
        // Préfère m4a/aac/mp4 pour sortie MP4 directe
        if (ext == 'm4a' || ext == 'aac' || ext == 'mp4') return 0;
        if (ext == 'webm' || ext == 'opus') return 1;
      } else {
        // Préfère webm/opus avec vidéo webm
        if (ext == 'webm' || ext == 'opus') return 0;
        if (ext == 'm4a' || ext == 'aac' || ext == 'mp4') return 1;
      }
      return 2;
    }

    candidates.sort((a, b) {
      final pa = pref(a);
      final pb = pref(b);
      if (pa != pb) return pa.compareTo(pb);
      // À préférence égale: plus haut bitrate d'abord
      return b.bitrate.kiloBitsPerSecond.compareTo(a.bitrate.kiloBitsPerSecond);
    });
    return candidates.first;
  }

  bool willResultInMp4(StreamInfo streamInfo) {
    if (streamInfo is! VideoStreamInfo) return false;
    if (streamInfo is! VideoOnlyStreamInfo) {
      // Muxed: MP4 si conteneur déjà mp4
      return streamInfo.container.name.toLowerCase() == 'mp4';
    }
    // Vidéo seule: vérifier si une piste audio compatible MP4 est disponible
    final videoExt = streamInfo.container.name.toLowerCase();
    if (videoExt != 'mp4') return false;
    return _audioStreams.any((a) {
      final ext = a.container.name.toLowerCase();
      return ext == 'm4a' || ext == 'aac' || ext == 'mp4';
    });
  }

  void cancelDownload() {
    _cancelToken?.cancel();
    if (_notificationId != null) {
      NotificationService.instance.cancel(_notificationId!);
    }
    _downloadActivity = DownloadActivityState.error;
    notifyListeners();
  }

  void clear() {
    _video = null;
    _muxedStreams = [];
    _audioStreams = [];
    _videoOnlyStreams = [];
    _errorMessage = null;
    _lastOutputPath = null;
    _currentDownloadTitle = null;
    _state = DownloaderState.initial;
    _downloadActivity = DownloadActivityState.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _yt.close();
    super.dispose();
  }
}
