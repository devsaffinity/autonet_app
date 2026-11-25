import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Push notifications need the Firebase config from the autonect1 project. It is
// tied to the applicationId, so it only exists once that has been settled.
// Applying the plugin without the file fails the whole build, so until the file
// is dropped into android/app/ the app builds and runs without push (the
// gateway reports unsupported and every push call is a no-op).
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

// Kotlin 2.4 removed the `kotlinOptions { jvmTarget }` DSL. firebase_auth's
// native SDK needs Kotlin 2.4 metadata, hence the plugin bump in settings.
kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

// Release signing. android/key.properties (never committed, see .gitignore)
// holds storeFile, storePassword, keyAlias and keyPassword for the upload key.
// Without it the release build falls back to the debug key so that
// `flutter run --release` still works on a dev machine, but that build is NOT
// uploadable: Play rejects debug-signed bundles.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

android {
    namespace = "com.devortexx.autonect"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // flutter_local_notifications relies on java.time desugaring.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Permanent once published. Firebase, RevenueCat, the Play products and
        // the backend's ANDROID_PACKAGE_NAME all key off this value.
        applicationId = "com.devortexx.autonect"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                logger.warn(
                    "WARNING: android/key.properties not found - signing the release " +
                        "build with the DEBUG key. This cannot be uploaded to Google Play."
                )
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // AppCompat themes in res/values*/styles.xml are declared here rather
    // than relied on transitively.
    implementation("androidx.appcompat:appcompat:1.7.0")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
