# الأمان والحماية (Security & Protection)

هذه الصفحة توثق جميع أدوات وتقنيات الأمان المستخدمة لحماية تطبيقات Android APK الاحترافية من الاختراق، الهندسة العكسية، وتسريب البيانات.

## 1. التوقيع الرقمي (Digital Signing)

| الأداة | الغرض | الموقع |
|--------|-------|-------|
| keystore (.jks) | ملف يحتوي على المفتاح الخاص والشهادة الرقمية لتوقيع التطبيق | تم إنشاؤه عبر `keytool` |
| apksigner | أداة توقيع ملفات APK/AAB والتحقق من التوقيع | `$ANDROID_HOME/build-tools/<version>/apksigner` |
| jarsigner | أداة توقيع قديمة لملفات JAR و APK | مدمجة مع JDK |
| Play App Signing | إدارة التوقيع عبر Google Play (توقيع التطبيق بواسطة جوجل بعد رفع AAB) | Google Play Console |

### أفضل الممارسات للتوقيع
- استخدم نفس ملف keystore لكل إصدارات التطبيق (تغيير keystore يعني اعتبار التطبيق جديدًا ولا يمكن تحديثه للمستخدمين القدامى).
- احفظ keystore خارج مستودع Git (أضفه إلى `.gitignore`).
- استخدم متغيرات البيئة أو Secrets في CI/CD لتمرير كلمات المرور.
- احتفظ بنسخة احتياطية من keystore في مكان آمن خارجي.
- لا تشارك كلمة مرور keystore مع أي شخص غير مخول.

## 2. تقليل الشيفرة والتعتيم (Code Shrinking & Obfuscation)

| الأداة | الغرض | التفعيل |
|--------|-------|---------|
| R8 | أداة تقليل الشيفرة والتعتيم الافتراضية من Google (تحل محل ProGuard) | مدمج في Android Gradle Plugin 3.4+ |
| ProGuard | أداة تقليدية لتقليل الشيفرة والتعتيم | يمكن تفعيلها في `build.gradle.kts` |
| DexGuard | نسخة مدفوعة من ProGuard مع حماية إضافية (تجارية) | https://www.guardsquare.com/dexguard |

### مثال التفعيل في `build.gradle.kts`

```kotlin
android {
    buildTypes {
        release {
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

### مثال `proguard-rules.pro`

```proguard
# الاحتفاظ بفئات التطبيق من التعتيم
-keep class com.tammtool.app.** { *; }

# الاحتفاظ بالأنشطة والخدمات والمستقبلات
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider

# الاحتفاظ بفئات النماذج (Data Classes) إذا كانت تُستخدم مع Gson/Moshi
-keepclassmembers class com.tammtool.app.models.** {
    <fields>;
}

# عدم输出 تحذيرات لبعض المكتبات
-dontwarn androidx.**
-dontwarn com.google.**
-dontwarn retrofit2.**
```

## 3. تشفير البيانات المحلية (Data Encryption)

| المكتبة | الغرض | معرف الإضافة |
|--------|-------|-------------|
| AndroidX Security (EncryptedSharedPreferences) | تخزين الإعدادات المشتركة بشكل مشفر | `androidx.security:security-crypto:1.1.0-alpha06` |
| EncryptedFile | تخزين ملفات مشفرة على القرص | `androidx.security:security-crypto:1.1.0-alpha06` |
| Google Tink | مكتبة تشفير شاملة وموثوقة من Google | `com.google.crypto.tink:tink-android:1.10.0` |
| Facebook Conceal | تشفير سريع للملفات الكبيرة على القرص | `com.facebook.conceal:conceal:2.1.0` |
| Bouncy Castle | مكتبة تشفير شاملة لـ Java/Kotlin | `org.bouncycastle:bcprov-jdk18on:1.76` |

### مثال استخدام EncryptedSharedPreferences

```kotlin
val sharedPreferences: SharedPreferences = EncryptedSharedPreferences.create(
    "secret_shared_prefs",
    masterKeyAlias,
    applicationContext,
    EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
    EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
)

