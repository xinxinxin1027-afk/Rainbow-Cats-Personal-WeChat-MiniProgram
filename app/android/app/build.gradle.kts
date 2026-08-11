plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.xinxinxin1027.rainbow_cats"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.xinxinxin1027.rainbow_cats"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // 私人侧载默认使用 debug key；配置 GitHub Secrets 后由 patch_android.py 覆盖为正式签名。
            signingConfig = signingConfigs.getByName("debug")
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

// RAINBOW_OPTIONAL_SIGNING
val rainbowStoreFile = System.getenv("RAINBOW_KEYSTORE_PATH")
val rainbowStorePassword = System.getenv("RAINBOW_KEYSTORE_PASSWORD")
val rainbowKeyAlias = System.getenv("RAINBOW_KEY_ALIAS")
val rainbowKeyPassword = System.getenv("RAINBOW_KEY_PASSWORD")

android {
    if (!rainbowStoreFile.isNullOrBlank()) {
        signingConfigs {
            create("rainbowRelease") {
                storeFile = file(rainbowStoreFile)
                storePassword = rainbowStorePassword
                keyAlias = rainbowKeyAlias
                keyPassword = rainbowKeyPassword
            }
        }
        buildTypes {
            getByName("release") {
                signingConfig = signingConfigs.getByName("rainbowRelease")
            }
        }
    }
}

