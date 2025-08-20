import 'dart:io';
import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:toolbox_everything_mobile/core/services/downloads_saver.dart';
import 'package:toolbox_everything_mobile/core/services/notification_service.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

// Callback de progression pour les téléchargements
typedef ProgressCallback = void Function(int received, int total);

class DownloadTask {
  final StreamInfo streamInfo;
  final AudioOnlyStreamInfo? audioStreamInfo; // Seulement pour la fusion
  final String videoTitle;
  final SendPort sendPort;
  final int notificationId;
  final RootIsolateToken rootIsolateToken;

  DownloadTask(
    this.streamInfo,
    this.audioStreamInfo,
    this.videoTitle,
    this.sendPort,
    this.notificationId,
    this.rootIsolateToken,
  );
}

class DownloadService {
  static void download(DownloadTask task) {
    // Initialise le messenger pour permettre aux plugins d'être utilisés dans l'isolate
    BackgroundIsolateBinaryMessenger.ensureInitialized(task.rootIsolateToken);
    final yt = YoutubeExplode();
    // Plus besoin du `notifier` ici
    bool cancelRequested = false;

    // L'ID de notification est maintenant géré par le Provider, on le reçoit dans la tâche
    final notificationId = task.notificationId;

    final receivePort = ReceivePort()
      ..listen((message) {
        if (message == 'cancel') {
          cancelRequested = true;
        }
      });
    task.sendPort.send({'port': receivePort.sendPort});

    () async {
      try {
        // L'initialisation du notifier se fait dans le Provider
        if (task.streamInfo is VideoOnlyStreamInfo && task.audioStreamInfo != null) {
          await _handleMerge(task, task.sendPort, yt, () => cancelRequested);
        } else {
          await _handleSingleStream(task.streamInfo, task.videoTitle, task.sendPort, yt, notificationId, () => cancelRequested);
        }
      } catch (e) {
        task.sendPort.send({'status': 'error', 'message': e.toString()});
        task.sendPort.send({
          'notification': 'fail',
          'id': notificationId,
          'title': 'Erreur de téléchargement',
          'body': task.videoTitle
        });
      } finally {
        yt.close();
        receivePort.close();
      }
    }();
  }

  static Future<void> _handleSingleStream(StreamInfo streamInfo, String videoTitle, SendPort sendPort, YoutubeExplode yt, int notificationId, bool Function() isCancelled) async {
    final downloadsDir = await getApplicationDocumentsDirectory();
    final sanitizedTitle = videoTitle.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').replaceAll(RegExp(r'\s+'), '_');
    final filePath = _ensureUniquePath('${downloadsDir.path}/$sanitizedTitle.${streamInfo.container.name}');
    
    sendPort.send({
      'notification': 'startProgress',
      'id': notificationId,
      'title': 'Téléchargement...',
      'body': videoTitle
    });
    await _downloadStream(streamInfo, filePath, sendPort, yt, notificationId, isCancelled);
    
    sendPort.send({'status': 'completed', 'path': filePath});
    sendPort.send({
      'notification': 'complete',
      'id': notificationId,
      'title': 'Téléchargement terminé',
      'body': videoTitle
    });
  }

  static Future<void> _handleMerge(DownloadTask task, SendPort sendPort, YoutubeExplode yt, bool Function() isCancelled) async {
    final downloadsDir = await getApplicationDocumentsDirectory();
    final sanitizedTitle = task.videoTitle.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').replaceAll(RegExp(r'\s+'), '_');
    final notificationId = task.notificationId;

    final videoPath = _ensureUniquePath('${downloadsDir.path}/${sanitizedTitle}_video.${task.streamInfo.container.name}');
    final audioPath = _ensureUniquePath('${downloadsDir.path}/${sanitizedTitle}_audio.${task.audioStreamInfo!.container.name}');
    final outputPath = _ensureUniquePath('${downloadsDir.path}/$sanitizedTitle.mp4');

    sendPort.send({
      'notification': 'startProgress',
      'id': notificationId,
      'title': 'Téléchargement...',
      'body': task.videoTitle
    });
    
    sendPort.send({'progress_text': 'Téléchargement de la vidéo...'});
    await _downloadStream(task.streamInfo, videoPath, sendPort, yt, notificationId, isCancelled, isPart: true);
    if (isCancelled()) throw 'Cancelled';

    sendPort.send({'progress_text': 'Téléchargement de l\'audio...'});
    await _downloadStream(task.audioStreamInfo!, audioPath, sendPort, yt, notificationId, isCancelled, isPart: true);
    if (isCancelled()) throw 'Cancelled';

    sendPort.send({'progress_text': 'Fusion en cours...'});
    final command = "-i \"$videoPath\" -i \"$audioPath\" -c:v copy -c:a aac \"$outputPath\"";
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    try {
      await File(videoPath).delete();
      await File(audioPath).delete();
    } catch (_) {}

    if (ReturnCode.isSuccess(returnCode)) {
      sendPort.send({'status': 'completed', 'path': outputPath});
      sendPort.send({
        'notification': 'complete',
        'id': notificationId,
        'title': 'Fusion terminée',
        'body': task.videoTitle
      });
    } else {
      throw 'La fusion FFmpeg a échoué.';
    }
  }

