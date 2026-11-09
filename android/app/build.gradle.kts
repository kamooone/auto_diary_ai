plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.kazusa.auto_diary_ai"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.kazusa.auto_diary_ai"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // google_mobile_adsは、Android 7.0(API 24)以上が必要
        minSdk = maxOf(flutter.minSdkVersion, 24)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // リリースの署名情報は、環境変数で受け取る(tools/deploy.sh が設定する)
    val keystoreFile = System.getenv("ANDROID_KEYSTORE_FILE")
    val keystorePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
    val keyAliasName = System.getenv("ANDROID_KEY_ALIAS")
    val keyPasswordValue = System.getenv("ANDROID_KEY_PASSWORD")
    val hasReleaseSigning = listOf(
        keystoreFile, keystorePassword, keyAliasName, keyPasswordValue
    ).none { it.isNullOrBlank() }

    signingConfigs {
        create("release") {
            if (hasReleaseSigning) {
                storeFile = file(keystoreFile!!)
                storePassword = keystorePassword
                keyAlias = keyAliasName
                keyPassword = keyPasswordValue
            }
        }
    }

    // 署名情報がないのは、リリースをビルドするときだけエラーにする
    // (デバッグ実行は、署名情報なしで動かせる)
    gradle.taskGraph.whenReady {
        val buildsRelease = allTasks.any {
            it.project == project && it.name.contains("Release", ignoreCase = true)
        }

        if (buildsRelease && !hasReleaseSigning) {
            throw GradleException(
                "Release signing credentials are not available. " +
                "Use tools/deploy_play.sh to build the release AAB."
            )
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")

    // 行動認識(徒歩・自転車・乗り物など)
    implementation("com.google.android.gms:play-services-location:21.2.0")
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}
