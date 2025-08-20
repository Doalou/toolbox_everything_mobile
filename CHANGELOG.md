# Changelog

Toutes les modifications notables de ce projet seront documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère au [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-07-28

### Ajouts
- **Téléchargeur YouTube en arrière-plan** : Les téléchargements continuent même si l'application est en arrière-plan, avec des notifications de progression.
- **Préréglages rapides pour le téléchargeur** : Téléchargez rapidement en MP4 (720p, 1080p) ou M4A (128kbps, 256kbps) en un clic.
- **Notifications système** : Des notifications claires pour le début, la progression, la réussite ou l'échec des téléchargements.
- **Mode économie de ressources** : Une nouvelle option dans les paramètres pour désactiver les animations et optimiser les performances sur les appareils moins puissants.
- **Support du Predictive Back Gesture** : Intégration de la navigation gestuelle prédictive d'Android pour une expérience plus fluide.
- **Dynamic Color (Material You)** : L'interface utilise désormais les couleurs du fond d'écran de l'utilisateur sur Android 12+ (activable dans les paramètres).
- **Edge-to-Edge Display** : L'application s'affiche en plein écran pour une meilleure immersion.
- **App Shortcuts** : Accès rapide aux outils "QR Code", "Téléchargeur" et "Convertisseur" depuis l'icône de l'application.
- **Contrôle des vibrations** : Ajout d'une option pour activer ou désactiver les retours haptiques.
- **Politique de confidentialité** : Ajout d'une politique de confidentialité accessible depuis l'écran "À propos".
- **Icônes de notification personnalisées** : Utilisation d'icônes dédiées pour les notifications de téléchargement et les raccourcis.

### Modifications
- **Amélioration de l'interface du téléchargeur** : Le champ de saisie de l'URL est plus grand et le texte d'aide a été déplacé pour une meilleure ergonomie.
- **Uniformisation des boutons** : Tous les boutons de l'application ont désormais une hauteur minimale de 52px pour une meilleure accessibilité et cohérence.
- **Optimisation des performances de l'interface** : Réduction de la qualité des miniatures et limitation du cache d'images pour économiser la mémoire.
- **Optimisation des transitions de page** : Les animations de transition entre l'écran d'accueil et les outils sont désormais plus rapides et fluides, corrigeant un bug qui causait plusieurs secondes de latence.

### Corrections
- **Correction des permissions Android** : L'application demande maintenant correctement la permission d'afficher des notifications sur Android 13+.
- **Correction d'une erreur de ressource d'icône** : Résolution d'un crash lié à une icône de notification manquante pour `flutter_local_notifications`.
- **Correction des animations de transition** : Les animations "Hero" entre l'accueil et les outils fonctionnent désormais correctement, éliminant les lenteurs.

## [1.0.0] - 2025-08-13

### Ajouté
- YouTube Downloader: affichage détaillé de la progression (Mo téléchargés/total), du débit (MB/s) et de l’ETA.
- Bouton « Ouvrir » proposé après la fin d’un téléchargement.
- Presets rapides: MP4 720p/1080p, M4A 128/256 kbps.
- Politique de confidentialité dédiée (`privacy/index.html`).
- Système: initialisation du service de notifications au démarrage (`flutter_local_notifications`).
- Android: sauvegarde automatique des fichiers téléchargés dans le dossier **Downloads** (MediaStore API 29+), avec fallback pré‑29.
- Notifications: création explicite du canal `downloads_channel` à l'initialisation.
- Tracking: enregistrement d’usage des outils (non bloquant) et chargement des favoris au démarrage.
- Matérial You (Android 12+): option pour activer les couleurs dynamiques système via les paramètres (désactive/grise le choix de thème).
- QR Code: export PDF et copie de l’image dans le presse‑papiers; UI modernisée.
- Générateur de MdP: historique auto affiché après 5s sur le même mot de passe.

### Modifié
- Refonte majeure du Téléchargeur YouTube (architecture simplifiée, sans isolate):
  - Téléchargements vidéo et audio exécutés en parallèle; progression combinée réelle.
  - Fusion FFmpeg fiable et journalisée (logs remontés en cas d’échec).
  - Identifiants de notification bornés à 32 bits pour compatibilité Android.
  - UI/UX modernisée (champ URL, presets, sections claires).
- Téléchargeur: ajout d’un bandeau d’intro Material You harmonisé; affichage du codec à côté de la taille; support MP3 (conversion) et sortie WEBM en fallback.
- Paramètres: AppBar.large M3, titre dynamique (primaire au repos, onSurface en scroll), bandeau d’intro, SegmentedButton compact; griser le sélecteur de thème sous Material You.
- Accueil: fond et bandeau harmonisés sur les couleurs dynamiques (primary/secondary/tertiary/surface).
 - Accueil: fond et bandeau harmonisés sur les couleurs dynamiques (primary/secondary/tertiary/surface). Entête modernisée et recherche épurée.
- Thème: intégration M3 expressif consolidée (Buttons/Inputs/Chips/ListTiles/Dialog/BottomSheet/SnackBar/NavBar), recolorisation via DynamicColor si activée.
- Convertisseur d'unités: refonte UI/UX (bandeau d'intro, catégories en chips, carte de conversion M3, bouton d'inversion des unités, champs avec copier/effacer).
- Thème des boutons: largeur minimale corrigée (`minimumSize: Size(0, 52)`) pour éviter les contraintes infinies.
- Uniformisation UI globale et optimisations de démarrage (SharedPreferences initialisées avant `runApp`).
- Android: ajout de la permission `POST_NOTIFICATIONS` (Android 13+).
- QR Code: mise en page des boutons avec Wrap pour éviter les débordements.
- UX/Code: migration de `.withOpacity()` vers `.withValues(alpha: ...)` (Flutter 3.22+).
- Générateur de MDP: délai d’historique porté à 15s (20 éléments).
- Optimisations performance: cache images réduit (~50 Mo), vignettes standardisées, throttling des notifications (téléchargements).
- Mode économie de ressources: désactivation/atténuation des animations et ombres (cards, header, widgets d’état) pour appareils modestes.
- Téléchargeur: compatibilité Web/Desktop via export conditionnel (stub web) et import universel dans le Provider.
- Tests: suppression du test widget par défaut (compteur) et ajout d’un smoke test minimal.

### Corrigé
- Téléchargeur YouTube: erreurs de layout `BoxConstraints forces an infinite width` (Rows/Wraps) corrigées.
- Téléchargeur YouTube: crashs liés aux isolates (`BackgroundIsolateBinaryMessenger`, `setMessageHandler`) éliminés en supprimant les isolates.
- Notifications: erreur « id doit tenir sur 32 bits » corrigée (ID borné) et progression normalisée (0–100).
- Fin de téléchargement: meilleure robustesse et logs FFmpeg disponibles pour diagnostic.
- Divers: nettoyage d’imports et corrections lints.
- Build Web: évite les échecs liés aux imports `dart:io`/FFmpeg sur le Web.
- Thème: corrections de types `CardThemeData`/`DialogThemeData` et suppression d’interpolations de TextStyle (désactivation animation de thème, recolorisation via copyWith).

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
 - Testeur de connexion: affichage simultané des adresses IPv4 et IPv6 avec mise en forme claire et sélectable.
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
