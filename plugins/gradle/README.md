# إضافات Gradle (Gradle Plugins)

تحتوي هذه الصفحة على جميع إضافات Gradle المستخدمة في بناء تطبيقات Android APK/AAB احترافية، مقسمة حسب الغرض.

## 1. إضافات البناء الأساسية (Core Build Plugins)

| الإضافة | الغرض | معرف الإضافة (plugin ID) |
|---------|-------|------------------------|
| Android Application Plugin | بناء تطبيق Android وإخراج APK/AAB | `com.android.application` |
| Android Library Plugin | بناء مكتبة Android (AAR) للاستخدام في تطبيقات أخرى | `com.android.library` |
| Kotlin Android Plugin | دعم لغة Kotlin في مشاريع Android | `org.jetbrains.kotlin.android` |
| Kotlin Multiplatform Mobile | تطوير شيفرة مشتركة بين Android و iOS | `org.jetbrains.kotlin.multiplatform` |
| Android Test Plugin | دعم أدوات الاختبار (instrumented tests) | `com.android.test` (مدمج في AGP) |

مثال تفعيل في `build.gradle.kts` (على مستوى المشروع):

```kotlin
plugins {
    id("com.android.application") version "8.2.0" apply false
    id("org.jetbrains.kotlin.android") version "1.9.20" apply false
}
```

## 2. إضافات Firebase و Google Services

| الإضافة | الغرض | معرف الإضافة |
|---------|-------|-------------|
| Google Services Gradle Plugin | ربط المشروع بمشروع Firebase و Google Play Services | `com.google.gms.google-services` |
| Crashlytics Gradle Plugin | الإبلاغ عن الأعطال (Crash Reporting) في الإصدارات | `com.google.firebase.crashlytics` |
| Firebase Perf Plugin | مراقبة أداء التطبيق (Performance Monitoring) | `com.google.firebase.firebase-perf` |
| Firebase App Distribution | توزيع نسخ تجريبية للمختبرين | `com.google.firebase.appdistribution` |

مثال التفعيل (الوحدة):

```kotlin
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    id("com.google.firebase.firebase-perf")
}
```

## 3. إضافات الجودة والتحليل الثابت (Code Quality & Static Analysis)

| الإضافة | الغرض | معرف الإضافة |
|---------|-------|-------------|
| Detekt | تحليل ثابت لشيفرة Kotlin واكتشاف العيوب والتعقيدات | `io.gitlab.arturbosch.detekt` |
| Ktlint | تنسيق شيفرة Kotlin تلقائياً وفحص النمط (style) | `org.jlleitschuh.gradle.ktlint` |
| Spotless | تنسيق شامل للشيفرة (Kotlin, Java, XML, JSON, Gradle) | `com.diffplug.spotless` |
| Android Lint | فحص أخطاء Android (مدمج في AGP) | `com.android.lint` (تلقائي) |
| Lint Baseline | إنشاء ملف أساس (baseline) لأخطاء Lint known | مدمج في AGP |

مثال Detekt:

```kotlin
plugins {
    id("io.gitlab.arturbosch.detekt") version "1.23.0"
}

detekt {
    config = files("detekt-config.yml")
    buildUponDefaultConfig = true
}
```

## 4. إضافات النشر والتوزيع (Publishing & Distribution)

| الإضافة | الغرض | معرف الإضافة |
|---------|-------|-------------|
| triplet-play | نشر ملفات AAB/APK على Google Play Console من Gradle | `com.github.triplet.play` |
| Firebase App Distribution Gradle | توزيع نسخ تجريبية عبر Firebase | `com.google.firebase.appdistribution` |
| Google Play Internal App Sharing | مشاركة داخلية سريعة للمختبرين | عبر Play Console API |

مثال triplet-play:

```kotlin
plugins {
    id("com.github.triplet.play") version "3.3.0"
}

play {
    serviceAccountCredentials = file("play-console-service-account.json")
    track = "internal"
}
```

## 5. إضافات البناء المتقدمة (Advanced Build)

| الإضافة | الغرض | معرف الإضافة |
|---------|-------|-------------|
| Android Gradle Plugin (AGP) | المحرك الأساسي لبناء Android (مدمج) | `com.android.tools.build:gradle` |
| Kotlin Serialization | دعم التسلسل (serialization) لكائنات Kotlin | `org.jetbrains.kotlin.plugin.serialization` |
| Parcelize | إنشاء أكواد Parcelable تلقائياً لكائنات البيانات | مدمج في `kotlin.android` |
| Hilt Dependency Injection | حقن التبعيات (DI) من Google | `com.google.dagger.hilt.android` |
| Room Gradle Plugin | قاعدة بيانات محلية (SQLite) مع دعم Kotlin | `androidx.room` (مكتبة وليس Plugin Pure) |
| Navigation Safe Args | إنشاء أكواد آمنة للتنقل بين الشاشات | `androidx.navigation.safeargs` |
| Build Config Plugin | إنشاء حقول BuildConfig مخصصة | `com.github.spotbugs` (اختياري) |
| Shadow Jar | إنشاء ملفات JAR شاملة للتابعات | `com.github.johnrengelman.shadow` |

## 6. إضافات الأمان والتوقيع (Security & Signing)

| الإضافة | الغرض | معرف الإضافة |
|---------|-------|-------------|
| Signing Plugin | إدارة توقيع الإصدارات المختلفة في Gradle | مدمج في AGP (`signingConfigs`) |
| Play App Signing | إدارة التوقيع عبر Google Play (ليس Gradle Pure) | عبر Play Console |
| App Check | حماية الموارد من الاستخدام غير المصرح به | `com.google.firebase.appcheck` |
| SafetyNet Attestation | التحقق من سلامة الجهاز والتطبيق | `com.google.android.gms:play-services-safetynet` |