val editor = sharedPreferences.edit()
editor.putString("access_token", token)
editor.apply()
```

## 4. التحقق من سلامة الجهاز والتطبيق (Integrity & Attestation)

| المكتبة | الغرض | معرف الإضافة |
|--------|-------|-------------|
| SafetyNet Attestation | التحقق من أن الجهاز غير معدل (rooted) والتطبيق أصلي | `com.google.android.gms:play-services-safetynet:18.0.1` |
| Play Integrity API | البديل الحديث لـ SafetyNet من Google Play | عبر Google Play Console |
| Firebase App Check | حماية موارد التطبيق (Firebase, ...) من الاستهلاك غير المصرح به | `com.google.firebase:firebase-appcheck` |

### مثال استخدام Firebase App Check

```kotlin
FirebaseApp.initializeApp(context)
FirebaseAppCheck.getInstance().installAppCheckProviderFactory(
    PlayIntegrityAppCheckProviderFactory.getInstance()
)
```

## 5. حماية الشيفرة من الهندسة العكسية (Anti-Reverse Engineering)

| التقنية | الغرض |
|--------|-------|
| تقليل الشيفرة (Minify) | إزالة الشيفرة غير المستخدمة وتسمية الفئات بأسماء قصيرة يصعب قراءتها |
| تأمين الموارد | تشفير الموارد الحساسة (مثل مفاتيح API) في الشيفرة |
| فحص الجذر (Root Detection) | اكتشاف ما إذا كان الجهاز يحتوي على Root ومنع تشغيل التطبيق |
| فحص المحاكي (Emulator Detection) | اكتشاف ما إذا كان التطبيق يعمل على محاكي ومنع بعض الميزات |
| فحص debuggable | منع تشغيل التطبيق في وضع التصحيح على الأجهزة الإنتاجية |

### مثال فحص debuggable

```kotlin
val isDebuggable = (context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
if (isDebuggable) {
    // منع تشغيل الميزات الحساسة في وضع التصحيح
}
```

## 6. أمان الشبكة (Network Security)

| الملف | الغرض |
|-------|-------|
| `network_security_config.xml` | تحديد إعدادات أمان الشبكة (Cleartext Traffic, Domains موثوقة, ...) |
| Certificate Pinning | تثبيت شهادات الخادم لمنع هجمات Man-in-the-Middle |
| HTTPS فقط | منع حركة المرور غير المشفرة (Cleartext HTTP) |

### مثال `network_security_config.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <domain-config cleartextTrafficPermitted="false">
        <domain includeSubdomains="true">api.tammtool.com</domain>
        <pin-set expiration="2026-12-01">
            <pin digest="SHA-256">BASE64_ENCODED_SHA256_OF_CERT</pin>
        </pin-set>
    </domain-config>
</network-security-config>
```

## 7. أمان الأذونات (Permissions)

| الممارسة | الوصف |
|----------|-------|
| طلب الأذونات في وقت التشغيل (Runtime Permissions) | طلب الأزونات الخطرة (الموقع، الكاميرا، الميكروفون) أثناء تشغيل التطبيق وليس عند التثبيت |
| 최소ية الأذونات | طلب الأذونات الضرورية فقط لعمل التطبيق |
| شرح الحاجة للأذونات | إظهار حوار يشرح لماذا يحتاج التطبيق لهذا الإذن |
| التحقق من منح الإذن قبل الاستخدام | التأكد من منح المستخدم الإذن قبل الوصول للمورد |

### مثال طلب إذن الموقع

```kotlin
if (ContextCompat.checkSelfPermission(
        this,
        Manifest.permission.ACCESS_FINE_LOCATION
    ) != PackageManager.PERMISSION_GRANTED
) {
    ActivityCompat.requestPermissions(
        this,
        arrayOf(Manifest.permission.ACCESS_FINE_LOCATION),
        REQUEST_LOCATION_PERMISSION
    )
}
```

## 8. أمان تخزين المفاتيح (Key Storage)

| التقنية | الغرض |
|--------|-------|
| Android Keystore System | تخزين المفاتيح التشفيرية في وحدة حماية الأجهزة (TEE) بدلاً من التخزين العادي |
| KeyGenParameterSpec | إنشاء مفاتيح تشفير آمنة مرتبطة بالأمان البيومتري أو رمز القفل |
| BiometricPrompt | مصادقة المستخدم عبر البصمة أو الوجه قبل الوصول للبيانات الحساسة |

### مثال استخدام Android Keystore

```kotlin
val keyGenParameterSpec = KeyGenParameterSpec.Builder(
    "my_key",
    KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
).setBlockModes(KeyProperties.BLOCK_MODE_GCM)
 .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
 .setUserAuthenticationRequired(true)
 .build()

val keyGenerator = KeyGenerator.getInstance(
    KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore"
)
keyGenerator.init(keyGenParameterSpec)
keyGenerator.generateKey()
```

## 9. أدوات فحص الأمان (Security Testing Tools)

| الأداة | الغرض |
|--------|-------|
| OWASP ZAP | أداة اختبار أمن التطبيقات (penetration testing) |
| MobSF (Mobile Security Framework) | تحليل أمن تطبيقات الجوال (APK/AAB) |
| Drozer | أداة اختبار أمن تطبيقات Android |
| APKLeaks | استخراج الأسرار (keys, tokens, ...) من ملفات APK |
| jadx | أداة فك تجميع (decompiler) لملفات APK لعرض الشيفرة المصدرية |
| MobSF CI | دمج فحص الأمان في خطوط CI/CD |

## 10. قائمة مراجعة الأمان قبل النشر (Security Checklist)

- [ ] تم توقيع APK/AAB باستخدام Keystore آمن وغير مشترك
- [ ] تم تفعيل تقليل الشيفرة (minifyEnabled) في نسخة الإصدار
- [ ] تم إضافة قواعد ProGuard/R8 لحماية الفئات الحساسة
- [ ] تم تشفير البيانات الحساسة المخزنة محليًا (EncryptedSharedPreferences)
- [ ] تم منع حركة المرور غير المشفرة (Cleartext Traffic)
- [ ] تم استخدام HTTPS فقط لجميع الاتصالات بالخادم
- [ ] تم تضمين ملف `network_security_config.xml` في التطبيق
- [ ] تم طلب الأذونات في وقت التشغيل وليس عند التثبيت
- [ ] تم إزالة سجلات التصحيح (Log.d, Timber.d) من نسخة الإصدار
- [ ] تم تفعيل Firebase App Check أو SafetyNet لحماية الموارد
- [ ] تم فحص التطبيق باستخدام أداة أمنية (مثل MobSF أو OWASP ZAP)
- [ ] لم تُclud أي كلمات مرور أو مفاتيح API في الشيفرة المصدرية
- [ ] تم استخدام Android Keystore لتخزين المفاتيح التشفيرية

---

بعد مراجعة هذا الملف، يمكنك الانتقال إلى [ضمان الجودة والاختبار](../testing/README.md) لضمان جودة التطبيق قبل النشر، أو [التصميم وواجهات المستخدم](../design/README.md) لتحسين تجربة المستخدم.