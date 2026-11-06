# نشر TAMMTOOL على Google Play — من keystore إلى Internal track

> وثيقة عملية لقرارات الإصدار والتوقيع. مبنية على الحالة الفعلية لـ `apps/*` في فرع الكود
> `arena/ff5110e8-tammtool` (آخر فحص 2026-11-06). لا تُنفَّذ أي خطوة توقيع هنا في هذه البيئة
> (لا `keytool`/`apksigner`) — الأوامر مُعدّة لتنفيذها على جهاز فيه JDK 17 + Android SDK.
> للأمر العام راجع [`BUILD_GUIDE.md`](BUILD_GUIDE.md) ولمشاكل CI [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md).

---

## 0. القرار الأول: AAB لا APK

Google Play **يفرض** حزمة `.aab` (Android App Bundle) للتطبيقات الجديدة منذ 2021؛ الـ APK
يكفي للتوزيع المباشر/الداخلي فقط. السكربت يبني الاثنين:

```bash
./scripts/build-apk.sh bundle marketer --yes        # → dist/marketer-bundle-v1.0.0-<git>.aab
./scripts/build-apk.sh debug  marketer --yes         # → dist/marketer-debug-v1.0.0-<git>.apk (للاختبار على الهاتف)
```

| الغرض | الملف | أين يذهب |
|---|---|---|
| رفع إلى Play Console | `dist/<app>-bundle-v<ver>-<sha>.aab` | Play Console → Production / Internal testing |
| اختبار على هاتف فريق | `dist/<app>-debug-<ver>-<sha>.apk` | `./scripts/apk-test.sh test --app <app>` |
| توزيع داخلي بلا Play | `dist/<app>-release-<ver>-<sha>.apk` موقّع | رابط داخلي/MDM |

الحالة الحالية للتطبيقين (`apps/*/app/build.gradle.kts`):

| العنصر | marketer | orders-delivery |
|---|---|---|
| `applicationId` | `com.tammtool.marketerapp` | `com.tammtool.ordersapp` |
| `app_name` | طلبات الأفغاني | تطبيق إدارة الطلبات والمناديب |
| `versionCode` / `versionName` | 1 / 1.0.0 | 1 / 1.0.0 |
| `minSdk` / `targetSdk` | 24 / 35 | 24 / 35 |
| `isMinifyEnabled` في release | true | true |
| `signingConfig` | **غير معرَّف** | **غير معرَّف** |

⇒ **قبل أول إصدار ستحتاج واحدة من طريقتين**: إمّا تعريف `signingConfig` في Gradle (القسم 2)،
وإمّا بناء نسخة غير موقّعة ثم توقيعها بالسكربت (القسم 3). الثانية أقل مخاطرة أسرارياً ولا تلمس
`apps/` — أنسب لنا الآن لأن `apps/` يملكه وكيل آخر.

---

## 1. keystore — أنشئه مرة واحدة، ولا تفقده أبداً

> **لا تسترجع Google مفتاحك.** إن ضاع keystore لا يمكن تحديث التطبيق على نفس المعرّف؛
> الحل الوحيد حساب جديد بتطبيق جديد. ابدأ مع **Play App Signing** منذ اليوم الأول.

```bash
mkdir -p ~/tamm-keystore && cd ~/tamm-keystore
keytool -genkeypair -v \
  -keystore tammtool-release.jks \
  -alias tammtool-upload \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass "$(read -rsp 'كلمة المرور: ' -n 32 p; printf '%s' "$p")"   # أو اكتبها تفاعلياً
```

الأفضل (تفاعلي، بلا كلمة مرور في سجل الأوامر):

```bash
keytool -genkeypair -v -keystore ~/tamm-keystore/tammtool-release.jks \
  -alias tammtool-upload -keyalg RSA -keysize 2048 -validity 10000
```

تحقق وخذ البصمة (تحتاجها لمطابقة ما يقوله Play):

```bash
keytool -list -v -keystore ~/tamm-keystore/tammtool-release.jks | grep -A2 SHA256
# أو من الـ APK بعد التوقيع:
"$ANDROID_HOME"/build-tools/35.0.0/apksigner verify --print-certs dist/marketer-release-*.apk
```

**قواعد إلزامية:**

1. `*.jks` و`*.keystore` و`keystore.properties` **متجاهَلة في git** (`.gitignore` عندك يغطيها) —
   لا ترفعها ولو مؤقتاً، ولا ترفعها كـ artifact في CI.
