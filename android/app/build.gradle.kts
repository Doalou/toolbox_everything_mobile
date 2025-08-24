import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keyProperties = Properties()
val keyPropertiesFile = rootProject.file("key.properties")
if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
}

android {
    namespace = "com.toolbox.everything.mobile"
    compileSdk = 36 // Android 15 pour compatibilité plugins
    ndkVersion = "27.3.13750724" // Version NDK spécifiée

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.toolbox.everything.mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24 // Requis par ffmpeg_kit_flutter_new
        targetSdk = 36 // Android 15 pour compatibilité plugins
        // La ligne ci-dessous est redondante car compileSdk est déjà défini au niveau supérieur
        // compileSdk = 35 // Android 15
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
        
        // Reproducible builds: fix build config values (epoch ms)
        buildConfigField("long", "BUILD_TIME", "${rootProject.extra["buildTimeEpochMs"]}")
        buildConfigField("String", "BUILD_COMMIT", "\"${System.getenv("GIT_COMMIT") ?: "unknown"}\"")
    }

    signingConfigs {
        create("release") {
            if (keyPropertiesFile.exists()) {
                keyAlias = keyProperties["keyAlias"] as String
                keyPassword = keyProperties["keyPassword"] as String
                storeFile = file(keyProperties["storeFile"] as String)
                storePassword = keyProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Apply signing configuration only if key.properties exists
            if (keyPropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
            
            // Reproducible builds configuration
            isMinifyEnabled = false
            isShrinkResources = false
            isDebuggable = false
            
            // Fix timestamps and ordering for reproducible APKs
            packagingOptions {
                doNotStrip("**/**.so")
                resources {
                    excludes += listOf(
                        "META-INF/DEPENDENCIES",
                        "META-INF/LICENSE*",
                        "META-INF/NOTICE*",
                        "META-INF/*.SF",
                        "META-INF/*.DSA",
                        "META-INF/*.RSA"
                    )
                }
            }
        }
        
        debug {
            // Same reproducible configuration for debug builds
            packagingOptions {
                doNotStrip("**/**.so")
                resources {
                    excludes += listOf(
                        "META-INF/DEPENDENCIES",
                        "META-INF/LICENSE*",
                        "META-INF/NOTICE*"
                    )
                }
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // Assure la compatibilité avec le geste retour prédictif (AndroidX Activity 1.8+)
    implementation("androidx.activity:activity-ktx:1.9.2")
    implementation("androidx.appcompat:appcompat:1.7.0")
}