  static Future<void> _downloadStream(StreamInfo streamInfo, String path, SendPort sendPort, YoutubeExplode yt, int notificationId, bool Function() isCancelled, {bool isPart = false}) async {
    final file = File(path);
    final fileStream = file.openWrite();
    final stream = yt.videos.streamsClient.get(streamInfo);

    final totalBytes = streamInfo.size.totalBytes;
    var downloadedBytes = 0;

    await for (final chunk in stream) {
      if (isCancelled()) {
        await fileStream.close();
        await file.delete();
        throw 'Cancelled';
      }
      downloadedBytes += chunk.length;
      fileStream.add(chunk);
      final progress = downloadedBytes / totalBytes;
      if (!isPart) {
        sendPort.send({'progress': progress});
        sendPort.send({
          'notification': 'updateProgress',
          'id': notificationId,
          'title': 'Téléchargement (${(progress * 100).toInt()}%)',
          'body': streamInfo.toString(),
          'progress': downloadedBytes,
          'maxProgress': totalBytes
        });
      }
    }
    await fileStream.close();
  }

  static String _ensureUniquePath(String path) {
    if (!File(path).existsSync()) return path;
    final directory = path.substring(0, path.lastIndexOf('/'));
    final filename = path.substring(path.lastIndexOf('/') + 1, path.lastIndexOf('.'));
    final extension = path.substring(path.lastIndexOf('.'));
    int i = 1;
    while (File('$directory/$filename($i)$extension').existsSync()) {
      i++;
    }
    return '$directory/$filename($i)$extension';
  }
}

// Nouvelle implémentation sans Isolate ------------------------------

class DownloadCancelToken {
  bool _cancelled = false;
  void cancel() => _cancelled = true;
  bool get isCancelled => _cancelled;
}

extension _SizeExt on int {
  String toMB() => (this / (1024 * 1024)).toStringAsFixed(2);
}

class DownloadServiceDirect {
  /// Téléchargement sans isolate. Renvoie une [Future] qui se termine quand
  /// le fichier (ou la fusion) est finalisé. Utilise [onProgress] pour
  /// notifier la progression (0.0 – 1.0).
  static Future<String> download({
    required StreamInfo streamInfo,
    AudioOnlyStreamInfo? audioStreamInfo,
    required String videoTitle,
    required DownloadCancelToken cancelToken,
    required ProgressCallback onProgress,
    required int notificationId,
  }) async {
    final yt = YoutubeExplode();
    try {
      if (streamInfo is VideoOnlyStreamInfo && audioStreamInfo != null) {
        final path = await _handleMergeDirect(
          yt,
          streamInfo,
          audioStreamInfo,
          videoTitle,
          cancelToken,
          onProgress,
          notificationId,
        );
        return path;
      } else {
        final path = await _handleSingleDirect(
          yt,
          streamInfo,
          videoTitle,
          cancelToken,
          onProgress,
          notificationId,
        );
        return path;
      }
    } finally {
      yt.close();
    }
  }

  static Future<String> _handleSingleDirect(
    YoutubeExplode yt,
    StreamInfo streamInfo,
    String videoTitle,
    DownloadCancelToken cancelToken,
    ProgressCallback onProgress,
    int notificationId,
  ) async {
    final downloadsDir = await getApplicationDocumentsDirectory();
    final sanitizedTitle = videoTitle
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
    final extension = streamInfo.container.name;
    final filePath = _ensureUniquePath(
        '${downloadsDir.path}/$sanitizedTitle.$extension');

    // Notification début
    await NotificationService.instance.startProgress(
      notificationId,
      title: 'Téléchargement...',
      body: videoTitle,
    );

    await _downloadStreamDirect(
      yt,
      streamInfo,
      filePath,
      cancelToken,
      (received, total) {
        final progress = received / total;
        onProgress(received, total);
        final percent = (progress * 100).toInt().clamp(0, 100);
        NotificationService.instance.updateProgress(
          notificationId,
          title: 'Téléchargement $percent%',
          body: '${(received).toMB()} / ${(total).toMB()} MB',
          progress: percent,
          maxProgress: 100,
        );
      },
    );

    final savedPath = await DownloadsSaver.saveFileToDownloads(
      filePath,
      displayName: '$sanitizedTitle.$extension',
    );
    await NotificationService.instance.complete(
      notificationId,
      title: 'Téléchargement terminé',
      body: videoTitle,
    );
    return savedPath;
  }

