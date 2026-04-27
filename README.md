# 🧰 Toolbox Everything Mobile

Votre boîte à outils numérique, locale-first et mobile-only.

Application **Flutter** Material 3 Expressive qui regroupe une vingtaine d'outils
utiles au quotidien : générateur de mots de passe, QR code, hash, JWT decoder,
formateur JSON, regex tester, capteurs, téléchargeur YouTube, conversion média,
diff texte, etc.

> 🎯 **Local-first.** La plupart des outils fonctionnent **sans Internet**, sans
> compte, sans backend. Les flux qui sortent de cette règle sont marqués
> explicitement (« Réseau »).

---

## 📱 Plateformes supportées

| Plateforme | Statut | Notes                                                  |
|------------|:------:|--------------------------------------------------------|
| Android    | ✅      | API 21+ (Android 5.0).                                 |
| iOS        | ✅      | iOS 13+.                                               |
| Desktop    | ❌      | Linux/Windows/macOS retirés en 0.3.0.                  |

L'application est pensée **mobile-first**. Les écrans s'adaptent aussi aux
tablettes Android et iPad, mais la priorité de design est le smartphone.

## ✨ Outils inclus (V1)

### Essentiels
- Générateur de mots de passe (force visuelle, options avancées).
- QR Code (générer + scanner + copier image).
- Calculateur Hash (MD5, SHA-1, SHA-256, SHA-512).
- Encodeur / Décodeur (Base64, URL, HTML, Hexadécimal).
- **JSON Formatter** — formater / minifier (nouveau en 0.3.0).
- **UUID v4** — génération en lot, validation (nouveau en 0.3.0).
- **Timestamp** — epoch ↔ ISO 8601 / local / UTC, horloge live (nouveau en 0.3.0).
- **JWT Decoder** — header / payload / signature, sans vérif. crypto (nouveau en 0.3.0).
- **Regex tester** — multi-ligne, casse, dot-all (nouveau en 0.3.0).
- **Diff texte** — comparaison ligne à ligne LCS (nouveau en 0.3.0).
- Lorem Ipsum, sélecteur de couleurs.

### Convertisseurs
- Unités (longueur, poids, température, volume, vitesse, surface, temps, données).
- Binaire / Hexadécimal / Décimal / Texte.

### Capteurs (Android / iOS uniquement)
- Boussole (`flutter_compass`).
- Niveau à bulle (`sensors_plus`).

### Média
- Conversion de fichiers (JSON ↔ YAML ↔ CSV, Markdown ↔ HTML, export PDF).
- Téléchargeur YouTube audio + vidéo (`youtube_explode_dart` + FFmpeg local).

### Réseau
- Test connexion : type (Wi-Fi / mobile / Ethernet / Satellite / VPN…), latence
  HTTP, infos publiques.

### Productivité
- Bloc-notes local, Minuteur.

> Les outils peuvent être désactivés au build via `lib/core/feature_flags/app_feature_flags.dart`
> — utile pour respecter une politique store sans cacher l'app entière.

## 🎨 Design — Material 3 Expressive

L'application embarque un **design system M3 Expressive** custom, isolé dans
`lib/core/design/` :

- `expressive_motion.dart` — durées et courbes (springs, emphasized, effects).
- `expressive_shapes.dart` — système de formes (rayons, formes asymétriques
  signature M3E, pill, dialog, bottom sheet).
- `expressive_tokens.dart` — espacements, élévations, palette saturée.
- `app_theme.dart` — `buildExpressiveTheme()` : builder pur de `ThemeData`,
  testable.

L'app supporte :

- thème clair / sombre / système ;
- couleurs dynamiques (`dynamic_color`) sur Android 12+ ;
- mode AMOLED noir pur ;
- transitions natives `PredictiveBackPageTransitionsBuilder` (Android) et
  `CupertinoPageTransitionsBuilder` (iOS).

Les widgets partagés (`lib/shared/widgets/`) reproduisent l'esprit M3 Expressive
sans dépendance tierce : `ExpressiveCard` (+ variante hero asymétrique),
`ExpressiveActionButton` (pill avec spring), `ExpressiveSectionHeader`,
`StatusBadge`, `StatusBanner`, `ExpressiveToolCard`.

## 🚀 Installation

### Prérequis
- Flutter SDK 3.41+ (Dart 3.11+).
- Android Studio / Xcode pour le build natif.

### Démarrer

```bash
git clone https://github.com/Doalou/toolbox_everything_mobile.git
cd toolbox_everything_mobile
flutter pub get
```

### Lancer

```bash
# Émulateur ou appareil branché
flutter run

# Choisir explicitement
flutter devices
flutter run -d <device-id>
```

### Tests & qualité

```bash
flutter analyze
flutter test
dart format lib test
```

### Build release

```bash
# Android — App Bundle pour Play Store
flutter build appbundle --release

# iOS — archive ouverte ensuite dans Xcode
flutter build ios --release
```

## 🏗️ Architecture

```
lib/
├── core/
│   ├── constants/         # AppConstants (alias vers les tokens design)
│   ├── design/            # Design system M3 Expressive (tokens, motion, shapes, theme)
│   ├── feature_flags/     # Toggles store-friendly
│   ├── models/            # ToolItem + ToolCategory
│   ├── providers/         # Provider (theme, settings, downloader)
│   ├── services/          # Services purs : json, uuid, jwt, timestamp, regex, diff, etc.
│   └── tool_catalog.dart  # Liste centralisée des outils
├── presentation/
│   ├── navigation/        # Helpers de navigation
│   ├── screens/           # Écrans (un par outil)
│   │   └── essentials/    # Sous-dossier pour les nouveaux outils 0.3.0
│   └── widgets/           # Widgets historiques (error_state, downloader)
├── shared/
│   └── widgets/           # Composants expressifs réutilisables
└── main.dart              # Bootstrap (providers + MaterialApp)

test/
├── services/              # 6 suites unitaires pour les nouveaux services
└── widget_test.dart       # Smoke test
```

Les services métier sont **purs** (aucune dépendance Flutter) — ils sont
testables en isolation.

## 🔐 Permissions

Android (`android/app/src/main/AndroidManifest.xml`) :

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.VIBRATE" />
```

iOS (`ios/Runner/Info.plist`) :

```xml
<key>NSCameraUsageDescription</key>
<string>Pour scanner les codes QR.</string>
```

## 📦 Dépendances clés

| Catégorie       | Paquets                                                                            |
|-----------------|------------------------------------------------------------------------------------|
| Thème           | `dynamic_color`                                                                    |
| État            | `provider`                                                                         |
| Capteurs        | `flutter_compass`, `sensors_plus`                                                  |
| Médias          | `youtube_explode_dart`, `ffmpeg_kit_flutter_new`, `mobile_scanner`, `qr_flutter`   |
| Documents       | `pdf`, `printing`, `file_picker`, `path_provider`                                  |
| Plateforme      | `permission_handler`, `connectivity_plus`, `flutter_local_notifications`           |
| Crypto / utils  | `crypto`, `clipboard`, `super_clipboard`, `shared_preferences`, `package_info_plus`|

## 📄 Licence & contact

- Politique de confidentialité : <https://doalo.fr/toolbox-everything/>
- Contact : `contact@doalo.fr`
- Code source : <https://github.com/Doalou/toolbox_everything_mobile>
