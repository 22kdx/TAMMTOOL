# مكتبات Android و Jetpack (Android Libraries & Jetpack)

هذه الصفحة توثق جميع المكتبات والتبعيات (dependencies) المستخدمة في بناء تطبيقات APK احترافية، مقسمة حسب الغرض الوظيفي.

## 1. المكتبات الأساسية (AndroidX Core)

| المكتبة | الغرض | معرف الإضافة (Maven Coordinates) |
|--------|-------|----------------------------------|
| AndroidX Core | وظائف أساسية لـ Kotlin و Java | `androidx.core:core-ktx:1.12.0` |
| AndroidX AppCompat | دعم شاشات الألعاب والإصدارات القديمة | `androidx.appcompat:appcompat:1.6.1` |
| AndroidX Fragment | إدارة الشظايا (Fragments) | `androidx.fragment:fragment-ktx:1.6.2` |
| AndroidX Activity | إدارة الأنشطة (Activities) | `androidx.activity:activity-ktx:1.8.2` |
| AndroidX Lifecycle | إدارة دورة حياة مكونات التطبيق | `androidx.lifecycle:lifecycle-runtime-ktx:2.7.0` |
| AndroidX ViewModel | حفظ بيانات واجهة المستخدم أثناء التغييرات (مثل دوران الشاشة) | `androidx.lifecycle:lifecycle-viewmodel-ktx:2.7.0` |
| AndroidX LiveData | مراقبة البيانات والاستجابة للتغييرات | `androidx.lifecycle:lifecycle-livedata-ktx:2.7.0` |
| AndroidX Startup | بدء المكونات عند تشغيل التطبيق | `androidx.startup:startup-runtime:1.1.1` |

## 2. واجهة المستخدم والتصميم (UI & Material Design)

| المكتبة | الغرض | معرف الإضافة |
|--------|-------|-------------|
| Material Components | مكونات واجهة مستخدم Material Design (أزرار، بطاقات، حقول نص، ...) | `com.google.android.material:material:1.11.0` |
| ConstraintLayout | تخطيط مرن وقوي لواجهات المستخدم | `androidx.constraintlayout:constraintlayout:2.1.4` |
| Jetpack Compose | بناء واجهة المستخدم بشكل Declarative باستخدام Kotlin | `androidx.compose.ui:ui:1.6.4` |
| Compose Material | مكونات Material Design لـ Jetpack Compose | `androidx.compose.material:material:1.6.4` |
| Compose Navigation | التنقل بين شاشات Compose | `androidx.navigation:navigation-compose:2.7.5` |
| MotionLayout | رسم 움직imenti وانتقالات سلسة بين حالات الواجهة | `androidx.constraintlayout:constraintlayout:2.1.4` |
| RecyclerView | عرض قوائم طويلة من البيانات بكفاءة | `androidx.recyclerview:recyclerview:1.3.2` |
| CardView | بطاقات displaying للمحتوى | `androidx.cardview:cardview:1.0.0` |
| SwipeRefreshLayout | التمرير لإعادة التحميل (Pull to Refresh) | `androidx.swiperefreshlayout:swiperefreshlayout:1.1.0` |
| NestedScrollView | تخطيطات تمرير متداخلة | `androidx.core:core:1.12.0` |

## 3. التنقل (Navigation)

| المكتبة | الغرض | معرف الإضافة |
|--------|-------|-------------|
| Navigation Component | التنقل بين الشاشات بأمان وبطريقة宣言ية | `androidx.navigation:navigation-fragment-ktx:2.7.5` |
| Navigation Safe Args | توليد أكواد آمنة لتمرير البيانات بين الشاشات | `androidx.navigation:navigation-safe-args-gradle-plugin:2.7.5` |
| Deep Links | دعم الروابط العميقة لفتح الشاشات من خارج التطبيق | مدمج في Navigation Component |

## 4. قاعدة البيانات والتخزين المحلي (Database & Storage)

| المكتبة | الغرض | معرف الإضافة |
|--------|-------|-------------|
| Room | طبقة تجريدية فوق SQLite مع دعم Kotlin و Coroutines و Flow | `androidx.room:room-runtime:2.6.1` |
| Room KTX | دعم Kotlin Extensions لـ Room | `androidx.room:room-ktx:2.6.1` |
| Room Compiler | معالج التجميع لـ Room | `androidx.room:room-compiler:2.6.1` |
| DataStore | تخزين أزواج المفتاح-القيمة (بديل لـ SharedPreferences) | `androidx.datastore:datastore-preferences:1.1.1` |
| DataStore Proto | تخزين كائنات موزعة ببروتوكولات | `androidx.datastore:datastore-core:1.1.1` |
| SQLite | قاعدة بيانات مباشرة (إذا لم تُستخدم Room) | مدمج في نظام Android |