  static Future<String> _handleMergeDirect(
    YoutubeExplode yt,
    VideoOnlyStreamInfo videoStream,
    AudioOnlyStreamInfo audioStream,
    String videoTitle,
    DownloadCancelToken cancelToken,
    ProgressCallback onProgress,
    int notificationId,
  ) async {
    final downloadsDir = await getApplicationDocumentsDirectory();
    final sanitizedTitle = videoTitle
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');

    final videoExt = videoStream.container.name;
    final audioExt = audioStream.container.name;
    final videoPath = _ensureUniquePath(
        '${downloadsDir.path}/${sanitizedTitle}_video.$videoExt');
    final audioPath = _ensureUniquePath(
        '${downloadsDir.path}/${sanitizedTitle}_audio.$audioExt');

    // Choix du conteneur de sortie
    final vExt = videoExt.toLowerCase();
    final aExt = audioExt.toLowerCase();
    final canMp4 = (vExt == 'mp4') && (aExt == 'm4a' || aExt == 'aac' || aExt == 'mp4');
    // Préférer WEBM en fallback (au lieu de MKV)
    final outExt = canMp4 ? 'mp4' : 'webm';
    final outputPath = _ensureUniquePath('${downloadsDir.path}/$sanitizedTitle.$outExt');

    await NotificationService.instance.startProgress(
      notificationId,
      title: 'Téléchargement...',
      body: videoTitle,
    );

    final totalCombinedBytes =
        videoStream.size.totalBytes + audioStream.size.totalBytes;
    int downloadedVideo = 0;
    int downloadedAudio = 0;

    Future<void> updateCombinedProgress() async {
      final combined = downloadedVideo + downloadedAudio;
      final percent = (combined * 100 ~/ totalCombinedBytes).clamp(0, 100);
      onProgress(combined, totalCombinedBytes);
      await NotificationService.instance.updateProgress(
        notificationId,
        title: 'Téléchargement $percent%',
        body: '${combined.toMB()} / ${totalCombinedBytes.toMB()} MB',
        progress: percent,
        maxProgress: 100,
      );
    }

    // Téléchargements en parallèle
    await Future.wait([
      _downloadStreamDirect(
        yt,
        videoStream,
        videoPath,
        cancelToken,
        (received, total) {
          downloadedVideo = received;
          updateCombinedProgress();
        },
      ),
      _downloadStreamDirect(
        yt,
        audioStream,
        audioPath,
        cancelToken,
        (received, total) {
          downloadedAudio = received;
          updateCombinedProgress();
        },
      ),
    ]);

    if (cancelToken.isCancelled) throw 'Annulé';

    // Fusion via FFmpeg
    await NotificationService.instance.updateProgress(
      notificationId,
      title: 'Fusion...',
      body: videoTitle,
      progress: 99,
      maxProgress: 100,
    );

    final command = canMp4
        ? '-y -hide_banner -loglevel info -i "$videoPath" -i "$audioPath" -c:v copy -c:a copy -shortest "$outputPath"'
        : '-y -hide_banner -loglevel info -i "$videoPath" -i "$audioPath" -c copy -shortest "$outputPath"';
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    try {
      await File(videoPath).delete();
      await File(audioPath).delete();
    } catch (_) {}

    if (!ReturnCode.isSuccess(returnCode)) {
      // Récupère logs FFmpeg pour diagnostic
      final logs = await session.getAllLogs();
      final logText = logs.map((l) => l.getMessage()).join('\n');
      await NotificationService.instance.fail(
        notificationId,
        title: 'Échec fusion',
        body: 'Voir logs',
      );
      throw 'La fusion FFmpeg a échoué. Logs FFmpeg:\n$logText';
    }

    onProgress(1, 1);
    final savedPath = await DownloadsSaver.saveFileToDownloads(
      outputPath,
      displayName: '$sanitizedTitle.$outExt',
    );
    await NotificationService.instance.complete(
      notificationId,
      title: 'Téléchargement terminé',
      body: videoTitle,
    );
    return savedPath;
  }

  static Future<void> _downloadStreamDirect(
    YoutubeExplode yt,
    StreamInfo streamInfo,
    String path,
    DownloadCancelToken cancelToken,
    ProgressCallback onReceive,
  ) async {
    final file = File(path);
    final sink = file.openWrite();
    // NOTE: Paramètre chunkSize non disponible dans la version actuelle.
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
      // N'appelez pas onReceive trop souvent pour ne pas saturer l'UI
      if (downloaded == totalBytes || downloaded % (256 * 1024) == 0) {
        onReceive(downloaded, totalBytes);
      }
    }

    await sink.close();
    // Flush progression finale
    onReceive(totalBytes, totalBytes);
  }

  static String _ensureUniquePath(String path) {
    if (!File(path).existsSync()) return path;
    final directory = path.substring(0, path.lastIndexOf('/'));
    final filename =
        path.substring(path.lastIndexOf('/') + 1, path.lastIndexOf('.'));
    final extension = path.substring(path.lastIndexOf('.'));
    int i = 1;
    while (File('$directory/$filename($i)$extension').existsSync()) {
      i++;
    }
    return '$directory/$filename($i)$extension';
  }
}
