import 'dart:async';

import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Centralise les choix de client et les garde-fous réseau liés à YouTube.
///
/// Le client par défaut de youtube_explode_dart 3.1.0 est `androidSdkless`.
/// Depuis le renforcement des PO Tokens par YouTube, il peut exposer des URLs
/// qui répondent 403 ou ne livrent aucun octet. Les clients ci-dessous sont des
/// profils HTTP YouTube simulés : ils ne dépendent pas de l'OS qui exécute Dart.
class YoutubeService {
  YoutubeService._();

  static const Duration _metadataTimeout = Duration(seconds: 20);
  static const Duration _manifestTimeout = Duration(seconds: 30);
  static const Duration streamInactivityTimeout = Duration(seconds: 25);

  static Future<Video> getVideo(YoutubeExplode youtube, VideoId videoId) {
    return youtube.videos.get(videoId).timeout(_metadataTimeout);
  }

  static Future<StreamManifest> getManifest(
    YoutubeExplode youtube,
    VideoId videoId,
  ) async {
    Object? lastError;
    StackTrace? lastStackTrace;

    // androidVr fonctionne sans PO Token sur les deux plateformes : son nom
    // décrit le client Innertube imité, pas l'appareil hôte. Le profil iOS est
    // conservé comme repli si YouTube refuse androidVr pour une vidéo donnée.
    final clients = [YoutubeApiClient.androidVr, YoutubeApiClient.ios];
    for (final client in clients) {
      try {
        return await youtube.videos.streams
            .getManifest(videoId, ytClients: [client])
            .timeout(_manifestTimeout);
      } catch (error, stackTrace) {
        lastError = error;
        lastStackTrace = stackTrace;
      }
    }

    Error.throwWithStackTrace(lastError!, lastStackTrace!);
  }

  static Stream<List<int>> getStream(
    YoutubeExplode youtube,
    StreamInfo streamInfo,
  ) {
    return youtube.videos.streams
        .get(streamInfo)
        .timeout(streamInactivityTimeout);
  }

  static String userMessage(Object error) {
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
