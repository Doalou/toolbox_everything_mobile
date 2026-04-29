# Changelog

Toutes les modifications notables de ce projet seront documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère au [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.1] - 2026-04-29

### Modifié

- **Accueil – barre du haut** : fond neutre du thème (`surface → surfaceContainerLowest →
  surfaceContainerLow`) habillé d'un motif décoratif inédit — une série d'arcs
  concentriques (effet ripple/onde) émergeant du coin bas-droit, peints au stroke
  avec le dégradé `#5c6ff4 → #e870c2` et une opacité décroissante vers l'extérieur,
  ponctués d'un petit point plein dégradé au point d'origine.
- **Accueil – titre "Toolbox"** : texte rendu avec un `ShaderMask` appliquant le
  dégradé `#5c6ff4 → #e870c2`, qui ressort clairement sur le fond neutre ;
  " Everything" reste en `onSurface` du thème pour la lisibilité.
- **Paramètres** : écran restructuré en sections plus lisibles avec un header compact,
  des réglages d’apparence clarifiés, un sélecteur clair/auto/sombre toujours disponible
  et un panneau d’accentuation dédié.
- **Identité Android** : les anciens `ic_launcher.png` hérités reprennent désormais
  l’icône Toolbox Everything, et les notifications du minuteur utilisent l’icône
  monochrome dédiée.
- **Build Android** : suppression ciblée des warnings Java `source/target value 8`
  émis par certaines tâches de plugins, sans masquer les autres diagnostics du
  compilateur.
- **Navigation** : les ouvertures d’outils utilisent désormais `MaterialPageRoute`
  de façon unifiée afin de préserver le geste Predictive Back sur toutes les entrées
  de navigation Android, y compris les raccourcis d’application.
- **Predictive Back** : les pages ouvertes depuis l’accueil, les cartes d’outils et
  les raccourcis d’application utilisent des routes Material natives, sans wrapper de
  retour supplémentaire, pour laisser Android piloter le geste prédictif.
- **À propos** : écran entièrement restructuré avec AppBar native, sections
  Application/Ressources, carte d’identité 0.3.1, liens et actions de contact plus
  lisibles, et e-mail de suggestion prérempli.
- **Accueil** : grille d’outils plus compacte, cartes moins hautes et bandeau favoris
  resserré pour réduire les espaces vides, avec des tuiles plus petites, plus
  sobres et une palette moins artificielle.
- **Paramètres** : ajout d’une action de réinitialisation de l’apparence pour revenir
  au thème auto, à l’accent par défaut et aux réglages visuels standards.
- **Cartes d’outils** : retrait des badges décoratifs (`Local`, `Offline`,
  `Sans compte`, catégories du header YouTube) dans les écrans et dans `À propos`,
  pour réduire le bruit visuel.
- **Démarrage** : initialisation différée des raccourcis d’application et des
  notifications après le premier rendu, avec notifications auto-initialisables à
  l’usage, afin de réduire le travail sur le thread UI au lancement.
- **À propos** : ajout d’un bouton de signalement de bug avec e-mail prérempli.
- **Cartes historiques** : rafraîchissement des cartes internes de plusieurs écrans
  pré-0.3.0 (`À propos`, sélecteur de couleurs, encodeur/décodeur, générateur de
  mot de passe, convertisseur d’unités) avec `ExpressiveCard`, icônes en pastilles
  et en-têtes plus lisibles.
- **Écrans anciens** : compactage des écrans bloc-notes temporaire, hash, lorem et
  minuteur pour réduire les en-têtes trop hauts et les espaces décoratifs.

### Corrigé

- **Couleur d’accentuation** : choisir une couleur personnalisée désactive maintenant
  automatiquement les couleurs dynamiques système, afin que le changement soit visible
  immédiatement.
- **Dashboard** : le `Hero` des cartes d’outils anime uniquement le titre au lieu de
  faire transiter toute la carte vers l’AppBar, ce qui évite les overflows `RenderFlex`
  signalés dans les logs.
- **Notifications minuteur** : référence d’icône Android alignée sur le service de
  notifications central.
