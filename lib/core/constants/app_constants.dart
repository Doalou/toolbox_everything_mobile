import 'package:material_ui/material_ui.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_tokens.dart';

/// Constantes globales de l'application.
class AppConstants {
  // Identité
  static const String version = '0.6.0';
  static const String contactEmail = 'contact@doalo.fr';

  // Espacements (alias vers ExpressiveTokens)
  static const double smallPadding = ExpressiveTokens.spacingSm;
  static const double defaultPadding = ExpressiveTokens.spacing;

  // Liens
  static const String privacyPolicyUrl =
      'https://toolbox.doalo.fr/confidentialite';
  static const String termsOfUseUrl =
      'https://toolbox.doalo.fr/conditions-utilisation';
  static const String sourceCodeUrl =
      'https://github.com/Doalou/toolbox_everything_mobile';

  /// Palette expressive — alias vers [ExpressivePalette.seeds].
  static const List<Color> expressiveColors = ExpressivePalette.seeds;

  // Messages
  static const String copySuccessMessage = 'Copié dans le presse-papiers';

  // Accessibilité
  static const String semanticCopyButton = 'Copier dans le presse-papiers';

  // Validation
  static const int minPasswordLength = 4;
  static const int maxPasswordLength = 128;
}

extension ExpressiveColorsExtension on List<Color> {
  Color getColorByHash(int hash) => this[hash.abs() % length];
  Color getColorByText(String text) => getColorByHash(text.hashCode);
}
