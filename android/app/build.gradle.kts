plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.book_app_v2"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11  // Updated to Java 11
        targetCompatibility = JavaVersion.VERSION_11  // Updated to Java 11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()  // Updated to Java 11
    }

    defaultConfig {
        applicationId = "com.example.book_app_v2"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    implementation("androidx.window:window:1.3.0")  // Updated version
    implementation("androidx.window:window-java:1.3.0")  // Updated version
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")  // Updated version
}

flutter {
    source = "../.."
}