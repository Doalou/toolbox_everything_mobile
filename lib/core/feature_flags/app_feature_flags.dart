import 'dart:io';

/// Feature flags applicatifs.
///
/// Permet de désactiver proprement certaines fonctionnalités selon :
/// - les politiques de stores (App Store / Play Store)
/// - la disponibilité de dépendances natives
/// - la plateforme (Android / iOS)
/// - des choix de build (debug, beta, release)
///
/// Toutes les valeurs sont **statiques** : un build donné a une configuration
/// figée. Si une fonctionnalité est désactivée, l'écran correspondant doit
/// afficher un état explicatif (StatusBanner « À venir » / « Indisponible »)
/// plutôt que de masquer l'entrée.
class AppFeatureFlags {
  AppFeatureFlags._();

  // --- Téléchargeur YouTube ---------------------------------------------
  /// Active le téléchargeur YouTube (`youtube_explode_dart`).
  /// Les politiques d'App Store/Play Store changent — vérifier avant publication.
  static const bool youtubeDownloader = true;

  /// Permet le téléchargement de la **vidéo** (et donc la fusion audio/vidéo).
  /// Dépend de FFmpeg.
  static const bool youtubeVideoDownload = true;

  // --- Conversion média -------------------------------------------------
  /// Conversion vidéo locale via FFmpeg Kit (LGPL — vérifier les codecs).
  static const bool ffmpegVideoConversion = true;

  /// Conversion image locale (toujours dispo).
  static const bool imageConversion = true;

  // --- Capteurs ---------------------------------------------------------
  /// Boussole (`flutter_compass`). iOS Simulator ne fournit pas de magnétomètre.
  static bool get compass => Platform.isAndroid || Platform.isIOS;

  /// Niveau à bulle (accéléromètre via `sensors_plus`).
  static bool get bubbleLevel => Platform.isAndroid || Platform.isIOS;

  // --- Outils essentiels expérimentaux ----------------------------------
  static const bool jwtDecoder = true;
  static const bool regexTester = true;
  static const bool jsonFormatter = true;
  static const bool uuidGenerator = true;
  static const bool timestampConverter = true;
  static const bool textDiff = true;

  // --- PDF -------------------------------------------------------------
  /// Export PDF dans QR / file converter.
  static const bool pdfExport = true;

  // --- Notifications ----------------------------------------------------
  /// Notifications locales (download terminé).
  static const bool localNotifications = true;

  // --- Quick Actions ----------------------------------------------------
  /// Raccourcis app (long press sur l'icône).
  static const bool quickActions = true;
}
