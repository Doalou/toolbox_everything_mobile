# Instructions pour l'agent IA de GitHub Copilot

Bienvenue dans le projet **Toolbox Everything Mobile** ! Ce document vous guidera pour comprendre l'architecture, les conventions et les flux de travail de ce projet Flutter.

## Vue d'ensemble de l'architecture

Il s'agit d'une application Flutter qui regroupe plusieurs outils dans une seule application. L'architecture est conçue pour être modulaire et facile à étendre.

- **Framework** : Flutter
- **Langage** : Dart
- **UI** : Material Design 3
- **Gestion de l'état** : `provider` est utilisé, principalement pour la gestion des thèmes.

### Structure du projet

La structure des répertoires clés est la suivante :

- `lib/`: Contient tout le code source Dart.
  - `main.dart`: Le point d'entrée de l'application.
  - `core/`: Contient la logique de base, comme les fournisseurs et les modèles.
    - `providers/theme_provider.dart`: Gère le thème de l'application (clair/sombre) et les palettes de couleurs.
  - `presentation/`: Contient les widgets de l'interface utilisateur.
    - `screens/`: Chaque écran de l'application correspond à un outil. C'est ici que la plupart des fonctionnalités sont implémentées.
      - `home_screen.dart`: L'écran principal qui affiche la grille d'outils.
    - `widgets/`: Widgets réutilisables utilisés dans l'application.
  - `features/`: Ce répertoire est actuellement vide mais est destiné à contenir la logique métier pour des fonctionnalités plus complexes à l'avenir.

## Flux de travail de développement

### Configuration

1.  Assurez-vous d'avoir le SDK Flutter installé.
2.  Installez les dépendances du projet :
    ```bash
    flutter pub get
    ```

### Exécution de l'application

- Pour exécuter l'application en mode débogage :
  ```bash
  flutter run
  ```
- Pour exécuter l'application sur une plateforme spécifique (par exemple, chrome) :
  ```bash
  flutter run -d chrome
  ```

### Tests

Pour exécuter les tests, utilisez la commande standard de Flutter :
```bash
flutter test
```

## Conventions et modèles spécifiques au projet

### Ajout d'un nouvel outil

Pour ajouter un nouvel outil à la boîte à outils :

1.  Créez un nouveau fichier `*_screen.dart` dans `lib/presentation/screens/`. Ce fichier doit contenir un `StatefulWidget` ou `StatelessWidget` pour l'interface utilisateur de l'outil.
2.  Inspirez-vous des écrans existants pour la structure (par exemple, `password_generator_screen.dart` ou `hash_calculator_screen.dart`).
3.  Ajoutez le nouvel outil à la liste des outils dans `home_screen.dart` pour qu'il apparaisse dans la grille du menu principal.

### Thématisation

- Le thème de l'application est géré par `ThemeProvider` dans `lib/core/providers/theme_provider.dart`.
- Pour ajouter une nouvelle palette de couleurs, modifiez la liste `colorSchemes` dans ce fichier.
- Le changement de thème est géré via le menu des paramètres (`settings_screen.dart`).

### Dépendances et intégrations

- Le fichier `pubspec.yaml` répertorie toutes les dépendances du projet.
- De nombreuses fonctionnalités reposent sur des paquets tiers (par exemple, `mobile_scanner` pour la lecture de codes QR, `flutter_compass` pour la boussole).
- Les autorisations pour les fonctionnalités natives (comme l'appareil photo ou les capteurs) sont gérées à l'aide du paquet `permission_handler`. Assurez-vous de demander les autorisations nécessaires avant d'utiliser une fonctionnalité qui en a besoin.
