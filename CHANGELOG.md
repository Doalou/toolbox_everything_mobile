# Changelog

Toutes les modifications notables de ce projet seront documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère au [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.4] - 2025-08-09

### Ajouté
- **YouTube Downloader**: section « Audio seul » clairement séparée sous « Vidéo + Audio » avec bouton « Télécharger la meilleure » par groupe.
- **QR Code**: export direct en PDF (avec prévisualisation possible via partage), bouton en plus des actions existantes.
- **YouTube Downloader**: bouton « Ouvrir le dossier » (rapide), action « Coller l’URL », et champ de saisie intégré dans l’en-tête.
 - **YouTube Downloader**: texte d’aide « Téléchargez vos vidéos et musiques préférées » déplacé au‑dessus du champ de lien pour une meilleure lisibilité.
 - **YouTube Downloader**: téléchargements en arrière‑plan avec notifications de progression, annulation et relance rapide.
 - **YouTube Downloader**: presets rapides de formats (MP4 720p, MP4 1080p, M4A 128/256 kbps).
- **Système**: initialisation du service de notifications au démarrage (flutter_local_notifications).

### Modifié
- **YouTube Downloader**: fiabilisation de la fusion automatique via FFmpeg (meilleure sélection audio/vidéo, gestion de noms uniques).
- **YouTube Downloader**: zone de saisie agrandie (padding, hauteur minimale et taille d’icône augmentés) pour un confort d’usage.
 - **UI Globale**: hauteur minimale uniformisée des boutons (52px) via le thème pour une meilleure cohérence visuelle.
- **Android**: ajout de la permission `POST_NOTIFICATIONS` (Android 13+) dans le manifeste.
- **QR Code**: mise en page des boutons avec Wrap pour éviter les débordements sur petits écrans.
- **UX/Code**: migration large de `.withOpacity()` vers `.withValues(alpha: ...)` pour éviter la perte de précision couleur (Flutter 3.22+).
- **Générateur de MDP**: délai d'affichage de l'historique porté de 5s à 15s (20 derniers éléments).

### Corrigé
- Message de fin de téléchargement: correction du nom de fichier affiché (suppression de la référence à `fileName` inexistante).
- Convertisseur binaire: conversions maintenant instantanées lors de la saisie (suppression des listeners redondants, garde de ré-entrée).
- Lints: suppression des imports inutilisés, des interpolations avec accolades inutiles, et variables locales non utilisées.

---

## [0.2.3] - 2025-08-08

### Ajouté
- QR Code: bouton “Copier” copie désormais l’image PNG du QR dans le presse‑papiers (support multi‑plateformes).
- Paramètres: option “Verrouiller le niveau à bulle en portrait” (persistante).

### Modifié
- **YouTube Downloader**:
    - Refonte complète de l'interface de téléchargement audio.
    - Les pistes "Audio seul" sont désormais regroupées par codec (ex: OPUS, AAC) avec un bouton "Télécharger la meilleure" pour chaque groupe.
    - Correction des débordements d'interface (RenderFlex overflow) sur les boutons de téléchargement pour les écrans de petite taille.
- Boussole: UX inversée – la rose tourne et l’aiguille reste fixe pour une lecture plus naturelle.
- Convertisseur binaire: corrections de fiabilité (prévention des boucles de listeners) et padding des champs pour éviter le texte collé aux bords.
- Testeur de connexion: meilleure robustesse de détection (ipapi/ipwhois/ipinfo/ifconfig avec User‑Agent), scroll sans rebond.
- Scroll global: suppression des effets d’overscroll/glow.
- Paramètres: refonte de la page (sections claires, défilement sans rebond, suppression des animations d’entrée) et affichage de la version avec build (ex: 0.2.3+7).
- QR Code: suppression du bouton “Copier texte”.

### Corrigé
- **Build Android Critique**:
    - Remplacement de la dépendance `ffmpeg_kit_flutter_min_gpl` (cassée) par `ffmpeg_kit_flutter_new` pour résoudre les erreurs de résolution de dépendances natives (`Could not find com.arthenica:ffmpeg-kit-min-gpl`).
    - Augmentation de la `minSdkVersion` Android à 24 pour assurer la compatibilité avec les nouvelles dépendances.
    - Résolution des conflits de dépendances transitives en passant à la dernière version stable de `ffmpeg_kit_flutter_new` (`^3.1.0`).
- YouTube Downloader: écrit dans le dossier externe de l’app (Android) pour éviter les permissions de stockage; message de fin avec chemin du fichier.
- Niveau à bulle: verrouillage d’orientation en portrait pendant l’utilisation.

---

## [0.2.2] - 2025-07-27

### 🔧 Corrigé
- **Téléchargeur de médias** : Correction du plugin `open_file_plus` obsolète
  - Remplacement par `open_file: ^3.5.10` pour compatibilité Flutter moderne
  - Résolution des erreurs de compilation Android liées à l'API `PluginRegistry.Registrar`
  - Mise à jour des imports dans `downloader_screen.dart`

### 🎨 Amélioré
- **Interface utilisateur** : Nettoyage et optimisation de l'interface principale
  - Suppression de la section "Quick Stats" (100% Offline, 0€ Gratuit, etc.)
  - Élimination des badges colorés du header (100% Offline, Gratuit, Sécurisé)
  - Interface plus épurée et professionnelle
  - Navigation directe vers les outils sans éléments distractifs

### 🧹 Nettoyé
- **Code** : Suppression du code inutilisé
  - Méthode `_buildQuickStats()` supprimée
  - Méthode `_buildStatItem()` supprimée  
  - Méthode `_buildFeatureBadge()` supprimée
  - Réduction de la complexité du code et amélioration des performances

### 📱 Optimisations
- **Performance** : Amélioration des performances de l'application
  - Moins de widgets à rendre = interface plus fluide
  - Code plus léger et maintenable
  - Compilation plus rapide

---

## [0.2.1] - Version précédente

### Ajouté
- Fonctionnalités initiales de l'application
- Outils de base (générateur de mots de passe, QR Code, etc.)
- Interface utilisateur moderne avec animations

### Modifié
- Améliorations de l'interface utilisateur
- Optimisations de performance

---

## [0.1.0] - Version initiale

### Ajouté
- Application Toolbox Everything Mobile
- Collection d'outils numériques essentiels
- Interface moderne et responsive
- Support multi-plateformes (Android, iOS, Web)
