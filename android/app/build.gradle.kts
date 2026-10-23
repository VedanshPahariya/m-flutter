import java.io.FileInputStream
import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ---------------------------------------------------------------------------
// Visible app name: one source of truth.
//
// 1. `--dart-define=APP_NAME=...` (or --dart-define-from-file) wins. Flutter
//    passes dart-defines to Gradle as a comma-separated list of base64 values.
// 2. Otherwise the default on the `APP_NAME_DEFAULT` line of
//    lib/app/app_config.dart is used, so the Dart UI and the launcher label
//    can never drift apart.
// ---------------------------------------------------------------------------
fun dartDefines(): Map<String, String> {
    val raw = project.findProperty("dart-defines") as String? ?: return emptyMap()
    return raw.split(",").mapNotNull { encoded ->
        runCatching { String(Base64.getDecoder().decode(encoded), Charsets.UTF_8) }.getOrNull()
    }.mapNotNull { pair ->
        val i = pair.indexOf('=')
        if (i <= 0) null else pair.substring(0, i) to pair.substring(i + 1)
    }.toMap()
}

fun defaultAppName(): String {
    val config = rootProject.file("../lib/app/app_config.dart")
    if (!config.exists()) return "App"
    val match = Regex("""defaultValue:\s*'([^']*)',\s*//\s*APP_NAME_DEFAULT""").find(config.readText())
    return match?.groupValues?.get(1) ?: "App"
}

val appName: String = dartDefines()["APP_NAME"]?.takeIf { it.isNotBlank() } ?: defaultAppName()

// Release signing: android/key.properties (never committed). See README.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) load(FileInputStream(file))
}
val hasReleaseKey = keystoreProperties.getProperty("storeFile") != null

android {
    namespace = "com.crmmarg.kora_crm"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // The application ID is independent of the visible name; renaming the
        // app does not change it.
        applicationId = "com.crmmarg.kora_crm"
        // Flutter 3.47 and every plugin used here support API 24 (Android 7.0)
        // as their minimum; nothing in the app requires a higher level.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Escape characters that are special in Android string resources.
        resValue("string", "app_name", appName.replace("'", "\\'").replace("&", "&amp;"))
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Without android/key.properties the release APK is signed with the
            // debug key so it can be installed for testing. It must not be
            // published to the Play Store in that state.
            signingConfig = if (hasReleaseKey) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
