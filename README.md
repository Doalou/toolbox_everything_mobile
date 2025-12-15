# 🧰 Toolbox Everything Mobile

**Version 1.1.0** - Votre boîte à outils numérique complète et moderne

Une application Flutter élégante qui regroupe tous vos outils numériques essentiels en une seule application. Conçue avec Material Design 3 et optimisée pour une expérience utilisateur exceptionnelle.

## 🆕 Dernières mises à jour (v1.1.0)

### ✨ Nouvelles fonctionnalités
- **🎨 Sélecteur de couleurs** : Roue chromatique, export HEX/RGB/RGBA/HSL, historique persistant des couleurs
- **🔐 Encodeur/Décodeur** : Base64, URL, HTML entities, Hexadécimal avec toggle encode ↔ decode

### 🚀 Migration Flutter 3.38 / Dart 3.10
- SDK mis à jour vers Dart 3.10.0
- Modernisation du code Flutter (nouvelles APIs, dépréciations corrigées)

### 🔧 Corrections techniques
- **Téléchargeur de médias** : Correction du plugin obsolète `open_file_plus` → `open_file: ^3.5.10`
- **Compatibilité Android** : Résolution des erreurs de compilation liées à l'API Flutter moderne
- **Build Web** : évite les échecs liés aux imports `dart:io`/FFmpeg sur le Web via un stub conditionnel

## ✨ Fonctionnalités

### 🔐 Sécurité & Cryptographie
- **Générateur de mots de passe** avec indicateur de force et options avancées
- **Calculateur de hash** (MD5, SHA256, SHA512) pour texte et hexadécimal
- **Générateur QR Code** avec scanner intégré
- **Encodeur/Décodeur** Base64, URL, HTML, Hexadécimal

### 🔧 Utilitaires
- **Convertisseur d'unités** (longueur, poids, température, données)
- **Convertisseur de nombres** (binaire, décimal, hexadécimal, octal)
- **Convertisseur de fichiers** (JSON ↔ YAML, CSV, XML)
- **Téléchargeur YouTube** avec support audio et vidéo
- **Sélecteur de couleurs** avec export HEX/RGB/RGBA/HSL

### 📱 Outils mobiles
- **Boussole** avec interface moderne et direction précise
- **Niveau à bulle** utilisant les capteurs du téléphone
- **Minuteur** avec alarmes et notifications

### 📝 Productivité
- **Bloc-notes** avec sauvegarde automatique
- **Générateur Lorem Ipsum** personnalisable
- **Gestionnaire de paramètres** avec thèmes multiples

## 🎨 Design & Interface

### Material Design 3
- **Interface moderne** avec couleurs expressives
- **Thème sombre/clair** adaptatif
- **Animations fluides** et transitions élégantes
- **Accessibilité** optimisée avec labels sémantiques

