import 'package:flutter/material.dart';
import 'package:toolbox_everything_mobile/core/feature_flags/app_feature_flags.dart';
import 'package:toolbox_everything_mobile/core/models/tool_item.dart';
import 'package:toolbox_everything_mobile/presentation/screens/bubble_level_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/color_picker_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/compass_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/connection_tester_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/downloader_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/essentials/json_formatter_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/essentials/jwt_decoder_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/essentials/regex_tester_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/essentials/text_diff_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/essentials/timestamp_converter_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/essentials/uuid_generator_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/file_converter_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/hash_calculator_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/lorem_generator_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/notes_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/number_converter_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/password_generator_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/qr_code_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/text_encoder_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/timer_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/unit_converter_screen.dart';

/// Catalogue centralisé des outils. Filtre par feature flags et fournit
/// la liste utilisée par le dashboard et la recherche.
class ToolCatalog {
  ToolCatalog._();

  static List<ToolItem> all() {
    final List<ToolItem> tools = [
      // --- Essentiels ---------------------------------------------------
      ToolItem(
        title: 'Générateur de MDP',
        subtitle: 'Mots de passe robustes',
        icon: Icons.password_rounded,
        screenBuilder: (h) => PasswordGeneratorScreen(heroTag: h),
        heroTag: 'password-generator-hero',
        category: ToolCategory.essentials,
        tags: const ['Local', 'Offline'],
      ),
      ToolItem(
        title: 'QR Code',
        subtitle: 'Générer & scanner',
        icon: Icons.qr_code_rounded,
        screenBuilder: (h) => QrCodeScreen(heroTag: h),
        heroTag: 'qr-code-hero',
        category: ToolCategory.essentials,
        tags: const ['Local'],
      ),
      ToolItem(
        title: 'Calculateur Hash',
        subtitle: 'MD5, SHA-1, SHA-256…',
        icon: Icons.fingerprint_rounded,
        screenBuilder: (h) => HashCalculatorScreen(heroTag: h),
        heroTag: 'hash-calculator-hero',
        category: ToolCategory.essentials,
        tags: const ['Local', 'Offline'],
      ),
      ToolItem(
        title: 'Encodeur / Décodeur',
        subtitle: 'Base64, URL, HTML',
        icon: Icons.code_rounded,
        screenBuilder: (h) => TextEncoderScreen(heroTag: h),
        heroTag: 'text-encoder-hero',
        category: ToolCategory.essentials,
        tags: const ['Local', 'Offline'],
      ),
      if (AppFeatureFlags.jsonFormatter)
        ToolItem(
          title: 'JSON Formatter',
          subtitle: 'Indenter, minifier',
          icon: Icons.data_object_rounded,
          screenBuilder: (h) => JsonFormatterScreen(heroTag: h),
          heroTag: 'json-formatter-hero',
          category: ToolCategory.essentials,
          tags: const ['Offline', 'Nouveau'],
        ),
      if (AppFeatureFlags.uuidGenerator)
        ToolItem(
          title: 'UUID',
          subtitle: 'Générateur v4',
          icon: Icons.qr_code_2_rounded,
          screenBuilder: (h) => UuidGeneratorScreen(heroTag: h),
          heroTag: 'uuid-generator-hero',
          category: ToolCategory.essentials,
          tags: const ['Offline', 'Nouveau'],
        ),
      if (AppFeatureFlags.timestampConverter)
        ToolItem(
          title: 'Timestamp',
          subtitle: 'Epoch ↔ date',
          icon: Icons.schedule_rounded,
          screenBuilder: (h) => TimestampConverterScreen(heroTag: h),
          heroTag: 'timestamp-hero',
          category: ToolCategory.essentials,
          tags: const ['Offline', 'Nouveau'],
        ),
      if (AppFeatureFlags.jwtDecoder)
        ToolItem(
          title: 'JWT Decoder',
          subtitle: 'Header & payload',
          icon: Icons.vpn_key_rounded,
          screenBuilder: (h) => JwtDecoderScreen(heroTag: h),
          heroTag: 'jwt-decoder-hero',
          category: ToolCategory.essentials,
          tags: const ['Offline', 'Nouveau'],
        ),
      if (AppFeatureFlags.regexTester)
        ToolItem(
          title: 'Regex tester',
          subtitle: 'Tester des patterns',
          icon: Icons.find_in_page_rounded,
          screenBuilder: (h) => RegexTesterScreen(heroTag: h),
          heroTag: 'regex-tester-hero',
          category: ToolCategory.essentials,
          tags: const ['Offline', 'Nouveau'],
        ),
      if (AppFeatureFlags.textDiff)
        ToolItem(
          title: 'Diff texte',
          subtitle: 'Comparer 2 textes',
          icon: Icons.compare_arrows_rounded,
          screenBuilder: (h) => TextDiffScreen(heroTag: h),
          heroTag: 'text-diff-hero',
          category: ToolCategory.essentials,
          tags: const ['Offline', 'Nouveau'],
        ),
      ToolItem(
        title: 'Lorem Ipsum',
        subtitle: 'Texte de remplissage',
        icon: Icons.text_snippet_rounded,
        screenBuilder: (h) => LoremGeneratorScreen(heroTag: h),
        heroTag: 'lorem-ipsum-hero',
        category: ToolCategory.essentials,
        tags: const ['Offline'],
      ),
      ToolItem(
        title: 'Sélecteur Couleurs',
        subtitle: 'HEX, RGB, HSL',
        icon: Icons.palette_rounded,
        screenBuilder: (h) => ColorPickerScreen(heroTag: h),
        heroTag: 'color-picker-hero',
        category: ToolCategory.essentials,
        tags: const ['Local'],
      ),

      // --- Convertisseurs ----------------------------------------------
      ToolItem(
        title: 'Convertisseur d\'unités',
        subtitle: 'Longueur, masse, temp.',
        icon: Icons.swap_horiz_rounded,
        screenBuilder: (h) => UnitConverterScreen(heroTag: h),
        heroTag: 'unit-converter-hero',
        category: ToolCategory.converters,
        tags: const ['Offline'],
      ),
      ToolItem(
        title: 'Convertisseur binaire',
        subtitle: 'Texte ↔ bin/hex/dec',
        icon: Icons.transform_rounded,
        screenBuilder: (h) => NumberConverterScreen(heroTag: h),
        heroTag: 'number-converter-hero',
        category: ToolCategory.converters,
        tags: const ['Offline'],
      ),

      // --- Capteurs (Android/iOS uniquement) ---------------------------
      if (AppFeatureFlags.compass)
        ToolItem(
          title: 'Boussole',
          subtitle: 'Magnétomètre',
          icon: Icons.explore_rounded,
          screenBuilder: (h) => CompassScreen(heroTag: h),
          heroTag: 'compass-hero',
          category: ToolCategory.sensors,
          tags: const ['Capteur'],
        ),
      if (AppFeatureFlags.bubbleLevel)
        ToolItem(
          title: 'Niveau à bulle',
          subtitle: 'Accéléromètre',
          icon: Icons.architecture_rounded,
          screenBuilder: (h) => BubbleLevelScreen(heroTag: h),
          heroTag: 'bubble-level-hero',
          category: ToolCategory.sensors,
          tags: const ['Capteur'],
        ),

      // --- Médias -------------------------------------------------------
      ToolItem(
        title: 'Convertisseur de fichiers',
        subtitle: 'JSON, YAML, CSV, MD…',
        icon: Icons.file_copy_rounded,
        screenBuilder: (h) => FileConverterScreen(heroTag: h),
        heroTag: 'file-converter-hero',
        category: ToolCategory.media,
        tags: const ['Local'],
      ),
      if (AppFeatureFlags.youtubeDownloader)
        ToolItem(
          title: 'Téléchargeur',
          subtitle: 'YouTube audio/vidéo',
          icon: Icons.download_rounded,
          screenBuilder: (h) => DownloaderScreen(heroTag: h),
          heroTag: 'downloader-hero',
          category: ToolCategory.media,
          tags: const ['Réseau'],
        ),

      // --- Réseau ------------------------------------------------------
      ToolItem(
        title: 'Test connexion',
        subtitle: 'Type & latence HTTP',
        icon: Icons.wifi_rounded,
        screenBuilder: (h) => ConnectionTesterScreen(heroTag: h),
        heroTag: 'connection-tester-hero',
        category: ToolCategory.network,
        tags: const ['Réseau'],
      ),

      // --- Productivité ------------------------------------------------
      ToolItem(
        title: 'Bloc-notes',
        subtitle: 'Notes locales',
        icon: Icons.note_alt_rounded,
        screenBuilder: (h) => NotesScreen(heroTag: h),
        heroTag: 'notes-hero',
        category: ToolCategory.productivity,
        tags: const ['Local'],
      ),
      ToolItem(
        title: 'Minuteur',
        subtitle: 'Compte à rebours',
        icon: Icons.timer_rounded,
        screenBuilder: (h) => TimerScreen(heroTag: h),
        heroTag: 'timer-hero',
        category: ToolCategory.productivity,
        tags: const ['Local'],
      ),
    ];
    return tools;
  }
}
