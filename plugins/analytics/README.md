# التحليلات وتقارير الأعطال (Analytics & Crash Reporting)

هذه الصفحة توثق جميع أدوات التحليلات ومراقبة الأداء والإبلاغ عن الأعطال المستخدمة في تطبيقات Android APK الاحترافية.

## 1. Firebase Analytics

| الأداة | الغرض | معرف الإضافة |
|--------|-------|-------------|
| Firebase Analytics | تتبع استخدام التطبيق، الأحداث المخصصة، الديموغرافيا، والاحتفاظ بالمستخدمين | `com.google.firebase:firebase-analytics-ktx` |

### ميزات
- تتبع الأحداث التلقائي (فتح التطبيق، النقر على الشاشات، ...)
- أحداث مخصصة يمكن تعريفها من قبل المطور
- تقارير عن 전환 (conversions) ومجموعات المستخدمين
- مجاني وغير محدود

### مثال الاستخدام

```kotlin
val firebaseAnalytics = Firebase.analytics

// حدث مخصص
firebaseAnalytics.logEvent(FirebaseAnalytics.Event.SELECT_CONTENT) {
    param(FirebaseAnalytics.Param.ITEM_ID, id)
    param(FirebaseAnalytics.Param.ITEM_NAME, name)
    param(FirebaseAnalytics.Param.CONTENT_TYPE, "image")
}
```

## 2. Firebase Crashlytics

| الأداة | الغرض | معرف الإضافة |
|--------|-------|-------------|
| Firebase Crashlytics | الإبلاغ عن الأعطال (crashes) والأخطاء غير الملتقطة في الوقت الحقيقي | `com.google.firebase:firebase-crashlytics-ktx` |

### ميزات
- تقارير مفصلة عن الأعطال مع Track Stack
- تمييز الأعطال حسب الإصدار (version) والجهاز
- إشعارات فورية عند ظهور أعطال جديدة
- دمج مع Google Play Console لعرض الأعطال في الإصدارات المنشورة

### مثال الاستخدام

```kotlin
Firebase.crashlytics.setCustomKey("user_id", userId)
Firebase.crashlytics.log("الشاشة الرئيسية تم فتحها")

try {
    riskyOperation()
} catch (e: Exception) {
    Firebase.crashlytics.recordException(e)
}
```

### تفعيل في Gradle

```kotlin
plugins {
    id("com.google.firebase.crashlytics")
}

android {
    buildTypes {
        release {
            firebaseCrashlytics {
                mappingFileUploadEnabled = true
            }
        }
    }
}
```

## 3. Firebase Performance Monitoring

| الأداة | الغرض | معرف الإضافة |
|--------|-------|-------------|
| Firebase Performance | مراقبة وقت بدء التطبيق، وقت استجابة الشاشات، طلبات الشبكة، ... | `com.google.firebase:firebase-perf-ktx` |

### ميزات
- تتبع أوقات بدء التطبيق (App Start Time)
- تتبع طلبات الشبكة (HTTP Request Traces)
- تتبع عروض الشاشات (Screen Rendering)
- تنبيهات عند تدهور الأداء

### مثال الاستخدام

```kotlin
val trace = Firebase.performance.newTrace("load_screen_trace")
trace.start()
// تحميل البيانات
trace.stop()
```

## 4. Firebase Cloud Messaging (FCM)

| الأداة | الغرض | معرف الإضافة |
|--------|-------|-------------|
| Firebase Cloud Messaging | إرسال واستقبال الإشعارات الفورية (Push Notifications) | `com.google.firebase:firebase-messaging-ktx` |

### ميزات
- إشعارات فورية من الخادم إلى التطبيق
- إشعارات محلية داخل التطبيق
- استهداف مجموعات محددة من المستخدمين (Topics)
- مجاني وغير محدود

## 5. أدوات تحليلات بديلة (Third-Party Analytics)