### Couleurs expressives
8 palettes de couleurs dynamiques :
- Violet principal (#6750A4)
- Rose dynamique (#E91E63)
- Cyan moderne (#00BCD4)
- Vert nature (#4CAF50)
- Orange énergique (#FF9800)
- Violet créatif (#9C27B0)
- Bleu technologique (#2196F3)
- Rouge passion (#FF5722)

## 📱 Plateformes supportées

- ✅ **Android** (API 21+)
- ✅ **iOS** (iOS 12+)
- ✅ **Windows** (Windows 10+)
- ✅ **macOS** (macOS 10.14+)
- ✅ **Linux** (Ubuntu 18.04+)
- ✅ **Web** (PWA support)

## 🚀 Installation

### Prérequis
- Flutter SDK 3.8.1+
- Dart 3.0+
- Android Studio / VS Code
- Git

### Étapes d'installation

1. **Cloner le projet**
```bash
git clone https://github.com/Doalou/toolbox_everything_mobile.git
cd toolbox_everything_mobile
```

2. **Installer les dépendances**
```bash
flutter pub get
```

3. **Configurer les plateformes**
```bash
# Pour Android
flutter config --android-studio-dir <path-to-android-studio>

# Pour iOS (macOS uniquement)
cd ios && pod install && cd ..
```

4. **Lancer l'application**
```bash
# Mode debug
flutter run

# Mode release
flutter run --release

# Pour une plateforme spécifique
flutter run -d windows
flutter run -d macos
flutter run -d chrome
```

## 🏗️ Architecture du projet

```
lib/
├── core/
│   ├── constants/         # Constantes de l'application
│   ├── models/           # Modèles de données
│   ├── providers/        # Gestionnaires d'état (Provider)
│   └── services/         # Services métier
├── presentation/
│   ├── screens/          # Écrans de l'application
│   ├── widgets/          # Widgets réutilisables
│   └── theme/           # Configuration des thèmes
└── main.dart            # Point d'entrée
```

## 🔧 Configuration

### Permissions requises

#### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.VIBRATE" />
```

#### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSCameraUsageDescription</key>
<string>Pour scanner les codes QR</string>
<key>NSMicrophoneUsageDescription</key>
<string>Pour les fonctionnalités audio</string>
```

## 📦 Dépendances principales

### Interface & État
- **`provider`** - Gestion d'état
- **`dynamic_color`** - Couleurs dynamiques (Material You)
- **`animate_do`** & **`flutter_staggered_animations`** - Animations
- **`shimmer`** & **`lottie`** - Effets visuels et de chargement
- **`auto_size_text`** - Texte responsive

### Fonctionnalités
- **`qr_flutter`** & **`mobile_scanner`** - QR Codes
- **`flutter_compass`** & **`sensors_plus`** - Capteurs (boussole, niveau)
- **`crypto`** - Cryptographie (hash)
- **`youtube_explode_dart`** - Téléchargement YouTube
- **`ffmpeg_kit_flutter_new`** - Traitement média
- **`pdf`** & **`printing`** - Génération de documents

### Utilitaires
- **`url_launcher`** - Ouverture d'URL
- **`shared_preferences`** - Stockage local simple
- **`path_provider`** & **`file_picker`** - Gestion de fichiers
- **`permission_handler`** - Permissions natives
- **`clipboard`** & **`super_clipboard`** - Gestion du presse-papiers
- **`flutter_local_notifications`** - Notifications locales
- **`connectivity_plus`** - Vérification de la connectivité

## 🛠️ Scripts de développement

### Analyse du code
```bash
# Analyse statique
flutter analyze

# Vérifier les dépendances obsolètes
flutter pub outdated

# Mettre à jour les dépendances
flutter pub upgrade
```

### Tests
```bash
# Tests unitaires
flutter test

# Tests d'intégration
flutter drive --target=test_driver/app.dart
```

### Build & Release

#### Android
```bash
# APK Debug
flutter build apk --debug

# APK Release
flutter build apk --release

# App Bundle (Google Play)
flutter build appbundle --release
```

#### iOS
```bash
# iOS Debug
flutter build ios --debug

# iOS Release
flutter build ios --release
```

#### Desktop
```bash
# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

#### Web
```bash
# Web
flutter build web --release
```

## 🎯 Fonctionnalités avancées

### Accessibilité
- **Labels sémantiques** sur tous les éléments interactifs
- **Support VoiceOver/TalkBack** complet
- **Contraste** optimisé pour tous les thèmes
- **Navigation clavier** fluide

### Performance
- **Lazy loading** des écrans
- **Optimisation des rebuilds** avec Provider
- **Images optimisées** multi-résolution
- **Code splitting** automatique

### Sécurité
- **Chiffrement local** des données sensibles
- **Validation** stricte des entrées utilisateur
- **Protection** contre les injections
- **Random cryptographique** sécurisé

## 🔧 Personnalisation

### Ajouter un nouvel outil

1. **Créer l'écran** dans `lib/presentation/screens/`
2. **Ajouter le modèle** dans `lib/core/models/tool_item.dart`
3. **Enregistrer l'outil** dans `lib/presentation/screens/home_screen.dart`

Exemple :
```dart
ToolItem(
  title: 'Mon nouvel outil',
  icon: Icons.new_tool,
  screenBuilder: () => const MonNouvelOutilScreen(),
),
```

### Modifier les couleurs
```dart
// Dans AppConstants
static const List<Color> expressiveColors = [
  Color(0xFF6750A4), // Votre couleur
  // ... autres couleurs
];
```

## 🐛 Dépannage

### Problèmes courants

#### Build Android échoue
```bash
flutter clean
flutter pub get
cd android && ./gradlew clean && cd ..
flutter run
```

#### Permissions iOS
Vérifiez que toutes les permissions sont déclarées dans `Info.plist`

#### Performance lente
```bash
flutter run --profile
flutter run --release
```

#### Erreurs de dépendances
```bash
flutter pub deps
flutter pub upgrade --major-versions
```

## 📄 License

Ce projet est sous licence MIT.

## 🤝 Contribution

Les contributions sont les bienvenues ! Voici comment contribuer :

1. **Fork** le projet
2. **Créer** une branche pour votre fonctionnalité
3. **Commiter** vos changements
4. **Pousser** vers la branche
5. **Ouvrir** une Pull Request

### Guidelines
- Suivre les conventions Dart/Flutter
- Ajouter des tests pour les nouvelles fonctionnalités
- Maintenir la couverture de code
- Documenter les changements

## 📞 Support

- **Email** : contact@doalo.fr
- **Issues** : Utilisez le système d'issues GitHub

---

**Développé avec ❤️ en Flutter**

*Toolbox Everything Mobile - Tous vos outils en une seule application*