2. نسخة احتياطية مشفّرة خارج الجهاز (مدير كلمات مرور + قرص/سحابة مشفّرة) + نسخة في مكان ثانٍ.
3. مفتاحان، لا واحد: **upload key** (هذا الـ keystore، يُرفع لـ Play ويمكن تدويره) و
   **app signing key** (تحتفظ به Google). تدوير upload key مسموح من Console؛ تدوير app signing key لا.
4. إن اضطررت لرفع المفتاح إلى CI (لا يُنصح): سرّ `secret` + فكّ التشفير في خطوة بناء،
   ومزيج `base64 -d` + `gpg` — و`set +o history`. **الحل الأمن هنا:** التوقيع **محلياً**،
   وCI يبني `*-unsigned` فقط.

---

## 2. الخيار أ — `signingConfig` داخل Gradle (أوتوماتيك، لكن يلمس `apps/`)

`apps/<app>/keystore.properties` (محلي، غير مرفوع):

```properties
storeFile=/home/YOU/tamm-keystore/tammtool-release.jks
storePassword=…
keyAlias=tammtool-upload
keyPassword=…
```

في `apps/<app>/app/build.gradle.kts` (تعديل يقترحّه الوكيل 1 على فرع `apps/`، لا أطبّقه أنا):

```kotlin
import java.util.Properties

val keystorePropsFile = rootProject.file("keystore.properties")
val keystoreProps = Properties().apply {
    if (keystorePropsFile.exists()) keystorePropsFile.inputStream().use { load(it) }
}

android {
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
        getByName("release") {
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            if (keystoreProps.isNotEmpty()) {
                signingConfig = signingConfigs.getByName("release")
            }
            // مهم: بلا هذا السطر يبقى مخرج release باسم app-release-unsigned.apk
        }
    }
}
```

فوائد هذا المسار: `./scripts/build-apk.sh release <app>` ينتج APK موقّعاً مباشرة،
و`bundle` ينتج `.aab` موقّعاً جاهزاً للرفع بلا خطوة إضافية.

---

## 3. الخيار ب — بناء غير موقّع ثم `sign-apk.sh` (لا يلمس `apps/`)

```bash
# 1) البناء (ينتهي بـ app-release-unsigned.apk داخل المشروع، والسكربت ينسخه إلى dist/)
./scripts/build-apk.sh release marketer --yes --low-memory    # RAM < 8GB

# 2) التوقيع — السكربت يوجد apksigner من $ANDROID_HOME/build-tools
export KEYSTORE_PASSWORD='…' KEY_PASSWORD='…'          # أو دعهما يُطلبان تفاعلياً
./scripts/sign-apk.sh dist/marketer-release-v1.0.0-<sha>.apk \
    ~/tamm-keystore/tammtool-release.jks tammtool-upload \
    dist/marketer-release-signed.apk

# 3) تحقق مزدوج — لا ترفع قبل أن ينجح كلاهما
./scripts/apk-test.sh validate dist/marketer-release-signed.apk
"$ANDROID_HOME"/build-tools/35.0.0/apksigner verify --verbose --print-certs dist/marketer-release-signed.apk
```

ملاحظات على `scripts/sign-apk.sh` (موثّقة في `TEAM_COLLABORATION.md` §5 للوكيل 2):
* يمرّر `--ks-pass pass:…` في argv ⇒ كلمة المرور ظاهرة في `ps` لسائر المستخدمين؛ المقترح
  `env:` (بانتظار تعديل الوكيل 2 — لا ترفع السكربت إلى CI بحالته هذه مع مفتاح حقيقي).
* `read -rsp` يسأل تفاعلياً ⇒ لا يعمل غير تفاعلي بلا تصحيح؛ اضبط المتغيرين في البيئة.
* الترتيب الصحيح للأدوات الخام: `zipalign` **قبل** `apksigner sign`؛ السكربت يستخدم `apksigner`
  فقط — مقبول لأن `bundletool`/AGP يخرجان محاذاة أصلاً. للتحقق: `zipalign -c -v 4 <apk>`.

**AAB غير موقّع:** لا يوقَّع بـ `apksigner`؛ اما أن تضبط `signingConfig` (الخيار أ) أو تبني
APK محلياً من الحزمة: `bundletool build-apks --mode=universal` ثم وقّعها للتوزيع الداخلي،
أو ارفع `dist/*.aab` كما هو ودَع Play يوقّعه (Play App Signing).

---

