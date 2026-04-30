import 'package:flutter/material.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_motion.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_shapes.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_tokens.dart';

/// Constantes globales — proxy vers le design system Material 3 Expressive.
/// La source de vérité est désormais [ExpressiveTokens] / [ExpressiveShapes] /
/// [ExpressiveMotion]. Les alias ici existent pour la compatibilité interne
/// et simplifient les sites d'appel les plus fréquents.
class AppConstants {
  // Identité
  static const String appName = 'Toolbox Everything';
  static const String appDescription = 'Vos outils numériques essentiels';
  static const String version = '0.3.2';
  static const String contactEmail = 'contact@doalo.fr';

  // Espacements (alias vers ExpressiveTokens)
  static const double extraSmallPadding = ExpressiveTokens.spacingXs;
  static const double smallPadding = ExpressiveTokens.spacingSm;
  static const double defaultPadding = ExpressiveTokens.spacing;
  static const double largePadding = ExpressiveTokens.spacingLg;

  // Rayons (alias vers ExpressiveShapes)
  static const double smallBorderRadius = ExpressiveShapes.medium;
  static const double defaultBorderRadius = ExpressiveShapes.large;
  static const double largeBorderRadius = ExpressiveShapes.largeIncreased;

  static const double cardElevation = ExpressiveTokens.elevation0;
  static const double buttonElevation = ExpressiveTokens.elevation0;

  // Tailles d'icônes
  static const double smallIconSize = ExpressiveTokens.iconSm;
  static const double defaultIconSize = ExpressiveTokens.iconMd;
  static const double largeIconSize = ExpressiveTokens.iconLg;
  static const double extraLargeIconSize = ExpressiveTokens.iconXl;

  // Animations
  static const Duration shortAnimation = ExpressiveMotion.short4;
  static const Duration mediumAnimation = ExpressiveMotion.medium2;
  static const Duration longAnimation = ExpressiveMotion.long2;
  static const Curve defaultAnimationCurve = ExpressiveMotion.emphasized;

  // Liens
  static const String privacyPolicyUrl = 'https://doalo.fr/toolbox-everything/';
  static const String sourceCodeUrl =
      'https://github.com/Doalou/toolbox_everything_mobile';

  /// Palette expressive — alias vers [ExpressivePalette.seeds].
  static const List<Color> expressiveColors = ExpressivePalette.seeds;

  // Messages
  static const String copySuccessMessage = 'Copié dans le presse-papier !';
  static const String shareSuccessMessage = 'Partagé avec succès !';
  static const String saveSuccessMessage = 'Sauvegardé avec succès !';
  static const String deleteSuccessMessage = 'Supprimé avec succès !';

  static const String errorGenericMessage = 'Une erreur s\'est produite';
  static const String errorNetworkMessage = 'Erreur de connexion réseau';
  static const String errorPermissionMessage = 'Permission refusée';
  static const String errorStorageMessage = 'Erreur d\'accès au stockage';

  // Accessibilité
  static const String semanticCopyButton = 'Copier dans le presse-papier';
  static const String semanticShareButton = 'Partager';
  static const String semanticDeleteButton = 'Supprimer';
  static const String semanticBackButton = 'Retour';
  static const String semanticSettingsButton = 'Paramètres';
  static const String semanticInfoButton = 'Informations';

  // Regex
  static const String emailPattern =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String urlPattern =
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$';
  static const String hexPattern = r'^[0-9A-Fa-f]+$';

  // Validation
  static const int minPasswordLength = 4;
  static const int maxPasswordLength = 128;
  static const int maxTextInputLength = 10000;

  // Catégories d'outils
  static const String categorySensors = 'Capteurs';
  static const String categoryConverters = 'Convertisseurs';
  static const String categoryEssentials = 'Essentiels';
  static const String categoryMedia = 'Média';
  static const String categoryNetwork = 'Réseau';
  static const String categoryProductivity = 'Productivité';
}

extension ExpressiveColorsExtension on List<Color> {
  Color getColorByHash(int hash) => this[hash.abs() % length];
  Color getColorByText(String text) => getColorByHash(text.hashCode);
}

extension AnimationExtensions on Duration {
  int get inMillis => inMilliseconds;
}