## 5. الشبكة والاتصال (Networking)

| المكتبة | الغرض | معرف الإضافة |
|--------|-------|-------------|
| Retrofit | عميل REST من النوع الآمن (type-safe) لـ Android و Java | `com.squareup.retrofit2:retrofit:2.9.0` |
| OkHttp | عميل HTTP منخفض المستوى (يُستخدم من قبل Retrofit) | `com.squareup.okhttp3:okhttp:4.12.0` |
| Gson | تحويل كائنات Java/Kotlin إلى JSON والعكس | `com.google.code.gson:gson:2.10.1` |
| Moshi | مكتبة JSON حديثة من Square (بديل لـ Gson) | `com.squareup.moshi:moshi:1.15.0` |
| Kotlinx Serialization | تسلسل كائنات Kotlin إلى JSON وغيرها | `org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.2` |
| Coil | تحميل وعرض الصور بكفاءة في Compose و Views | `io.coil-kt:coil:2.5.0` |
| Glide | مكتبة تحميل الصور الكلاسيكية لـ Android | `com.github.bumptech.glide:glide:4.16.0` |
| Picasso | مكتبة تحميل الصور الخفيفة | `com.squareup.picasso:picasso:2.71828` |
| Stetho | ربط تطبيق Android بـ Chrome DevTools لتصحيح الشبكة وقاعدة البيانات | `com.facebook.stetho:stetho:1.5.1` |

## 6. البرمجة غير المتزامنة (Async & Concurrency)

| المكتبة | الغرض | معرف الإضافة |
|--------|-------|-------------|
| Kotlin Coroutines | برمجة غير متزامنة منظمة (Structured Concurrency) | `org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3` |
| Kotlin Flow | تيار بيانات تفاعلي (Reactive Streams) | `org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3` |
| RxJava | برمجة تفاعلية (Reactive Programming) | `io.reactivex.rxjava3:rxjava:3.1.8` |
| RxAndroid | ربط RxJava بنظام Android | `io.reactivex.rxjava3:rxandroid:3.0.2` |
| WorkManager | تنفيذ المهام في الخلفية حتى عند إغلاق التطبيق | `androidx.work:work-runtime-ktx:2.9.0` |

## 7. حقن التبعيات (Dependency Injection - DI)

| المكتبة | الغرض | معرف الإضافة |
|--------|-------|-------------|
| Hilt | مكتبة حقن التبعيات الرسمية من Google المبنية على Dagger | `com.google.dagger:hilt-android:2.50` |
| Hilt Compiler | معالج التجميع لـ Hilt | `com.google.dagger:hilt-android-compiler:2.50` |
| Dandle | مكتبة DI خفيفة (بديل لـ Dagger/Hilt) | `com.jakewharton.dagger:dagger:2.50` |
| Koin | مكتبة DI خفيفة وكotlin-first (بديل لـ Hilt) | `io.insert-koin:koin-android:3.5.3` |
| Kodein | مكتبة DI وظيفية لـ Kotlin | `org.kodein.di:kodein-di-android:7.12.0` |

## 8. Firebase و Google Services

| المكتبة | الغرض | معرف الإضافة |
|--------|-------|-------------|
| Firebase BOM | إدارة إصدارات مكتبات Firebase بشكل موحد | `com.google.firebase:firebase-bom:33.0.0` |
| Firebase Analytics | تتبع استخدام التطبيق والسلوكيات | `com.google.firebase:firebase-analytics-ktx` |
| Firebase Crashlytics | الإبلاغ عن الأعطال والتحليلات | `com.google.firebase:firebase-crashlytics-ktx` |
| Firebase Performance | مراقبة أداء التطبيق (البدء، الاستجابة، ...) | `com.google.firebase:firebase-perf-ktx` |
| Firebase Cloud Messaging (FCM) | إرسال واستقبال الإشعارات الفورية | `com.google.firebase:firebase-messaging-ktx` |
| Firebase Auth | مصادقة المستخدمين (البريد، فيسبوك، غوغل، ...) | `com.google.firebase:firebase-auth-ktx` |
| Firebase Firestore | قاعدة بيانات سحابية NoSQL في الوقت الحقيقي | `com.google.firebase:firebase-firestore-ktx` |
| Firebase Realtime Database | قاعدة بيانات سحابية مزامنة في الوقت الحقيقي | `com.google.firebase:firebase-database-ktx` |
| Firebase Storage | تخزين الملفات والصور في السحابة | `com.google.firebase:firebase-storage-ktx` |
| Firebase Remote Config | تخصيص سلوك التطبيق دون تحديث من المتجر | `com.google.firebase:firebase-config-ktx` |
| Firebase App Distribution | توزيع نسخ تجريبية للمختبرين | `com.google.firebase:firebase-appdistribution` |
| Google Play Services Auth | مصادقة جوجل (تسجيل الدخول بحساب جوجل) | `com.google.android.gms:play-services-auth:21.0.0` |
| Google Play Services Maps | خرائط جوجل في التطبيق | `com.google.android.gms:play-services-maps:21.0.0` |
| Google Play Services Location | تحديد الموقع الجغرافي | `com.google.android.gms:play-services-location:21.0.1` |
| Google Play Services SafetyNet | التحقق من سلامة الجهاز والتطبيق | `com.google.android.gms:play-services-safetynet:18.0.1` |

