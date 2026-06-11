plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.ecommerce_app"
    compileSdk = 36 // 🟢 MODIFIÉ : Forcer la version 36 requise par les dépendances
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.ecommerce_app"
        minSdk = 24  // 🟢 MODIFIÉ : Forcer à 24 pour anticiper les exigences futures
        targetSdk = 34 // Laisse flutter.targetSdkVersion ou mets 34/35 directement
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}