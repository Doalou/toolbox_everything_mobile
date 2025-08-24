# 📦 Reproducible Builds

Ce document explique comment fonctionne la configuration des **builds reproductibles** dans ce projet Flutter.

## 🎯 Qu'est-ce qu'un build reproductible ?

Un build reproductible garantit que le même code source produit **exactement le même binaire** à chaque compilation, indépendamment de :
- La machine utilisée
- L'heure de compilation
- L'ordre des fichiers sur le disque
- Les variables d'environnement temporaires

## ✅ Avantages

- **🔒 Sécurité** : Vérification que le binaire correspond exactement au code source
- **🐛 Débogage** : Comparaison fiable entre versions
- **📋 Conformité** : Respect des standards de sécurité industriels
- **🤝 Transparence** : Confiance renforcée pour les utilisateurs

## ⚙️ Configuration actuelle

### Gradle Properties (`android/gradle.properties`)

```properties
# Reproducible builds configuration
org.gradle.parallel=true
org.gradle.configureondemand=false
org.gradle.caching=true
org.gradle.console=plain

# Ensure deterministic builds
android.deterministic=true
android.injected.build.density=420
android.injected.build.abi=armeabi-v7a,arm64-v8a,x86_64
```

### Build Gradle Principal (`android/build.gradle.kts`)

- **Timestamps fixes** : `SOURCE_DATE_EPOCH` ou date par défaut (2024-01-01)
- **Ordre des fichiers** : `isReproducibleFileOrder = true`
- **Permissions fixes** : Modes de fichiers normalisés (644/755)
- **Compilation Java** : Arguments déterministes, pas d'incrémental

### Build Gradle App (`android/app/build.gradle.kts`)

- **BuildConfig** : Valeurs fixes pour `BUILD_TIME` et `BUILD_COMMIT`
- **Packaging** : Exclusion des métadonnées variables
- **Archives** : Timestamps et permissions normalisés

## 🚀 Utilisation

### Scripts de vérification

**Windows (PowerShell) :**
```powershell
# Build double et comparaison
.\scripts\reproducible_build.ps1 --compare

# Nettoyage
.\scripts\reproducible_build.ps1 --clean

# Build debug
.\scripts\reproducible_build.ps1 --compare --BuildType debug
```

**Linux/macOS (Bash) :**
```bash
# Build double et comparaison
./scripts/reproducible_build.sh --compare

# Nettoyage
./scripts/reproducible_build.sh --clean

# Build debug
./scripts/reproducible_build.sh --compare --build-type=debug
```

### Build manuel avec variables d'environnement

```bash
# Fixer la date de build (timestamp Unix)
export SOURCE_DATE_EPOCH=1704067200  # 2024-01-01 00:00:00 UTC

# Fixer le commit Git (optionnel)
export GIT_COMMIT=$(git rev-parse HEAD)

# Build reproductible
flutter clean
flutter pub get
flutter build apk --release --split-per-abi
```

## 🔍 Vérification de la reproductibilité

### Méthode automatique (recommandée)

Utilisez les scripts fournis qui :
1. Effectuent deux builds successifs
2. Calculent les SHA256 de chaque APK
3. Comparent les hashes et les tailles
4. Affichent un rapport détaillé

### Méthode manuelle

```bash
# Premier build
export SOURCE_DATE_EPOCH=1704067200
flutter clean && flutter pub get && flutter build apk --release
cp build/app/outputs/flutter-apk/*.apk /tmp/build1/

# Deuxième build
flutter clean && flutter pub get && flutter build apk --release
cp build/app/outputs/flutter-apk/*.apk /tmp/build2/

# Comparaison
cd /tmp/build1 && sha256sum *.apk > checksums1.txt
cd /tmp/build2 && sha256sum *.apk > checksums2.txt
diff checksums1.txt checksums2.txt
```

## 🎛️ Variables d'environnement

| Variable | Description | Valeur par défaut |
|----------|-------------|-------------------|
| `SOURCE_DATE_EPOCH` | Timestamp Unix fixe pour la compilation | `1704067200` (2024-01-01) |
| `GIT_COMMIT` | Hash du commit Git | Détecté automatiquement ou `"unknown"` |

## 🔧 Dépannage

### Les builds diffèrent encore

1. **Vérifiez les versions** :
   ```bash
   flutter --version
   gradle --version
   ```

2. **Nettoyage complet** :
   ```bash
   flutter clean
   cd android && ./gradlew clean
   rm -rf build/
   ```

3. **Variables d'environnement** :
   Assurez-vous que `SOURCE_DATE_EPOCH` est défini avant chaque build.

### Erreurs de compilation

- **NDK** : Vérifiez que `ndkVersion = "27.3.13750724"` est installé
- **Java** : Utilisez Java 17 (`JAVA_HOME` correctement configuré)
- **Gradle** : Cache parfois corrompu → `rm -rf ~/.gradle/caches/`

## 📚 Références

- [Reproducible Builds Project](https://reproducible-builds.org/)
- [Android Gradle Plugin - Reproducible Builds](https://developer.android.com/studio/build/reproducible-builds)
- [SOURCE_DATE_EPOCH Specification](https://reproducible-builds.org/specs/source-date-epoch/)
- [Repository GitHub](https://github.com/Doalou/toolbox_everything_mobile)

## 🏷️ Versions testées

- **Flutter** : 3.24.x+
- **Gradle** : 8.5+
- **Android Gradle Plugin** : 8.5+
- **Java** : 17

---

## 📝 Notes importantes

> ⚠️ **Les builds reproductibles nécessitent une configuration stricte**. Tout changement dans l'environnement peut affecter la reproductibilité.

> 💡 **Tip** : Utilisez Docker ou des environnements CI/CD pour une reproductibilité maximale entre différentes machines.

> 🎯 **Objectif** : Si vous suivez cette configuration, vos builds devraient être 100% reproductibles. En cas de problème, n'hésitez pas à ouvrir une issue !