## 7. table全面的: 모든 추가 Gradle 플러그인 (قائمة شاملة)

| # | الإضافة | الغرض | المعرف | الموقع |
|---|---------|-------|--------|-------|
| 1 | Android Application | بناء تطبيق APK/AAB | `com.android.application` | أساسي |
| 2 | Android Library | بناء مكتبة AAR | `com.android.library` | أساسي |
| 3 | Kotlin Android | دعم Kotlin | `org.jetbrains.kotlin.android` | أساسي |
| 4 | Kotlin Multiplatform | شيفرة مشتركة Android/iOS | `org.jetbrains.kotlin.multiplatform` | اختياري |
| 5 | Google Services | Firebase + Play Services | `com.google.gms.google-services` | خدمات جوجل |
| 6 | Firebase Crashlytics | تقارير الأعطال | `com.google.firebase.crashlytics` | مراقبة |
| 7 | Firebase Performance | مراقبة الأداء | `com.google.firebase.firebase-perf` | مراقبة |
| 8 | Firebase App Distribution | توزيع تجريبي | `com.google.firebase.appdistribution` | توزيع |
| 9 | Detekt | تحليل ثابت Kotlin | `io.gitlab.arturbosch.detekt` | جودة |
| 10 | Ktlint | تنسيق Kotlin | `org.jlleitschuh.gradle.ktlint` | جودة |
| 11 | Spotless | تنسيق شامل | `com.diffplug.spotless` | جودة |
| 12 | Android Lint | فحص أخطاء Android | مدمج | جودة |
| 13 | triplet-play | نشر على Google Play | `com.github.triplet.play` | نشر |
| 14 | Hilt DI | حقن التبعيات | `com.google.dagger.hilt.android` | بنية |
| 15 | Navigation Safe Args | تنقل آمن | `androidx.navigation.safeargs` | واجهة |
| 16 | Room | قاعدة بيانات محلية | `androidx.room` | بيانات |
| 17 | Kotlin Serialization | تسلسل كائنات | `org.jetbrains.kotlin.plugin.serialization` | بيانات |
| 18 | Shadow Jar | JAR شامل | `com.github.johnrengelman.shadow` | بناء |
| 19 | App Check | حماية الموارد | `com.google.firebase.appcheck` | أمان |
| 20 | SafetyNet | فحص سلامة الجهاز | مكتبة Google Play Services | أمان |

## ملف مثال: `build.gradle.kts` كامل مع الإضافات الأساسية

```kotlin
// build.gradle.kts (مستوى المشروع)
plugins {
    id("com.android.application") version "8.2.0" apply false
    id("org.jetbrains.kotlin.android") version "1.9.20" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
    id("com.google.firebase.crashlytics") version "2.9.9" apply false
    id("io.gitlab.arturbosch.detekt") version "1.23.0" apply false
    id("org.jlleitschuh.gradle.ktlint") version "11.4.1" apply false
    id("com.github.triplet.play") version "3.3.0" apply false
}
```

```kotlin
// app/build.gradle.kts (مستوى الوحدة)
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    id("io.gitlab.arturbosch.detekt")
    id("org.jlleitschuh.gradle.ktlint")
    id("com.github.triplet.play")
}

android {
    namespace = "com.tammtool.app"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.tammtool.app"
        minSdk = 24
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("release")
            firebaseCrashlytics {
                mappingFileUploadEnabled = true
            }
        }
        debug {
            firebaseCrashlytics {
                mappingFileUploadEnabled = false
            }
        }
    }

    signingConfigs {
        create("release") {
            storeFile = file("../keystore/release-keystore.jks")
            storePassword = System.getenv("KEYSTORE_PASSWORD")
            keyAlias = System.getenv("KEY_ALIAS")
            keyPassword = System.getenv("KEY_PASSWORD")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildFeatures {
        compose = true
        viewBinding = true
        dataBinding = true
    }
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.0.0"))
    implementation("com.google.firebase:firebase-crashlytics-ktx")
    implementation("com.google.firebase:firebase-analytics-ktx")
    implementation("com.google.android.gms:play-services-auth:21.0.0")
    
    // AndroidX
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.11.0")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")
    
    // Jetpack
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.7.0")
    implementation("androidx.lifecycle:lifecycle-viewmodel-ktx:2.7.0")
    implementation("androidx.room:room-runtime:2.6.1")
    implementation("androidx.navigation:navigation-fragment-ktx:2.7.5")
    
    // Networking
    implementation("com.squareup.retrofit2:retrofit:2.9.0")
    implementation("com.squareup.retrofit2:converter-gson:2.9.0")
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
    
    // Image loading
    implementation("io.coil-kt:coil:2.5.0")
    
    // Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    
    // Hilt DI
    implementation("com.google.dagger:hilt-android:2.50")
    kapt("com.google.dagger:hilt-android-compiler:2.50")
    
    // Testing
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
}
```

## أوامر Gradle المفيدة مع الإضافات

```bash
# بناء التطبيق
./gradlew assembleDebug
./gradlew assembleRelease

# تشغيل الفحص الثابت (Detekt + Ktlint + Lint)
./gradlew detekt
./gradlew ktlintCheck
./gradlew lint

# بناء ونشر على Google Play Intern
./gradlew publishRelease

# توزيع عبر Firebase App Distribution
./gradlew appDistributionUploadRelease

# عرض جميع المهام المتاحة
./gradlew tasks --all
```

---

بعد مراجعة هذا الملف، انتقل إلى الفئات الأخرى في مجلد `plugins/` للاكماليات والملحقات الإضافية.