## 4. R8 / minify — الذي يُعطّل الإصدار بصمت

`isMinifyEnabled = true` مفعل في التطبيقين. قبل رفع نسخة release اختبر **هذا المسار تحديداً**:

```bash
./scripts/build-apk.sh release marketer --yes && ./scripts/apk-test.sh test --app marketer   # على هاتف
```

`mapping.txt` (يستخرج أخطاء ما بعد R8 من Play Console) يُكتب في:

```
apps/marketer/app/build/outputs/mapping/release/mapping.txt
```

**احفظه لكل إصدار** (خارج git؛ `dist/` متجاهَلة فاستخدمه مجلداً للتجميع):

```bash
mkdir -p ~/tamm-mappings && cp apps/marketer/app/build/outputs/mapping/release/mapping.txt \
  ~/tamm-mappings/marketer-1.0.0-$(git rev-parse --short HEAD).txt
```

أقل ما يلزم في `apps/<app>/app/proguard-rules.pro` مع Hilt + Room + kotlinx.serialization:

```proguard
-keepattributes Signature,InnerClasses,*Annotation*,SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
-keep class * extends androidx.room.RoomDatabase { *; }
-keep @androidx.room.Entity class * { *; }
-dontwarn androidx.room.paging.**
-keepclassmembers class * { @com.google.gson.annotations.SerializedName <fields>; }
-keepclassmembers class kotlinx.serialization.json.** { *** Companion; }
-keep,includedescriptorclasses class com.tammtool.**$$serializer { *; }
-keepclassmembers class com.tammtool.** { *** Companion; }
-keep class com.tammtool.**.*$$HiltModules* { *; }
-printmapping mapping.txt
```

إن ظهر `ClassNotFoundException`/`Missing class` بعد التقليص، جرّب `isMinifyEnabled = false`
للعزل ثم أعد تفعيله بقاعدة keep أدقّ — ولا ترفع نسخة لا تعمل وأنت تعتمد على أن Play «سيصلحها».

---

## 5. `versionCode` — رقم واحد يمنع الرفع

Play يرفض رفع `versionCode` مكرّر أو أصغر. التطبيقان على **1**:

```kotlin
android {
    defaultConfig {
        versionCode = 2          // يزداد مع كل رفع، ولا ينقص أبداً
        versionName = "1.0.1"    // النصي حرّ، يظهر للمستخدم
    }
}
```

اقتراح فريق: رقم `versionCode` مشتق من git (مثل `dist/` يسمّي الملف به) حتى لا يتصادم وكيلان
يبنيان في نفس اليوم — لكن **ليس** في `build.gradle.kts` تلقائياً إلا باتفاق الوكيل 1، لأن
تغييره في `apps/` يمسّ شخصين.

---

## 6. ما يطلبه Play Console (قائمة المتجر) — لا تقم بها بعد آخر APK

| العنصر | الحد/المطلوب | ملاحظات لـ TAMMTOOL |
|---|---|---|
| اسم التطبيق | ≤ 30 حرفاً | «طلبات الأفغاني» (13) / «تطبيق إدارة الطلبات والمناديب» (28) ✓ |
| وصف قصير | ≤ 80 | لا يشمل «الأفضل/رقم 1» — مرفوض آلياً |
| وصف كامل | ≤ 4000 | اذكر أن التطبيق يعرض بيانات الموقع/الاتصال |
| أيقونة | 512×512 PNG · ≤ 1MB | `ic_launcher` المصدري SVG/WebP موجود؛ صدّره PNG |
| لقطات شاشة | هاتف: 2–8 صور، ≤ 8MB، أحد الاتجاهات | من `./scripts/apk-test.sh screenshot --app <app>` |
| سياسة الخصوصية | رابط **عام** إلزامي | حتى لو لا بيانات حساسة — صفحة ثابتة تكفي |
| نموذج أمان البيانات | إلزامي | GPS/جهات الاتصال/الموقع = «يُشارَك» إذا خرج لسيرفرك |
| تصنيف المحتوى / الإعلانات / الوصول | استمارات | لا تنسها قبل «إرسال للمراجعة» |
| targetSdk | 35 = مطلوب لأغسطس 2025+ | ✓ مضبوط عندك؛ راجع الأذونات الجديدة (الطواريء/الصور الجزئية) |

**الترتيب الآمن:** Internal testing (حتى 100 مختبِر، مراجعة خفيفة) → Closed → Production.
الرفع للأولي: Console → *Testing* → *Internal testing* → Create release → ارفع `dist/*.aab`
→ راجع «App Bundle Explorer» → Save → **Rotate/Select testers** → Release.

