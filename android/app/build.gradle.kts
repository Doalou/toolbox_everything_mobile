import java.util.Properties
import java.io.FileInputStream
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android Gradle plugin.
    id("dev.flutter.flutter-gradle-plugin")
}

val keyProperties = Properties()
val keyPropertiesFile = rootProject.file("key.properties")
if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
}

fun signingProperty(name: String): String {
    val value = keyProperties.getProperty(name)?.trim()
    require(!value.isNullOrBlank()) {
        "Missing or empty Android signing property '$name' in ${keyPropertiesFile.path}"
    }
    return value
}

android {
    namespace = "com.toolbox.everything.mobile"
    compileSdk = 37 // Android 17
    ndkVersion = "28.2.13676358" // Requis par jni, rétrocompatible avec les plugins NDK 27

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.toolbox.everything.mobile"
        minSdk = 24 // Requis par ffmpeg_kit_flutter_new
        targetSdk = 37 // Android 17
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            if (keyPropertiesFile.exists()) {
                keyAlias = signingProperty("keyAlias")
                keyPassword = signingProperty("keyPassword")
                storeFile = file(signingProperty("storeFile"))
                storePassword = signingProperty("storePassword")
                keyProperties.getProperty("storeType")?.trim()
                    ?.takeIf { it.isNotBlank() }
                    ?.let { storeType = it }
            }
        }
    }

    buildTypes {
        release {
            if (keyPropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = JvmTarget.JVM_17
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
