import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:toolbox_everything_mobile/core/services/downloads_saver.dart';
import 'package:toolbox_everything_mobile/core/services/notification_service.dart';
import 'package:toolbox_everything_mobile/core/services/youtube_service.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

enum DownloadPhase { downloading, merging, converting }

class DownloadProgress {
  final int receivedBytes;
  final int totalBytes;
  final DownloadPhase phase;

  const DownloadProgress({
    required this.receivedBytes,
    required this.totalBytes,
    required this.phase,
  });

  double get fraction =>
      totalBytes <= 0 ? 0 : (receivedBytes / totalBytes).clamp(0.0, 1.0);
}

typedef ProgressCallback = void Function(DownloadProgress progress);

class DownloadCancelToken {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;

  void throwIfCancelled() {
    if (_cancelled) throw const DownloadException('Téléchargement annulé.');
  }
}

class DownloadException implements Exception {
  final String message;
  final String? diagnostics;

  const DownloadException(this.message, {this.diagnostics});

  @override
  String toString() => message;
}

/// Point d'entrée unique pour télécharger et convertir les flux média.
class DownloadService {
  DownloadService._();

  static Future<String> download({
    required StreamInfo streamInfo,
    AudioOnlyStreamInfo? audioStreamInfo,
    required String videoTitle,
    required DownloadCancelToken cancelToken,
    required ProgressCallback onProgress,
    required int notificationId,
  }) async {
    final youtube = YoutubeExplode();
    try {
      if (streamInfo is VideoOnlyStreamInfo && audioStreamInfo != null) {
        return await _downloadAndMerge(
          youtube: youtube,
          videoStream: streamInfo,
          audioStream: audioStreamInfo,
          title: videoTitle,
          cancelToken: cancelToken,
          onProgress: onProgress,
          notificationId: notificationId,
        );
      }
      return await _downloadSingle(
        youtube: youtube,
        streamInfo: streamInfo,
        title: videoTitle,
        cancelToken: cancelToken,
        onProgress: onProgress,
        notificationId: notificationId,
      );
    } on DownloadException {
      rethrow;
    } catch (error) {
      throw DownloadException(
        'Le téléchargement a échoué.',
        diagnostics: error.toString(),
      );
    } finally {
      youtube.close();
    }
  }

  static Future<String> downloadMp3({
    required AudioOnlyStreamInfo source,
    required String videoTitle,
    required DownloadCancelToken cancelToken,
    required ProgressCallback onProgress,
    required int notificationId,
  }) async {
    final youtube = YoutubeExplode();
    final directory = await getApplicationDocumentsDirectory();
    final safeTitle = sanitizeFileName(videoTitle);
    final inputPath = ensureUniquePath(
      '${directory.path}/${safeTitle}_source.${source.container.name}',
    );
    final outputPath = ensureUniquePath('${directory.path}/$safeTitle.mp3');

    try {
      await NotificationService.instance.startProgress(
        notificationId,
        title: 'Téléchargement audio…',
        body: videoTitle,
      );
      await _writeStream(
        youtube: youtube,
        streamInfo: source,
        outputPath: inputPath,
        cancelToken: cancelToken,
        phase: DownloadPhase.downloading,
        onProgress: (progress) {
          onProgress(progress);
          _notifyProgress(notificationId, progress, 'Téléchargement audio');
        },
      );
      cancelToken.throwIfCancelled();

      onProgress(
        const DownloadProgress(
          receivedBytes: 0,
          totalBytes: 0,
          phase: DownloadPhase.converting,
        ),
      );
      await NotificationService.instance.updateProgress(
        notificationId,
        title: 'Conversion MP3…',
        body: videoTitle,
        progress: 99,
        maxProgress: 100,
      );
      final session = await FFmpegKit.execute(
        '-y -hide_banner -loglevel warning -i "$inputPath" '
        '-vn -c:a libmp3lame -q:a 2 "$outputPath"',
      );
      if (!ReturnCode.isSuccess(await session.getReturnCode())) {
        throw DownloadException(
          'La conversion MP3 a échoué.',
          diagnostics: await _ffmpegDiagnostics(session),
        );
      }

      final savedPath = await DownloadsSaver.saveFileToDownloads(
        outputPath,
        displayName: '$safeTitle.mp3',
      );
      await NotificationService.instance.complete(
        notificationId,
        title: 'Conversion MP3 terminée',
        body: videoTitle,
      );
      return savedPath;
    } on DownloadException {
      await NotificationService.instance.fail(
        notificationId,
        title: 'Échec du téléchargement',
        body: videoTitle,
      );
      rethrow;
    } catch (error) {
      throw DownloadException(
        'La conversion MP3 a échoué.',
        diagnostics: error.toString(),
      );
    } finally {
      youtube.close();
      await _deleteIfExists(inputPath);
      if (Platform.isAndroid) await _deleteIfExists(outputPath);
    }
  }

