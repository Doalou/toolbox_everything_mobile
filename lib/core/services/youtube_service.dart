import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Centralise les choix de client et les garde-fous réseau liés à YouTube.
///
/// YouTube fait évoluer régulièrement ses contrôles anti-bot et l'exigence de
/// PO Tokens selon les profils Innertube (`ANDROID`, `IOS`, `ANDROID_VR`).
/// Ce service chaîne plusieurs profils sans dépendre de la page web (`watchPage`)
/// lorsque c'est possible, et assure un repli par requêtes HTTP `Range` si le
/// flux standard de `youtube_explode_dart` est interrompu.
class YoutubeService {
  YoutubeService._();

  static const Duration _metadataTimeout = Duration(seconds: 20);
  static const Duration _manifestTimeout = Duration(seconds: 25);
  static const Duration streamInactivityTimeout = Duration(seconds: 25);

  /// Ordre de priorité des clients Innertube :
  /// 1. `androidSdkless` (`c=ANDROID`, inclut les flux muxed + adaptatifs et
  ///    utilise l'en-tête HTTP `Range` dans `youtube_explode_dart`).
  /// 2. `android` (profil Android complet en repli).
  /// 3. `ios` (flux adaptatifs H.264/AAC fiables sans déchiffrement JS).
  /// 4. `androidVr` (dernier repli).
  static final List<YoutubeApiClient> _manifestClients = [
    YoutubeApiClient.androidSdkless,
    YoutubeApiClient.android,
    YoutubeApiClient.ios,
    YoutubeApiClient.androidVr,
  ];

  static Future<Video> getVideo(YoutubeExplode youtube, VideoId videoId) async {
    try {
      return await youtube.videos.get(videoId).timeout(_metadataTimeout);
    } catch (_) {
      // Si la page web (WatchPage) échoue (absence d'en-tête set-cookie ou
      // blocage anti-bot sur la version web), on récupère les métadonnées via
      // oEmbed afin de ne pas bloquer l'extraction des flux Innertube.
      return _getVideoFallback(videoId);
    }
  }

