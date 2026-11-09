import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseProperties = Properties()
val releasePropertiesFile =
    file("C:/MindfulYou-Seguranca/key.properties")

if (releasePropertiesFile.exists()) {
    FileInputStream(releasePropertiesFile).use {
        releaseProperties.load(it)
    }
}

android {
    namespace = "com.mindfulyou.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.mindfulyou.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
    create("release") {
        val requiredKeys = listOf(
            "storeFile",
            "storePassword",
            "keyAlias",
            "keyPassword"
        )

        requiredKeys.forEach { key ->
            require(!releaseProperties.getProperty(key).isNullOrBlank()) {
                "Configuracao de assinatura ausente: $key"
            }
        }

        storeFile = file(releaseProperties.getProperty("storeFile"))
        storePassword = releaseProperties.getProperty("storePassword")
        keyAlias = releaseProperties.getProperty("keyAlias")
        keyPassword = releaseProperties.getProperty("keyPassword")
    }
}

buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
    }
}
}

flutter {
    source = "../.."
}
