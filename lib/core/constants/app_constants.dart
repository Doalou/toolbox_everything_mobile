import 'package:flutter/material.dart';

/// Constantes de l'application pour une meilleure organisation du code
class AppConstants {
  // Informations de l'application
  static const String appName = 'Toolbox Everything';
  static const String appDescription = 'Vos outils numériques essentiels';
  static const String version = '0.2.3';
  static const String contactEmail = 'contact@doalo.fr';

  // Dimensions et espacements
  static const double defaultPadding = 16.0;
  static const double largePadding = 20.0;
  static const double smallPadding = 8.0;
  static const double extraSmallPadding = 4.0;

  static const double defaultBorderRadius = 16.0;
  static const double largeBorderRadius = 20.0;
  static const double smallBorderRadius = 12.0;

  static const double cardElevation = 0.0;
  static const double buttonElevation = 0.0;

  // Tailles d'icônes
  static const double defaultIconSize = 24.0;
  static const double largeIconSize = 32.0;
  static const double smallIconSize = 20.0;
  static const double extraLargeIconSize = 48.0;

  // Durées d'animation
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Couleurs expressives
  static const List<Color> expressiveColors = [
    Color(0xFF6750A4), // Violet principal
    Color(0xFFE91E63), // Rose dynamique
    Color(0xFF00BCD4), // Cyan moderne
    Color(0xFF4CAF50), // Vert nature
    Color(0xFFFF9800), // Orange énergique
    Color(0xFF9C27B0), // Violet créatif
    Color(0xFF2196F3), // Bleu technologique
    Color(0xFFFF5722), // Rouge passion
  ];

  // Messages
  static const String copySuccessMessage = 'Copié dans le presse-papier !';
  static const String shareSuccessMessage = 'Partagé avec succès !';
  static const String saveSuccessMessage = 'Sauvegardé avec succès !';
  static const String deleteSuccessMessage = 'Supprimé avec succès !';

  static const String errorGenericMessage = 'Une erreur s\'est produite';
  static const String errorNetworkMessage = 'Erreur de connexion réseau';
  static const String errorPermissionMessage = 'Permission refusée';
  static const String errorStorageMessage = 'Erreur d\'accès au stockage';

  // Labels pour l'accessibilité
  static const String semanticCopyButton = 'Copier dans le presse-papier';
  static const String semanticShareButton = 'Partager';
  static const String semanticDeleteButton = 'Supprimer';
  static const String semanticBackButton = 'Retour';
  static const String semanticSettingsButton = 'Paramètres';
  static const String semanticInfoButton = 'Informations';

  // Regex patterns
  static const String emailPattern =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String urlPattern =
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$';
  static const String hexPattern = r'^[0-9A-Fa-f]+$';

  // Contraintes de validation
  static const int minPasswordLength = 4;
  static const int maxPasswordLength = 128;
  static const int maxTextInputLength = 10000;

  // Catégories d'outils
  static const String categoryUtilities = 'Utilitaires';
  static const String categoryConversion = 'Conversion';
  static const String categorySecurity = 'Sécurité';
  static const String categoryProductivity = 'Productivité';
  static const String categoryMedia = 'Média';
}

/// Extensions pour faciliter l'utilisation des couleurs expressives
extension ExpressiveColorsExtension on List<Color> {
  /// Obtient une couleur basée sur un hash
  Color getColorByHash(int hash) {
    return this[hash.abs() % length];
  }

  /// Obtient une couleur basée sur un texte
  Color getColorByText(String text) {
    return getColorByHash(text.hashCode);
  }
}

/// Extensions pour les animations
extension AnimationExtensions on Duration {
  /// Convertit la durée en millisecondes
  int get inMillis => inMilliseconds;
}