---

## 7. بعد التنزيل: تحقق أن ما رفعته هو ما أردته

```bash
# بصمة التوقيع يجب أن تطابق ما يعرضه Console (App signing → SHA-256 certificate fingerprint)
unzip -p <(gh run download <run> --repo 22kdx/TAMMTOOL --name <artifact> --dir ./ci-apk; echo) 2>/dev/null
./scripts/apk-test.sh info   ./ci-apk/*.aab        # أو على الـ apk
./scripts/apk-test.sh validate ./ci-apk/*.apk      # 11 فحصاً: zip، manifest، SDK، signer
sha256sum ./ci-apk/*.aab; cat dist/*.sha256        # مطابقة ما بناه CI/أنت
adb install -r ./ci-apk/*.apk                      # خطأ البصمة = INSTALL_FAILED_UPDATE_INCOMPATIBLE
```

| الرسالة | السبب | الحل |
|---|---|---|
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE: Signatures do not match` | النسخة المثبتة موقعة بمفتاح آخر (debug key غالباً) | `adb uninstall com.tammtool.marketerapp` ثم أعد التثبيت — وإعلام المستخدمين أن التحديثات تحتاج نفس المفتاح للأبد |
| `APK is not aligned` | توقيع بلا `zipalign` | أعد التوقيع بعد `zipalign -f 4 in.apk out.apk` |
| `Missing or invalid signature` | نسيت `apksigner` أو وقّعت الـ unsigned خطأً | أعد القسم 3 وتأكد من اسم الملف الناتج |
| Play: «AAB is not signed / versionCode already used» | ملف من بناء قديم أو `versionCode` مكرّر | ابنِ من نظيف: `./scripts/build-apk.sh clean <app> && ./scripts/build-apk.sh bundle <app>` ثم زد `versionCode` |
| تعطل عند الإقلاع في نسخة release فقط | R8 | القسم 4 + `mapping.txt` لرموز Crashlytics/Android Vitals |

---

## 8. قائمة تحقق «قبل الضغط على Publish»

- [ ] `./scripts/build-apk.sh bundle <app> --yes` نجح من مستودع نظيف (`git status --porcelain` فارغ).
- [ ] `./scripts/ci-logs.sh <run> --gate` رجع `0` (لو البناء تمّ في CI) — لا أثراً بحجم 153 بايت.
- [ ] `./scripts/apk-test.sh validate <apk|aab>` = rc 0، و`info` يعرض `versionCode` الصحيح.
- [ ] اختبار حقيقي: `./scripts/apk-test.sh test --app <app>` → لا `FATAL EXCEPTION`، ولقطة شاشة في `test-reports/`.
- [ ] نسخة release (لا debug) موقعة، وبصمتها = بصمة Console.
- [ ] `mapping.txt` محفوظ باسم الإصدار.
- [ ] `versionCode` أكبر من كل ما رُفع سابقاً.
- [ ] لا `keystore` ولا `keystore.properties` ولا `*.jks` في `git status`/الـ artifacts.
- [ ] سياسة الخصوصية تعمل، ونموذج أمان البيانات يطابق الكود الفعلي (ماذا يُرسَل وإلى أين).
- [ ] الوثائق هنا محدّثة: [`AGENTS_STATUS.md`](AGENTS_STATUS.md) و[`TEAM_COLLABORATION.md`](TEAM_COLLABORATION.md).

---

## 9. ما لم أتحقق منه في هذه البيئة

لا `keytool`/`apksigner`/`zipalign` ولا شبكة كاملة هنا، فلم أُنتج keystore ولم أوقّع ملفاً؛
كل ما فوق مكتوب من الملفات الفعلية للفروع (`build.gradle.kts`، `scripts/sign-apk.sh`) ومن
سلوك `build-apk.sh`/`apk-test.sh` المغطّى بـ `scripts/tests/mock-smoke.sh` (90 فحصاً).
القيود التي تبقى عند التنفيذ الحقيقي: تسمية مخرجات Gradle لـ release (`app-release-unsigned.apk`
عند غياب `signingConfig`)، ووجود `mapping.txt` فعلي بعد R8 — يختبرهما من يشغّل القسم 2 أو 3
ويُحدّث هذا القسم بنتيجته.

— الوكيل 3 (التوثيق والتقارير) · 2026-11-06