| الأداة | الغرض | الموقع |
|--------|-------|-------|
| Mixpanel | تحليل سلوك المستخدمين وفunnels (مسارات التحويل) | https://mixpanel.com |
| Amplitude | تحليل البيانات السلوكية واحتفاظ المستخدمين | https://amplitude.com |
| Google Analytics for Firebase | تحليل ويب وتطبيقات مدمج مع Google | https://analytics.google.com |
| AppsFlyer | تحليل اكتساب المستخدمين والتسويق (Attribution) | https://appsflyer.com |
| Adjust | تحليل التسويق والاحتيال ومجموعات المستخدمين | https://adjust.com |
| Firebase Remote Config | تخصيص سلوك التطبيق عن بعد دون تحديث | مكتبة Firebase |

## 6. تقارير الأخطاء والسجلات (Error Reporting & Logging)

| الأداة | الغرض | معرف الإضافة |
|--------|-------|-------------|
| Sentry | الإبلاغ عن الأخطاء والتعقب (Error Tracking) | `io.sentry:sentry-android:7.x` |
| Bugsnag | مراقبة الأعطال والاستقرار | `com.bugsnag:bugsnag-android:6.x` |
| ACRA | جمع تقارير الأعطال وإرسالها إلى خادم خاص | `ch.acra:acra:5.x` |
| Logcat | سحب السجلات من الجهاز أثناء التطوير | أداة ADB مدمجة |
| Timber | مكتبة تسجيل (Logging) خفيفة لـ Android | `com.jakewharton.timber:timber:5.0.1` |

### مثال استخدام Timber

```kotlin
Timber.tag("MainActivity")
Timber.d("تم فتح الشاشة الرئيسية")
Timber.e(e, "حدث خطأ في تحميل البيانات")
```

## 7. مراقبة الاستقرار (Stability Monitoring)

| الأداة | الغرض |
|--------|-------|
| Android Vitals | تقارير من Google Play عن ANR (توقف الاستجابة)، الأعطال، استهلاك البطارية، وقت بدء التطبيق |
| Google Play Console | عرض تقارير الجودة والاستقرار للإصدارات المنشورة |
| Firebase Crashlytics | تقارير مفصلة عن الأعطال في الإصدارات التجريبية والنهائية |

## 8. مثال إعداد كامل لمراقبة التطبيق (build.gradle.kts)

```kotlin
dependencies {
    // Firebase BOM
    implementation(platform("com.google.firebase:firebase-bom:33.0.0"))
    
    // Analytics
    implementation("com.google.firebase:firebase-analytics-ktx")
    
    // Crashlytics
    implementation("com.google.firebase:firebase-crashlytics-ktx")
    
    // Performance
    implementation("com.google.firebase:firebase-perf-ktx")
    
    // Cloud Messaging
    implementation("com.google.firebase:firebase-messaging-ktx")
    
    // Timber للLogging
    implementation("com.jakewharton.timber:timber:5.0.1")
    
    // Sentry (اختياري، بديل或إضافي لـ Crashlytics)
    implementation("io.sentry:sentry-android:7.7.0")
}
```

## 9. أفضل الممارسات للتحليلات

1. **تتبع الأحداث المهمة فقط:** لا تتبع كل نقر، تتبع الأحداث ذات القيمة التجارية (تسجيل، شراء، إكمال عملية، ...).
2. **حماية الخصوصية:** لا ترسل بيانات حساسة (كلمات مرور، بطاقات ائتمان، ...) عبر التحليلات.
3. **الامتثال لـ GDPR/Consent:** اطلب موافقة المستخدم قبل تفعيل التحليلات في بعض المناطق.
4. **مراجعة الأعطال يوميًا:** تحقق من Crashlytics يوميًا لإصلاح الأعطال الحرجة.
5. **استخدام الإصدارات:** تأكد من إرسال `versionCode` و `versionName` مع كل تقرير خطأ لمعرفة أي إصدار يحتوي على المشكلة.
6. **اختبار قبل النشر:** تأكد من عمل التحليلات في نسخة التجريب (Internal Testing) قبل النشر العام.

---

بعد مراجعة هذا الملف، يمكنك الانتقال إلى [الأمان والحماية](../security/README.md) لحماية الشيفرة والبيانات، أو [ضمان الجودة والاختبار](../testing/README.md) لضمان جودة التطبيق قبل النشر.