  static Future<Video> _getVideoFallback(VideoId videoId) async {
    final uri = Uri.https('www.youtube.com', '/oembed', {
      'url': 'https://www.youtube.com/watch?v=${videoId.value}',
      'format': 'json',
    });
    final response = await http.get(uri).timeout(_metadataTimeout);
    if (response.statusCode != 200) {
      throw VideoUnavailableException.unavailable(videoId);
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final title = (data['title'] as String?)?.trim();
    final author = (data['author_name'] as String?)?.trim();

    return Video(
      videoId,
      title != null && title.isNotEmpty ? title : 'Vidéo ${videoId.value}',
      author ?? 'YouTube',
      ChannelId('UC_x5XG1OV2P6uZZ5FSM9Ttw'),
      null,
      null,
      null,
      '',
      null,
      ThumbnailSet(videoId.value),
      const [],
      const Engagement(0, null, null),
      false,
    );
  }

  static Future<StreamManifest> getManifest(
    YoutubeExplode youtube,
    VideoId videoId,
  ) async {
    Object? lastError;
    StackTrace? lastStackTrace;

    // 1) Essayer d'abord `requireWatchPage: false` pour éviter d'envoyer les
    //    cookies et le visitorData web avec un profil mobile Innertube.
    for (final requireWatchPage in [false, true]) {
      for (final client in _manifestClients) {
        try {
          final manifest = await youtube.videos.streams
              .getManifest(
                videoId,
                ytClients: [client],
                requireWatchPage: requireWatchPage,
              )
              .timeout(_manifestTimeout);
          if (manifest.streams.isNotEmpty) {
            return manifest;
          }
        } catch (error, stackTrace) {
          lastError = error;
          lastStackTrace = stackTrace;
        }
      }
    }

    Error.throwWithStackTrace(lastError!, lastStackTrace!);
  }

  static Stream<List<int>> getStream(
    YoutubeExplode youtube,
    StreamInfo streamInfo,
  ) async* {
    final totalBytes = streamInfo.size.totalBytes;
    var yieldedBytes = 0;

    try {
      await for (final chunk
          in youtube.videos.streams
              .get(streamInfo)
              .timeout(streamInactivityTimeout)) {
        yieldedBytes += chunk.length;
        yield chunk;
      }
      if (totalBytes <= 0 || yieldedBytes >= totalBytes) {
        return;
      }
    } catch (_) {
      // Bascule vers le téléchargement direct par plages d'octets (`Range`)
      // à partir de l'offset déjà reçu (`yieldedBytes`).
    }

    try {
      yield* _getDirectRangeStream(streamInfo, startOffset: yieldedBytes);
      return;
    } catch (_) {
      if (yieldedBytes > 0) rethrow;
    }

    // Si le jeton du flux a expiré ou si YouTube refuse un second téléchargement
    // issu du même manifeste (cas de la fusion vidéo + audio), on régénère un
    // manifeste frais pour récupérer une nouvelle URL signée du même itag.
    final freshManifest = await getManifest(youtube, streamInfo.videoId);
    final refreshed = freshManifest.streams
        .where((s) => s.tag == streamInfo.tag)
        .firstOrNull;
    if (refreshed == null) {
      throw YoutubeExplodeException(
        'Video returned 403 (stream: ${streamInfo.tag})',
      );
    }
    yield* _getDirectRangeStream(refreshed, startOffset: 0);
  }

  /// Télécharge directement le flux média par blocs de 9 Mo avec l'en-tête HTTP
  /// `Range: bytes=start-end` et le `User-Agent` correspondant au client `c=`.
  static Stream<List<int>> _getDirectRangeStream(
    StreamInfo streamInfo, {
    int startOffset = 0,
  }) async* {
    const int chunkSize = 9 * 1024 * 1024; // ~9 Mo par requête
    final totalBytes = streamInfo.size.totalBytes;
    if (totalBytes > 0 && startOffset >= totalBytes) return;

    final clientType = (streamInfo.url.queryParameters['c'] ?? '')
        .toUpperCase();
    final userAgent = switch (clientType) {
      'IOS' =>
        'com.google.ios.youtube/20.10.4 (iPhone16,2; U; CPU iOS 18_3_2 like Mac OS X;)',
      'ANDROID_VR' =>
        'com.google.android.apps.youtube.vr.oculus/1.56.21 (Linux; U; Android 12L; eureka-user Build/SQ3A.220605.009.A1) gzip',
      _ => 'com.google.android.youtube/20.10.38 (Linux; U; Android 11) gzip',
    };

    final httpClient = http.Client();
    try {
      var offset = startOffset;
      while (totalBytes <= 0 || offset < totalBytes) {
        final end = totalBytes > 0
            ? (offset + chunkSize - 1).clamp(offset, totalBytes - 1)
            : offset + chunkSize - 1;

        final request = http.Request('GET', streamInfo.url);
        request.headers['User-Agent'] = userAgent;
        request.headers['Range'] = 'bytes=$offset-$end';

        final response = await httpClient
            .send(request)
            .timeout(streamInactivityTimeout);

        if (response.statusCode >= 400) {
          throw YoutubeExplodeException(
            'Video returned ${response.statusCode} (stream: ${streamInfo.tag})',
          );
        }

        var segmentReceived = 0;
        await for (final chunk in response.stream.timeout(
          streamInactivityTimeout,
        )) {
          segmentReceived += chunk.length;
          offset += chunk.length;
          yield chunk;
        }

        if (segmentReceived == 0 || totalBytes <= 0) {
          break;
        }
      }
    } finally {
      httpClient.close();
    }
  }

  static VideoId? parseVideoId(String rawInput) {
    final trimmed = rawInput.trim();
    if (trimmed.isEmpty) return null;

    final direct = VideoId.parseVideoId(trimmed);
    if (direct != null) return VideoId(direct);

    final urlMatch = RegExp(r'https?://\S+').firstMatch(trimmed);
    if (urlMatch != null) {
      final extracted = VideoId.parseVideoId(urlMatch.group(0)!);
      if (extracted != null) return VideoId(extracted);
    }

    final liveOrShortsMatch = RegExp(
      r'(?:youtube\.com/(?:shorts|live)/|youtu\.be/)([a-zA-Z0-9_-]{11})',
    ).firstMatch(trimmed);
    if (liveOrShortsMatch != null) {
      return VideoId(liveOrShortsMatch.group(1)!);
    }

    return null;
  }

  static String userMessage(Object error) {
    if (error is FormatException) {
      return 'Lien YouTube invalide. Vérifiez l’URL puis réessayez.';
    }
    if (error is RequestLimitExceededException) {
      return 'YouTube limite temporairement les requêtes de cette connexion. '
          'Patientez quelques minutes, puis réessayez sans VPN.';
    }
    if (error is VideoUnavailableException) {
      return 'Cette vidéo est privée, supprimée ou indisponible dans votre région.';
    }
    if (error is VideoUnplayableException) {
      return 'YouTube ne permet pas d’accéder aux flux de cette vidéo '
          '(restriction d’âge, direct ou contenu protégé).';
    }

    final details = error.toString().toLowerCase();
    if (error is TimeoutException ||
        details.contains('403') ||
        details.contains('forbidden') ||
        details.contains('no chunks')) {
      return 'YouTube n’a pas délivré le flux demandé. Réessayez dans un '
          'instant ; la disponibilité peut varier selon la vidéo et le réseau.';
    }
    if (details.contains('socket') ||
        details.contains('connection') ||
        details.contains('network')) {
      return 'Connexion à YouTube impossible. Vérifiez le réseau, puis réessayez.';
    }
    return 'Impossible de récupérer cette vidéo pour le moment.';
  }
}