  static Future<String> _downloadSingle({
    required YoutubeExplode youtube,
    required StreamInfo streamInfo,
    required String title,
    required DownloadCancelToken cancelToken,
    required ProgressCallback onProgress,
    required int notificationId,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final safeTitle = sanitizeFileName(title);
    final extension = streamInfo.container.name;
    final temporaryPath = ensureUniquePath(
      '${directory.path}/$safeTitle.$extension',
    );

    try {
      await NotificationService.instance.startProgress(
        notificationId,
        title: 'Téléchargement…',
        body: title,
      );
      await _writeStream(
        youtube: youtube,
        streamInfo: streamInfo,
        outputPath: temporaryPath,
        cancelToken: cancelToken,
        phase: DownloadPhase.downloading,
        onProgress: (progress) {
          onProgress(progress);
          _notifyProgress(notificationId, progress, 'Téléchargement');
        },
      );
      final savedPath = await DownloadsSaver.saveFileToDownloads(
        temporaryPath,
        displayName: '$safeTitle.$extension',
      );
      await NotificationService.instance.complete(
        notificationId,
        title: 'Téléchargement terminé',
        body: title,
      );
      return savedPath;
    } finally {
      if (cancelToken.isCancelled || Platform.isAndroid) {
        await _deleteIfExists(temporaryPath);
      }
    }
  }

  static Future<String> _downloadAndMerge({
    required YoutubeExplode youtube,
    required VideoOnlyStreamInfo videoStream,
    required AudioOnlyStreamInfo audioStream,
    required String title,
    required DownloadCancelToken cancelToken,
    required ProgressCallback onProgress,
    required int notificationId,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final safeTitle = sanitizeFileName(title);
    final videoPath = ensureUniquePath(
      '${directory.path}/${safeTitle}_video.${videoStream.container.name}',
    );
    final audioPath = ensureUniquePath(
      '${directory.path}/${safeTitle}_audio.${audioStream.container.name}',
    );
    final canUseMp4 =
        videoStream.container.name.toLowerCase() == 'mp4' &&
        {
          'm4a',
          'aac',
          'mp4',
        }.contains(audioStream.container.name.toLowerCase());
    final extension = canUseMp4 ? 'mp4' : 'webm';
    final outputPath = ensureUniquePath(
      '${directory.path}/$safeTitle.$extension',
    );
    final totalBytes =
        videoStream.size.totalBytes + audioStream.size.totalBytes;
    var videoBytes = 0;
    var audioBytes = 0;

    void reportProgress() {
      final progress = DownloadProgress(
        receivedBytes: videoBytes + audioBytes,
        totalBytes: totalBytes,
        phase: DownloadPhase.downloading,
      );
      onProgress(progress);
      _notifyProgress(notificationId, progress, 'Téléchargement');
    }

    try {
      await NotificationService.instance.startProgress(
        notificationId,
        title: 'Téléchargement…',
        body: title,
      );
      await Future.wait([
        _writeStream(
          youtube: youtube,
          streamInfo: videoStream,
          outputPath: videoPath,
          cancelToken: cancelToken,
          phase: DownloadPhase.downloading,
          onProgress: (progress) {
            videoBytes = progress.receivedBytes;
            reportProgress();
          },
        ),
        _writeStream(
          youtube: youtube,
          streamInfo: audioStream,
          outputPath: audioPath,
          cancelToken: cancelToken,
          phase: DownloadPhase.downloading,
          onProgress: (progress) {
            audioBytes = progress.receivedBytes;
            reportProgress();
          },
        ),
      ]);
      cancelToken.throwIfCancelled();

      onProgress(
        DownloadProgress(
          receivedBytes: totalBytes,
          totalBytes: totalBytes,
          phase: DownloadPhase.merging,
        ),
      );
      await NotificationService.instance.updateProgress(
        notificationId,
        title: 'Fusion…',
        body: title,
        progress: 99,
        maxProgress: 100,
      );
      final codecArguments = canUseMp4 ? '-c:v copy -c:a copy' : '-c copy';
      final session = await FFmpegKit.execute(
        '-y -hide_banner -loglevel warning -i "$videoPath" -i "$audioPath" '
        '$codecArguments -shortest "$outputPath"',
      );
      if (!ReturnCode.isSuccess(await session.getReturnCode())) {
        throw DownloadException(
          'La fusion audio/vidéo a échoué.',
          diagnostics: await _ffmpegDiagnostics(session),
        );
      }
      final savedPath = await DownloadsSaver.saveFileToDownloads(
        outputPath,
        displayName: '$safeTitle.$extension',
      );
      await NotificationService.instance.complete(
        notificationId,
        title: 'Téléchargement terminé',
        body: title,
      );
      return savedPath;
    } finally {
      await Future.wait([
        _deleteIfExists(videoPath),
        _deleteIfExists(audioPath),
      ]);
      if (cancelToken.isCancelled || Platform.isAndroid) {
        await _deleteIfExists(outputPath);
      }
    }
  }

  static Future<void> _writeStream({
    required YoutubeExplode youtube,
    required StreamInfo streamInfo,
    required String outputPath,
    required DownloadCancelToken cancelToken,
    required DownloadPhase phase,
    required ProgressCallback onProgress,
  }) async {
    final file = File(outputPath);
    final sink = file.openWrite();
    final totalBytes = streamInfo.size.totalBytes;
    var receivedBytes = 0;
    try {
      await for (final chunk in YoutubeService.getStream(youtube, streamInfo)) {
        cancelToken.throwIfCancelled();
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (receivedBytes == totalBytes || receivedBytes % (256 * 1024) == 0) {
          onProgress(
            DownloadProgress(
              receivedBytes: receivedBytes,
              totalBytes: totalBytes,
              phase: phase,
            ),
          );
        }
      }
      onProgress(
        DownloadProgress(
          receivedBytes: totalBytes,
          totalBytes: totalBytes,
          phase: phase,
        ),
      );
    } on DownloadException {
      rethrow;
    } catch (error) {
      throw DownloadException(
        YoutubeService.userMessage(error),
        diagnostics: error.toString(),
      );
    } finally {
      await sink.close();
      if (cancelToken.isCancelled) await _deleteIfExists(outputPath);
    }
  }

  static void _notifyProgress(
    int notificationId,
    DownloadProgress progress,
    String title,
  ) {
    final percent = (progress.fraction * 100).round().clamp(0, 100);
    NotificationService.instance.updateProgress(
      notificationId,
      title: '$title $percent %',
      body:
          '${_megabytes(progress.receivedBytes)} / '
          '${_megabytes(progress.totalBytes)} Mo',
      progress: percent,
      maxProgress: 100,
    );
  }

  static String sanitizeFileName(String source) {
    final sanitized = source
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return sanitized.isEmpty ? 'telechargement' : sanitized;
  }

  static String ensureUniquePath(String path) {
    if (!File(path).existsSync()) return path;
    final separator = Platform.pathSeparator;
    final separatorIndex = path.lastIndexOf(separator);
    final extensionIndex = path.lastIndexOf('.');
    final directory = path.substring(0, separatorIndex);
    final filename = path.substring(separatorIndex + 1, extensionIndex);
    final extension = path.substring(extensionIndex);
    var suffix = 1;
    while (File(
      '$directory$separator$filename ($suffix)$extension',
    ).existsSync()) {
      suffix++;
    }
    return '$directory$separator$filename ($suffix)$extension';
  }

  static Future<String> _ffmpegDiagnostics(dynamic session) async {
    final logs = await session.getAllLogs();
    return logs.map((log) => log.getMessage()).join('\n');
  }

  static Future<void> _deleteIfExists(String path) async {
    final file = File(path);
    if (!await file.exists()) return;
    try {
      await file.delete();
    } catch (_) {
      // Le nettoyage est best-effort et ne masque pas le résultat principal.
    }
  }

  static String _megabytes(int bytes) =>
      (bytes / (1024 * 1024)).toStringAsFixed(1);
}
