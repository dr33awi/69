import java.io.FileInputStream
import java.util.Properties

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase Plugins
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    id("com.google.firebase.firebase-perf")
}

android {
    namespace = "com.dhakarani.app"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.dhakarani.app"
        minSdk = 23
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"
        multiDexEnabled = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
        freeCompilerArgs += listOf(
            "-Xjvm-default=all",
            "-Xskip-prerelease-check"
        )
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    packaging {
        resources {
            excludes += setOf(
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/license.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt",
                "META-INF/notice.txt",
                "META-INF/ASL2.0",
                "META-INF/*.kotlin_module"
            )
        }
    }
}

dependencies {
    // Core library desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // ========== Firebase Dependencies with Explicit Versions ==========
    
    // Firebase BoM - يحدد الإصدارات المتوافقة
    implementation(platform("com.google.firebase:firebase-bom:33.6.0"))
    
    // Firebase Core Services
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-messaging") 
    implementation("com.google.firebase:firebase-config")
    implementation("com.google.firebase:firebase-crashlytics")
    
    // Firebase Performance
    implementation("com.google.firebase:firebase-perf")
    
    // Firebase In-App Messaging
    implementation("com.google.firebase:firebase-inappmessaging-display")
    
    // ========== Google Play Services ==========
    implementation("com.google.android.gms:play-services-base:18.5.0")
    
    // ========== AndroidX Dependencies ==========
    implementation("androidx.work:work-runtime-ktx:2.9.1")
    implementation("androidx.multidex:multidex:2.0.1")
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.7")
    
    // ========== Kotlin Coroutines ==========
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.1")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-play-services:1.8.1")
}

flutter {
    source = "../.."
}