## 9. الأمان والتشفير (Security & Encryption)

| المكتبة | الغرض | معرف الإضافة |
|--------|-------|-------------|
| AndroidX Security | تخزين آمن للملفات والإعدادات المشتركة (EncryptedSharedPreferences) | `androidx.security:security-crypto:1.1.0-alpha06` |
| Tink | مكتبة تشفير من Google | `com.google.crypto.tink:tink-android:1.10.0` |
| App Check | حماية موارد التطبيق من الاستخدام غير المصرح به | `com.google.firebase:firebase-appcheck` |
| SafetyNet Attestation | التحقق من أن الجهاز غير معدل (rooted) والتطبيق أصلي | `com.google.android.gms:play-services-safetynet:18.0.1` |
| Conceal | تشفير سريع للملفات على القرص (من فيسبوك) | `com.facebook.conceal:conceal:2.1.0` |
| Bouncy Castle | مكتبة تشفير شاملة لـ Java/Kotlin | `org.bouncycastle:bcprov-jdk18on:1.76` |

## 10. الاختبار وضمان الجودة (Testing & QA)

| المكتبة | الغرض | معرف الإضافة |
|--------|-------|-------------|
| JUnit | اختبارات وحدات (Unit Tests) لـ Java و Kotlin | `junit:junit:4.13.2` |
| Kotlin Test | إطار اختبار لكotlin | `org.jetbrains.kotlin:kotlin-test:1.9.20` |
| JUnit 5 (Jupiter) | إطار اختبار حديث | `org.junit.jupiter:junit-jupiter:5.10.0` |
| Espresso | اختبارات واجهة المستخدم (UI Tests) | `androidx.test.espresso:espresso-core:3.5.1` |
| UI Automator | اختبارات واجهة المستخدم عبر التطبيقات | `androidx.test.uiautomator:uiautomator:2.3.0` |
| Robolectric | تشغيل اختبارات Android على JVM دون محاكي | `org.robolectric:robolectric:4.10.1` |
| Mockito | إنشاء كائنات محاكية (Mock Objects) للاختبارات | `org.mockito:mockito-core:5.11.0` |
| MockK | إنشاء كائنات محاكاة لـ Kotlin | `io.mockk:mockk:1.13.9` |
| AssertJ | تأكيدات (Assertions) غنية للاختبارات | `org.assertj:assertj-core:3.24.2` |
| Truth | تأكيدات بسيطة وقابلة للقراءة | `com.google.truth:truth:1.1.5` |
| Detekt | تحليل ثابت لشيفرة Kotlin (راجع ملف الإضافات) | `io.gitlab.arturbosch.detekt:detekt-core:1.23.0` |
| Ktlint | تنسيق وفحص نمط شيفرة Kotlin | `com.pinterest:ktlint:0.50.0` |

## 11. الصور والوسائط (Images & Media)

| المكتبة | الغرض | معرف الإضافة |
|--------|-------|-------------|
| Coil | تحميل الصور modernos لـ Kotlin و Compose | `io.coil-kt:coil:2.5.0` |
| Glide | تحميل الصور الكلاسيكية مع دعم GIF و WebP | `com.github.bumptech.glide:glide:4.16.0` |
| ExoPlayer | مشغل فيديو وصوت متقدم لـ Android | `com.google.android.exoplayer:exoplayer:2.19.1` |
| Media3 | مكتبة الوسائط الجديدة من AndroidX | `androidx.media3:media3-exoplayer:1.1.1` |
| CameraX | التقاط الصور والفيديو بسهولة من كاميرا الجهاز | `androidx.camera:camera-core:1.3.1` |
| Lottie | عرض رسومات متحركة (After Effects) في التطبيق | `com.airbnb.android:lottie:6.2.0` |

