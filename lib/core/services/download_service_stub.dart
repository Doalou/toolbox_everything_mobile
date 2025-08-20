typedef ProgressCallback = void Function(int received, int total);

class DownloadCancelToken {
  bool _cancelled = false;
  void cancel() => _cancelled = true;
  bool get isCancelled => _cancelled;
}

class DownloadServiceDirect {
  static Future<String> download({
    required Object streamInfo,
    Object? audioStreamInfo,
    required String videoTitle,
    required DownloadCancelToken cancelToken,
    required ProgressCallback onProgress,
    required int notificationId,
  }) async {
    throw UnsupportedError('Téléchargement non supporté sur cette plateforme');
  }
}