- **Mode économie de ressources** : réparé et étendu.
  - Accueil : le nouvel effet ripple/onde du bandeau du haut n'est plus dessiné
    quand le mode est activé, le toggle est lu en temps réel
    (`context.select`) et la grille reste visible quand on bascule le mode
    pendant l'usage (auparavant, l'activation après chargement laissait les
    cartes à opacité 0 car le contrôleur de stagger restait à `value=0`).
  - Composants partagés : `ExpressiveCard`, `ExpressiveActionButton` et
    `ExpressiveToolCard` désactivent maintenant leur `AnimatedScale` de pression
    et leur splash/highlight `InkWell` quand le mode est activé, supprimant les
    rebonds spring et les ondes de tap sur tous les écrans.
  - Transitions de page : `PredictiveBackPageTransitionsBuilder` est remplacé
    par `FadeUpwardsPageTransitionsBuilder` (plus léger) sur Android quand le
    mode est activé.

## [0.3.0] - 2026-04-27

> Refonte UI majeure autour de **Material 3 Expressive**.
> L'application cible désormais **uniquement Android et iOS**.

### Ajouté

- **Design system Material 3 Expressive** isolé dans `lib/core/design/` :
  - `expressive_motion.dart` — tokens de durée et courbes (springs, emphasized, effects).
  - `expressive_shapes.dart` — système de formes (rayons, formes asymétriques signature M3E, pill, dialog, bottom sheet).
  - `expressive_tokens.dart` — espacements, élévations, palette `ExpressivePalette` plus saturée.
  - `app_theme.dart` — `buildExpressiveTheme()`, builder pur de `ThemeData` (testable).