## 12. التصميم والرسومات (Graphics & Animation)

| المكتبة | الغرض | معرف الإضافة |
|--------|-------|-------------|
| Lottie | رسومات متحركة من ملفات JSON | `com.airbnb.android:lottie:6.2.0` |
| Android Vector Drawable | أيقونات متجهة قابلة للتعديل | مدمج في AndroidX |
| AnimatedVectorDrawable | أيقونات متجهة متحركة | مدمج في AndroidX |
| Shapeshifter | أداة تصميم أيقونات متحركة (أداة خارجية) | https://shapeshifter.design |

## 13. internationalization و localization (الدعم اللغوي)

| المكتبة | الغرض | معرف الإضافة |
|--------|-------|-------------|
| AndroidX Resources | دعم اللغات والتخطيط من اليمين لليسار (RTL) للعربية | مدمج في AndroidX |
| ICU4J | دعم التنسيق والتواريخ واللغات | `com.ibm.icu:icu4j:72.1` |

## 14. مثال شامل لملف `build.gradle.kts` مع التبعيات

```kotlin
dependencies {
    // Firebase BOM (إدارة إصدارات Firebase بشكل موحد)
    implementation(platform("com.google.firebase:firebase-bom:33.0.0"))
    
    // Firebase
    implementation("com.google.firebase:firebase-crashlytics-ktx")
    implementation("com.google.firebase:firebase-analytics-ktx")
    implementation("com.google.firebase:firebase-perf-ktx")
    implementation("com.google.firebase:firebase-auth-ktx")
    implementation("com.google.firebase:firebase-firestore-ktx")
    implementation("com.google.firebase:firebase-messaging-ktx")
    
    // Google Play Services
    implementation("com.google.android.gms:play-services-auth:21.0.0")
    implementation("com.google.android.gms:play-services-location:21.0.1")
    
    // AndroidX Core
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.11.0")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")
    implementation("androidx.recyclerview:recyclerview:1.3.2")
    
    // Jetpack
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.7.0")
    implementation("androidx.lifecycle:lifecycle-viewmodel-ktx:2.7.0")
    implementation("androidx.lifecycle:lifecycle-livedata-ktx:2.7.0")
    implementation("androidx.room:room-runtime:2.6.1")
    implementation("androidx.room:room-ktx:2.6.1")
    implementation("androidx.navigation:navigation-fragment-ktx:2.7.5")
    implementation("androidx.navigation:navigation-ui:2.7.5")
    implementation("androidx.work:work-runtime-ktx:2.9.0")
    implementation("androidx.datastore:datastore-preferences:1.1.1")
    
    // Compose (اختياري)
    implementation("androidx.compose.ui:ui:1.6.4")
    implementation("androidx.compose.material:material:1.6.4")
    implementation("androidx.navigation:navigation-compose:2.7.5")
    
    // Networking
    implementation("com.squareup.retrofit2:retrofit:2.9.0")
    implementation("com.squareup.retrofit2:converter-gson:2.9.0")
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
    implementation("com.google.code.gson:gson:2.10.1")
    
    // Images
    implementation("io.coil-kt:coil:2.5.0")
    
    // Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    
    // Hilt DI
    implementation("com.google.dagger:hilt-android:2.50")
    kapt("com.google.dagger:hilt-android-compiler:2.50")
    
    // Security
    implementation("androidx.security:security-crypto:1.1.0-alpha06")
    
    // Testing
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.mockito:mockito-core:5.11.0")
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
}
```

## 15. كيفية إضافة تبعية جديدة

في ملف `app/build.gradle.kts`:

```kotlin
dependencies {
    implementation("مكتبة:إصدار")
    // مثال:
    implementation("com.squareup.retrofit2:retrofit:2.9.0")
    
    // لمعالجات التجميع (مثل Hilt, Room):
    kapt("معالج:إصدار")
    // مثال:
    kapt("com.google.dagger:hilt-android-compiler:2.50")
}
```

ثم قم بمزامنة المشروع (Sync Now) في Android Studio أو شغّل:
```bash
./gradlew androidDependencies
```

---

بعد مراجعة هذا الملف، يمكنك الانتقال إلى [أنظمة CI/CD](../ci-cd/README.md) لإعداد خطوط البناء والنشر التلقائي، أو [أمان التطبيق](../security/README.md) لحماية الشيفرة والبيانات.