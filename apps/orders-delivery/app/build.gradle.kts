import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.kapt")
    id("org.jetbrains.kotlin.plugin.serialization")
    id("com.google.dagger.hilt.android")
}

// ── توقيع الإصدار من keystore.properties المحلي (غير مرفوع في git — راجع PLAY_STORE_RELEASE.md §2)
//    غيابه = بناء release غير موقّع كما كان، بلا فشل.
val keystorePropsFile = rootProject.file("keystore.properties")
val keystoreProps = Properties().apply {
    if (keystorePropsFile.exists()) FileInputStream(keystorePropsFile).use { load(it) }
}

// B5 (GAP_TO_APK.md): نسخة قابلة للتكرار من CI دون تعديل يدوي — TAMM_VERSION_CODE/TAMM_VERSION_NAME
val ciVersionCode: Int = System.getenv("TAMM_VERSION_CODE")?.toIntOrNull() ?: 1
val ciVersionName: String = System.getenv("TAMM_VERSION_NAME") ?: "1.0.0"

android {
    namespace = "com.tammtool.ordersapp"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.tammtool.ordersapp"
        minSdk = 24
        targetSdk = 35
        versionCode = ciVersionCode
        versionName = ciVersionName
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        vectorDrawables {
            useSupportLibrary = true
        }
    }

    if (keystoreProps.isNotEmpty()) {
        signingConfigs {
            create("release") {
                storeFile = file(keystoreProps.getProperty("storeFile"))
                storePassword = keystoreProps.getProperty("storePassword")
                keyAlias = keystoreProps.getProperty("keyAlias")
                keyPassword = keystoreProps.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            // بلا keystore.properties تبقى النسخة غير موقّعة (اسمها app-release-unsigned.apk)
            signingConfig = signingConfigs.findByName("release")
        }
        debug {
        }
    }

    // مخططات Room تُراجَع في git لتفادي كسر الترحيل بصمت
    sourceSets {
        getByName("androidTest").assets.srcDir("$projectDir/schemas")
    }

    lint {
        // لا نُخفي المشكلة لكن لا نوقف البناء بتحذيرات lint غير حاسمة
        abortOnError = true
        warningsAsErrors = false
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildFeatures {
        compose = true
        // viewBinding/dataBinding معطّلان: لا يوجد أي ملف layout XML ولا أي *Binding مُستخدم.
        // dataBinding كان يضيف مهمة :app:dataBindingMergeDependencyArtifactsDebug التي تفشل
        // عند أي خطأ في classpath (رُصدت في CI 42273932002) بلا أي فائدة هنا.
    }

    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.8"
    }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

// ── A1 من GAP_TO_APK.md: exportSchema=true بلا room.schemaLocation كان يُفشل kaptDebugKotlin
kapt {
    correctErrorTypes = true
    arguments {
        arg("room.schemaLocation", "$projectDir/schemas")
    }
}

dependencies {
    // Hilt DI
    implementation("com.google.dagger:hilt-android:2.50")
    kapt("com.google.dagger:hilt-android-compiler:2.50")

    // AndroidX
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.11.0")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")

    implementation("androidx.compose.runtime:runtime-livedata:1.6.4")
    implementation("androidx.compose.material3:material3:1.2.1")

    // Jetpack Compose
    implementation("androidx.activity:activity-compose:1.8.2")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.7.0")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.7.0")
    implementation("androidx.compose.ui:ui:1.6.4")
    implementation("androidx.compose.ui:ui-graphics:1.6.4")
    implementation("androidx.compose.ui:ui-tooling-preview:1.6.4")
    implementation("androidx.compose.material:material:1.6.4")
    implementation("androidx.compose.material:material-icons-extended:1.6.4")
    // حُذفت: androidx.compose.material:material-window-size-class:1.6.4 غير منشور في google()
    //   (الاسم الصحيح androidx.compose.material3:material3-window-size-class) ولا يوجد أي Use
    //   في الشيفرة — كانت سبب فشل :app:dataBindingMergeDependencyArtifactsDebug / debugCompileClasspath
    implementation("androidx.navigation:navigation-compose:2.7.5")

    // Hilt Navigation Compose
    implementation("androidx.hilt:hilt-navigation-compose:1.1.0")

    // Room Database
    implementation("androidx.room:room-runtime:2.6.1")
    implementation("androidx.room:room-ktx:2.6.1")
    kapt("androidx.room:room-compiler:2.6.1")

    // Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3")

    // Serialization (JSON)
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.2")

    // Coil (image loading)
    implementation("io.coil-kt:coil-compose:2.5.0")

    // Timber logging
    implementation("com.jakewharton.timber:timber:5.0.1")

    // ── اختبارات وحدوية (لا وجود لأي اختبار قبل هذا السطر)
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.7.3")
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
}
