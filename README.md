# Toolbox Everything Mobile

[![Android CI](https://github.com/Doalou/toolbox_everything_mobile/actions/workflows/android.yml/badge.svg)](https://github.com/Doalou/toolbox_everything_mobile/actions/workflows/android.yml)
[![iOS CI](https://github.com/Doalou/toolbox_everything_mobile/actions/workflows/ios.yml/badge.svg)](https://github.com/Doalou/toolbox_everything_mobile/actions/workflows/ios.yml)
![Flutter](https://img.shields.io/badge/Flutter-3.47.9-02569B?logo=flutter)
![Version](https://img.shields.io/badge/version-0.5.1-2544D8)

La boîte à outils locale pour Android et iOS : générer, convertir, inspecter et
mesurer sans compte ni backend.

La majorité des fonctions travaillent directement sur l’appareil. Seuls le
téléchargeur et le diagnostic réseau contactent des services externes.

<p align="center">
  <img src="docs/screenshots/home-android.png" width="31%" alt="Accueil de Toolbox Everything Mobile 0.5.1">
  <img src="docs/screenshots/downloader-formats-android.png" width="31%" alt="Formats audio et vidéo proposés par le téléchargeur">
  <img src="docs/screenshots/about-android.png" width="31%" alt="Écran À propos de Toolbox Everything Mobile">
</p>

## Points clés

- **21 outils** réunis dans un catalogue recherchable et organisé par catégorie.
- **Local-first** pour les générateurs, convertisseurs, notes et capteurs.
- Thèmes clair, sombre, système et AMOLED avec prise en charge de Material You (`dynamic_color`).
- Design **Material 3 Expressive** associé à la typographie éditoriale **Fraunces**, aux formes asymétriques et aux couleurs distinctes par catégorie.
- Retours unifiés dans l’application (`AppFeedback` via `SnackBar` Material 3).
- Aucun compte utilisateur et aucune télémétrie applicative.

## Outils

| Catégorie | Outils | Réseau requis |
|---|---|:---:|
| Essentiels | Mots de passe, QR Code, hash, encodeur/décodeur, JSON, UUID, timestamp, JWT, regex, diff, Lorem Ipsum, couleurs | Non, sauf scan caméra |
| Convertisseurs | Unités, binaire/hexadécimal/décimal/texte | Non |
| Capteurs | Boussole, niveau à bulle | Non |
| Média | Conversion de fichiers, téléchargement audio/vidéo | Téléchargeur uniquement |
| Réseau | Type de connexion, IPv4/IPv6 publiques, localisation FAI, latence HTTP et débit mesuré | Oui |
| Productivité | Notes locales, minuteur et chronomètre | Non |

Les fonctions disponibles dans une release peuvent être contrôlées dans
`lib/core/feature_flags/app_feature_flags.dart` afin de respecter les
contraintes des stores.

## Plateformes

| Plateforme | Minimum | Validation CI |
|---|---:|:---:|
| Android | API 24 / Android 7.0 | Analyse, tests, goldens, APK debug, APK/AAB release sur `master` |
| iOS | iOS 15.5 | Analyse, tests et build simulateur sans signature |

Le design s’adapte aux téléphones et tablettes. Les projets desktop et Web ne
font pas partie de ce dépôt.

## Installation

### Prérequis

- Flutter `3.47.9` stable et Dart `3.13.7` ;
- Android Studio avec le SDK Android `37.0`, AGP `9.3.1`, Kotlin `2.3.20` (Built-in Kotlin), un JDK `21` et le NDK `28.2.13676358` ;
- Xcode récent et CocoaPods pour iOS (`IPHONEOS_DEPLOYMENT_TARGET = 15.5`) ;
- un émulateur ou un appareil physique.

```bash
git clone https://github.com/Doalou/toolbox_everything_mobile.git
cd toolbox_everything_mobile
flutter pub get
flutter run
```

Pour choisir une cible :

```bash
flutter devices
flutter run -d <device-id>
```

## Qualité et tests

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter test --coverage
```

La suite couvre les services purs (`FileConversionService`, `NetworkDiagnosticService`,
`YoutubeService`, `DownloadService`), les migrations de préférences, le catalogue,
le thème, les golden tests de l’accueil (`test/goldens/home_golden_test.dart`) et
les parcours essentiels. Les vérifications natives caméra, capteurs,
notifications, MediaStore et FFmpeg doivent également être exécutées sur
appareil avant une release.

## Builds

```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS — la signature est gérée ensuite dans Xcode
flutter build ios --release
```

Le workflow Android attend les secrets `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`,
`KEY_PASSWORD` et `KEY_ALIAS` pour produire les artefacts signés sur `master`.
Le bundle identifier iOS et l’applicationId Android sont `com.toolbox.everything.mobile`.

## Architecture

```text
lib/
├── core/
│   ├── constants/       # constantes applicatives et métadonnées
│   ├── design/          # tokens, formes asymétriques, mouvement et thème M3 Expressive
│   ├── feature_flags/   # capacités activées dans la release
│   ├── models/          # catalogue immuable et modèles
│   ├── providers/       # état Provider : thème, réglages, téléchargement
│   ├── services/        # logique métier, diagnostic réseau, conversions et médias
│   └── tool_catalog.dart
├── presentation/
│   ├── navigation/
│   ├── screens/         # accueil, à propos, paramètres et écrans des 21 outils
│   └── widgets/
├── shared/widgets/      # shell éditorial, cartes expressives et composants partagés
└── main.dart

test/
├── core/
├── goldens/             # tests visuels de non-régression de l'accueil
├── services/
└── widget_test.dart
```

Chaque outil possède un identifiant stable. Les favoris et statistiques des
versions antérieures, autrefois enregistrés avec le titre visible, sont migrés
automatiquement au premier démarrage.

## Design system

L’interface combine **Material 3 Expressive** et l’identité éditoriale de
[Toolbox Everything Web](https://github.com/Doalou/toolbox_everything) :

- titres **Fraunces** (romain et italique accentué) ;
- cartes héroïques à rayons asymétriques (`ExpressiveCard.hero`) ;
- teintes chromatiques dédiées par catégorie et par outil (`tonalSpot` sans rotation de teinte artificielle) ;
- écran d’accueil structuré avec couverture éditoriale, grille de catégories 2×3 compacte, raccourcis d’accès rapide et cartes d’outils épurées ;
- shell commun pour tous les outils, avec largeur de lecture adaptée aux
  téléphones et tablettes, en-têtes compacts et actions cohérentes ;
- contrôles et navigation adaptés aux conventions Android et iOS.

Fraunces est embarquée localement au format variable TTF sous licence SIL Open
Font License 1.1. La licence est disponible dans
`lib/assets/fonts/OFL.txt`.

## Stockage et permissions

### Android

- `INTERNET` et `ACCESS_NETWORK_STATE` pour les outils marqués Réseau ;
- `CAMERA` au moment d’ouvrir le scanner QR ;
- `POST_NOTIFICATIONS` au lancement d’un téléchargement ou d’un minuteur sur Android 13+ ;
- `WRITE_EXTERNAL_STORAGE` uniquement jusqu’à l’API 28 ;
- MediaStore à partir d’Android 10 pour enregistrer dans Téléchargements.

### iOS

- la caméra est décrite par `NSCameraUsageDescription` ;
- les notifications sont demandées au premier téléchargement ou minuteur ;
- les exports sont enregistrés dans Documents et exposés au sélecteur de
  fichiers iOS.

Les notes, favoris, statistiques d’usage et préférences sont stockés localement
avec `SharedPreferences`. Ils ne sont pas synchronisés vers un serveur.

## Confidentialité et limites

- Politique de confidentialité : <https://toolbox.doalo.fr/confidentialite>
- Conditions d'utilisation : <https://toolbox.doalo.fr/conditions-utilisation>
- Contact : `contact@doalo.fr`
- Code source : <https://github.com/Doalou/toolbox_everything_mobile>

Le téléchargement média dépend de services tiers, de FFmpeg et des formats
disponibles pour chaque contenu. L’utilisateur reste responsable du respect des
conditions d’utilisation, licences et droits d’auteur applicables.

Le téléchargeur repose sur les points d’accès Innertube utilisés par
`youtube_explode_dart`, pas sur l’API YouTube Data officielle. YouTube peut
modifier ses clients, ses limites et l’exigence de PO Tokens sans préavis : une
vidéo peut donc devenir temporairement indisponible ou répondre HTTP 403. La
version 0.5.1 chaîne automatiquement les profils `androidSdkless`, `android`,
`ios` et `androidVr` (sans dépendre des cookies de la page web par défaut), avec
repli sur `oEmbed` pour les métadonnées et téléchargement segmenté via l’en-tête
HTTP `Range` et régénération d’URL signée lors des fusions audio/vidéo.

## Licence

La police Fraunces est distribuée sous SIL OFL 1.1. Le dépôt mobile ne contient
pas encore de fichier `LICENSE` pour le code applicatif ; les droits restent
donc réservés à son auteur jusqu’à publication d’une licence explicite.