- **6 nouveaux outils Essentiels**, tous offline / locaux :
  - **JSON Formatter** (formater / minifier, indent 2 ou 4).
  - **UUID v4** (génération en lot 1–100, validation, copie groupée).
  - **Timestamp** (epoch s/ms ↔ ISO 8601 / local / UTC, horloge live).
  - **JWT Decoder** (header / payload / signature, sans vérif. crypto, alerte d'expiration).
  - **Regex tester** (multi-ligne, sensibilité casse, dot-all, jusqu'à 50 matchs affichés).
  - **Diff texte** (LCS classique, ajouts / suppressions, surlignage).
- **Widgets partagés** dans `lib/shared/widgets/` :
  - `ExpressiveCard` (+ variante `hero` à coins asymétriques).
  - `ExpressiveActionButton` (bouton pill avec spring sur la pression).
  - `ExpressiveSectionHeader`, `StatusBadge` (Local, Offline, Bêta, Permission…), `StatusBanner`.
  - `ExpressiveToolCard` — nouvelle carte d'outil avec spring + icône en bulle pill colorée.
- **Feature flags** dans `lib/core/feature_flags/app_feature_flags.dart`
  (toggles store-friendly pour le téléchargeur YouTube, FFmpeg, capteurs, outils expérimentaux…).
- **Catalogue d'outils centralisé** (`lib/core/tool_catalog.dart`) avec catégories
  (Capteurs, Convertisseurs, Essentiels, Média, Réseau, Productivité), sous-titres, tags.
- **Tests unitaires** pour les 6 nouveaux services (`test/services/`, 33 cas).

### Modifié

- **Dashboard refondu** (`home_screen.dart`) :
  - `SliverAppBar.large` avec fond expressif léger et titre épuré.
  - Haut d'accueil simplifié autour de `Toolbox Everything`, avec `Toolbox`
    en dégradé `#5c6ff4` → `#e870c2`.
  - Bandeau favoris horizontal scrollable.
  - Sections groupées par catégorie avec en-têtes expressifs.
  - `SearchBar` Material 3 native (pill).
  - Stagger d'apparition basé sur les courbes M3 Expressive (`emphasizedDecelerate`).
- **Téléchargeur YouTube** : écran reconstruit autour d'un flux guidé
  (analyse d'URL, états vides/erreur/progression, actions rapides, préférences
  de sortie et sections audio/vidéo détaillées).
- **Identité visuelle** : nouveaux assets Toolbox Everything pour l'icône launcher,
  le splash screen avec wordmark et la bannière.
- **Assets natifs** : icône applicative générée sur `launcher_icon`, splash Android/iOS
  recalibré aux tailles natives (Android 12 1152x1152 + branding 800x320, iOS
  160 pt + branding 250x100 pt), `roundIcon` Android aligné sur `launcher_icon`;
  les `ic_launcher.png` Flutter historiques restent inchangés.
- **Thème** : `ThemeProvider` allégé, délègue désormais à `buildExpressiveTheme`.
  Page transitions `PredictiveBackPageTransitionsBuilder` (Android) /
  `CupertinoPageTransitionsBuilder` (iOS), boutons en `StadiumBorder` (pill),
  inputs containerHighest, FAB rayon 16, NavigationBar 72 dp, slider M3E (track 12),
  sheets et dialogs en rayons larges.
- **Bump dépendances (patches & minor sûrs)** :
  - `cupertino_icons` 1.0.8 → 1.0.9
  - `clipboard` 3.0.8 → 3.0.14
  - `mobile_scanner` 7.0.1 → 7.2.0
  - `file_picker` 10.3.7 → 11.0.2
  - `lottie` 3.3.1 → 3.3.3
  - `package_info_plus` 9.0.0 → 9.0.1
  - `shared_preferences` 2.5.3 → 2.5.5
  - `flutter_local_notifications` 19.4.0 → 21.0.0
  - `animate_do` 4.2.0 → 5.1.0
  - `open_file` 3.5.10 → 3.5.11
  - `connectivity_plus` 7.0.0 → 7.1.1 (ajout du cas `ConnectivityResult.satellite`).
- **Compatibilité APIs post-bump** : appels `flutter_local_notifications` migrés
  vers les paramètres nommés de la v21 et `file_picker` vers l'API statique v11.
- **Toolchain** : projet aligné sur Flutter 3.41.7 stable et Dart 3.11.5
  (`environment.sdk` mis à `^3.11.0`), NDK Android aligné sur `28.2.13676358`
  pour satisfaire `jni`.
- **CI Android** : validation explicite des secrets de signature et génération
  propre de `android/key.properties` dans GitHub Actions, avec détection du
  type réel de keystore (`jks` / `pkcs12`) et installation explicite du SDK
  Android/NDK via `android-actions/setup-android`.

### Retiré

- Plateformes **Linux**, **Windows**, **macOS** et **Web** : l'application n'est plus livrée que sur
  **Android** et **iOS**.
- `lib/presentation/widgets/tool_card.dart` (remplacé par `lib/shared/widgets/tool_card.dart`).
- `lib/core/services/download_service_universal.dart` et `download_service_stub.dart`
  (export conditionnel web inutilisé sur mobile).

## [0.2.6] - 2025-12-15

### Ajouté
- **Sélecteur de couleurs avancé** : Nouvel outil avec roue chromatique, export HEX/RGB/RGBA/HSL, et historique des 12 dernières couleurs (persistant).
- **Encodeur/Décodeur** : Nouvel outil supportant Base64, URL, HTML entities et Hexadécimal avec toggle instantané encode ↔ decode.

### Modifié
- **Migration Flutter 3.38 / Dart 3.10** : SDK constraint mis à jour de `^3.8.1` vers `^3.10.0`.
- **Mise à jour majeure des dépendances** :
  - `clipboard` 2.0.2 → 3.0.8
  - `fluttertoast` 8.2.12 → 9.0.0
  - `youtube_explode_dart` 2.5.1 → 3.0.5
  - `sensors_plus` 6.1.1 → 7.0.0
  - `package_info_plus` 8.0.0 → 9.0.0
  - `connectivity_plus` 6.0.5 → 7.0.0
  - `ffmpeg_kit_flutter_new` 3.1.0 → 4.1.0
  - `file_picker` 10.2.0 → 10.3.7
  - `collection` 1.18.0 → 1.19.1
  - `crypto` 3.0.5 → 3.0.7
  - `shared_preferences` 2.3.4 → 2.5.3
  - `printing` 5.13.5 → 5.14.2
  - `http` 1.2.0 → 1.4.0
  - `dynamic_color` 1.7.0 → 1.8.1

### Corrigé
- **Modernisation du code Flutter 3.x** :
  - Migration de `color.value` vers `color.toARGB32()` (API dépréciée).
  - Migration de `withOpacity()` vers `withValues(alpha:)` pour une meilleure précision.
  - Migration de `textScaleFactor` vers `textScaler` (API dépréciée depuis Flutter 3.12).
  - Suppression des imports, variables et champs inutilisés.
  - Ajout de `final` aux champs immuables (`_stopwatch`, `_laps`).
  - Ajout d'accolades aux structures conditionnelles (`if` statements).
- **Réduction des warnings** : Passage de 32 issues à 3 infos (0 erreur, 0 warning).

---

## [0.2.5] - 2025-08-25

### Ajouté
- **Support du Predictive Back Gesture** : Intégration complète de la navigation gestuelle prédictive d'Android 16+ pour une expérience fluide.
- **Interface adaptative et centrée** : La grille d'outils s'adapte automatiquement à toutes les tailles d'écran avec un centrage intelligent.
- **Correctifs de responsivité** : Résolution complète des problèmes de débordement (overflow) et de positionnement aléatoire dans les cartes d'outils.
- **Téléchargeur YouTube en arrière-plan** : Les téléchargements continuent même si l'application est en arrière-plan, avec des notifications de progression.
- **Préréglages rapides pour le téléchargeur** : Téléchargez rapidement en MP4 (720p, 1080p) ou M4A (128kbps, 256kbps) en un clic.
- **Notifications système** : Des notifications claires pour le début, la progression, la réussite ou l'échec des téléchargements.
- **Mode économie de ressources** : Une nouvelle option dans les paramètres pour désactiver les animations et optimiser les performances sur les appareils moins puissants.
- **Dynamic Color (Material You)** : L'interface utilise désormais les couleurs du fond d'écran de l'utilisateur sur Android 12+ (activable dans les paramètres).
- **Edge-to-Edge Display** : L'application s'affiche en plein écran pour une meilleure immersion.
- **App Shortcuts** : Accès rapide aux outils "QR Code", "Téléchargeur" et "Convertisseur" depuis l'icône de l'application.
- **Contrôle des vibrations** : Ajout d'une option pour activer ou désactiver les retours haptiques.
- **Politique de confidentialité** : Ajout d'une politique de confidentialité accessible depuis l'écran "À propos".
- **Icônes de notification personnalisées** : Utilisation d'icônes dédiées pour les notifications de téléchargement et les raccourcis.
- YouTube Downloader: affichage détaillé de la progression (Mo téléchargés/total), du débit (MB/s) et de l'ETA.
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
- **Compatibilité Android 16** : Migration de `FlutterFragmentActivity` vers `FlutterActivity` pour une meilleure compatibilité avec le Predictive Back Gesture.
- **Optimisation des animations Hero** : Désactivation conditionnelle sur Android pour éviter les conflits avec la navigation gestuelle prédictive.
- **Interface des paramètres améliorée** :
  - Titre "Paramètres" masqué en haut (pas de doublon avec le header) et affiché uniquement lors du collapse.
  - Prévention du troncage des labels (Clair/Système/Sombre) sur petits écrans.
- **Amélioration de l'interface du téléchargeur** : Le champ de saisie de l'URL est plus grand et le texte d'aide a été déplacé pour une meilleure ergonomie.
- **Uniformisation des boutons** : Tous les boutons de l'application ont désormais une hauteur minimale de 52px pour une meilleure accessibilité et cohérence.
- **Optimisation des performances de l'interface** : Réduction de la qualité des miniatures et limitation du cache d'images pour économiser la mémoire.
- **Optimisation des transitions de page** : Les animations de transition entre l'écran d'accueil et les outils sont désormais plus rapides et fluides, corrigeant un bug qui causait plusieurs secondes de latence.
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
- **Accueil (cartes)** : Contenu parfaitement centré et typographies uniformisées (icône taille fixe, titre en 14px, FittedBox pour l'adaptation).
- **Architecture responsive complète** : Élimination de tous les débordements (RenderFlex overflow) grâce à l'utilisation de FittedBox et LayoutBuilder adaptatifs.
- **Stabilisation du Predictive Back** : Résolution des problèmes de fonctionnement intermittent du geste de retour prédictif.
- **Centrage et adaptabilité** : Correction du positionnement "aléatoire" des éléments dans les cartes, avec un alignement cohérent sur toutes les tailles d'écran.
- **Correction des permissions Android** : L'application demande maintenant correctement la permission d'afficher des notifications sur Android 13+.
- **Correction d'une erreur de ressource d'icône** : Résolution d'un crash lié à une icône de notification manquante pour `flutter_local_notifications`.
- **Correction des animations de transition** : Les animations "Hero" entre l'accueil et les outils fonctionnent désormais correctement, éliminant les lenteurs.
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

### Corrigé
- **Téléchargeur de médias** : Correction du plugin `open_file_plus` obsolète
  - Remplacement par `open_file: ^3.5.10` pour compatibilité Flutter moderne
  - Résolution des erreurs de compilation Android liées à l'API `PluginRegistry.Registrar`
  - Mise à jour des imports dans `downloader_screen.dart`

### Amélioré
- **Interface utilisateur** : Nettoyage et optimisation de l'interface principale
  - Suppression de la section "Quick Stats" (100% Offline, 0€ Gratuit, etc.)
  - Élimination des badges colorés du header (100% Offline, Gratuit, Sécurisé)
  - Interface plus épurée et professionnelle
  - Navigation directe vers les outils sans éléments distractifs

### Nettoyé
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
