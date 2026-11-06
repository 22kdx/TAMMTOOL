# ما الذي ينقص لإنتاج التطبيق؟ — قائمة الفجوات بالأولوية

> تحليل الوكيل 3 (التوثيق) بتاريخ **2026-11-06**، مبني على فحص ملفات الفروع الفعلية:
> فرع الكود `origin/arena/ff5110e8-tammtool` @ `8f92000` (أكمل نسخة من `apps/`) وفرع CI
> `origin/arena/6b69a15d-tammtool` @ `74f0a54`. كل سطر فيه **أمر يثبتُه** و**سطر يُصلحه**.
> لم يُنفَّذ أي بناء Gradle في بيئة العمل (لا JDK/SDK/شبكة) — ما لم أتحقق منه مذكور في §6.

> **تحديث 2026-11-06 (لاحق):** بعد «قم بحل كل المشاكل» نُفِّذت الإصلاحات **في الكود داخل هذا
> الفرع** (`arena/68a3e358-tammtool` @ ما بعد الدمج مع `ff5110e8`)، ولم تعد `patches/` هي المصدر
> الوحيد. جدول الحالة بند‑بند مع أمر التحقق من كل إصلاح: **§7 في نهاية الملف**.

**الحالة بكلمة:** التطبيقان **مبنيان محلياً منطقياً** (UI + Room + Hilt كاملان، 36 و62 ملف Kotlin،
بلا ملفات فارغة)، لكن **لا يوجد APK** لأن: (1) CI يخفي الفشل، (2) ذاكرة Gradle، (3) **عائق لم
يذكره أحد بعد: `room.schemaLocation`**، (4) لا wrapper في git، ولا keystore. وبعدها تأتي فجوات
«يعمل فعلاً» و«مقبول في Play».

| الطبقة | عدد البنود | من يملكها |
|---|---|---|
| **A. تمنع ظهور APK أخضر** (build) | 5 | المنسّق 0 + أدوات 2 |
| **B. تمنع إصداراً موقّعاً/مرفوعاً** (release) | 5 | المنسّق 0 (+1 في `apps/`) |
| **C. تمنع أن يكون التطبيق مفيداً/مقبولاً** (وظيفة وسياسة) | 6 | الوكيل 1 أساساً |

---

## A. طبقة البناء — بلا هذا لا APK أخضر

### A1. `room.schemaLocation` مفقود ⇒ kapt يرفض البناء (لم يوثّقه أحد) ❗

كلا التطبيقين يصدّران مخطط Room: `orders-delivery` صراحةً (`exportSchema = true` في
`data/local/AppDatabase.kt:22`) و`marketer` **بالافتراضي** (لا يذكر `exportSchema` أصلاً،
وقيمة Default في Room 2.6.1 هي `true`) — بينما لا يوجد أي `room.schemaLocation` في
`build.gradle.kts` ولا مجلد `app/schemas`:

```bash
git grep -n "room.schemaLocation" origin/arena/ff5110e8-tammtool -- apps   # ← لا نتيجة
git ls-tree -r --name-only origin/arena/ff5110e8-tammtool -- apps/marketer/app/schemas  # ← لا شيء
```

**النتيجة المتوقعة:** `error: Schema export directory was not provided to the annotation
processor` في `:app:kaptDebugKotlin` — أي فشل **قبل** أي خطأ ذاكرة، وعلى كلتا المنصتين (CI ومحلي).

**الحل (رقعة جاهزة):** [`patches/0003-apps-room-schema-export.patch`](patches/0003-apps-room-schema-export.patch)
يضيف إلى `apps/<app>/app/build.gradle.kts`:

```kotlin
kapt {
    correctErrorTypes = true
    arguments { arg("room.schemaLocation", "$projectDir/schemas") }
}
```

وبديل من سطر واحد إن آثرت التعديل في `apps/` مباشرة: `exportSchema = false` داخل `@Database(...)`
في الملفين (يُفقدك مراجعة المخطط في الدمج، لكنه يفتح البناء فوراً).

### A2. ذاكرة Gradle في CI — موثّقة ومسلَّمة

`run 42264822833` → `[.github:69] Java heap space`. الحل في `patches/0002` (سطور `org.gradle.jvmargs=-Xmx3g …`)
والتفصيل `TROUBLESHOOTING.md` §1.1. **يبقى مطلوباً حتى بعد A1.**

### A3. لا Gradle Wrapper مرفوع في git (كل الفروع)

```bash
git ls-tree -r --name-only origin/arena/ff5110e8-tammtool -- apps/marketer/gradlew apps/marketer/gradle
# ← لا gradlew ولا gradle/wrapper/gradle-wrapper.properties
```

⇒ كل بناء يعتمد على توليد wrapper أو تنزيل توزيع Gradle؛ ومع `FAIL_ON_PROJECT_REPOS` +
`pluginManagement` السليمين يبقى هذا هو المصدر الأول للتذبذب (ولماذا يختلف CI عن الجهاز).
**الحل:** التزام `apps/<app>/gradlew` + `gradle/wrapper/gradle-wrapper.properties` بنسخة
`gradle-8.7-bin.zip` والـ `gradle-wrapper.jar` (مرخّص في `.gitignore` بسطر `!gradle/wrapper/gradle-wrapper.jar` ✓ موجود).
**المالك:** الوكيل 2 (`download-gradlew.sh` أصلحه كي يحترم النسخة — `TEAM_COLLABORATION.md` §4).

### A4. CI يخفي الفشل ⇒ لا أحد يرى A1/A2 (الحل جاهز)

`set +e` + `BUILD_EXIT` غير مفحوص + placeholder بحجم 153 بايت + `git add` مرفوض بـ `*.log`.
**الحل:** [`patches/0001`](patches/README.md) (يضيف `::error::` من كتلة `* What went wrong:` ثم `exit $BUILD_EXIT`)
أو `patches/build-apk.yml.proposed` بالكامل. الأمر: `./scripts/ci-logs.sh <run> --gate`.

### A5. `scripts/android-sdk-setup.sh` معطَّل الصيغة (سطر 83) — CI يستدعيه

```bash
bash -n scripts/android-sdk-setup.sh
# scripts/android-sdk-setup.sh: line 83: syntax error near unexpected token `<>'   (على فرعي 6b69a15d و ff5110e8)
```

مُضمَّن إصلاحه في `patches/0001`. بدونه تبقى خطوة «Install Android SDK» في workflow
`6b69a15d` تعتمد على `curl` يدوي (عاملة حالياً) — لكن أي استدعاء للسكربت يفشل فوراً.

---

## B. طبقة الإصدار — تمنع «نسخة تُثبَّت وتُرفع»

| # | الفجوة | الدليل | ما يسدّها | المالك |
|---|---|---|---|---|
| B1 | **لا `signingConfig`** ⇒ مخرج release اسمه `app-release-unsigned.apk` ولا يُثبَّت | `git show origin/arena/ff5110e8-tammtool:apps/marketer/app/build.gradle.kts \| grep -c signingConfig` → `0` (وكذلك orders) | `PLAY_STORE_RELEASE.md` §2 (خيار Gradle) أو §3 (خيار `sign-apk.sh` دون لمس `apps/`) | 0 |
| B2 | **لا keystore ولا سياسة نسخ احتياطي** | لا `*.jks` في أي فرع (وهذا صحيح — ممنوع رفعه)؛ المطلوب توليده **محلياً** فقط | `PLAY_STORE_RELEASE.md` §1 | 0 |
| B3 | `sign-apk.sh` لا يعمل غير تفاعلي ويضع كلمات السر في argv | `read -rsp` في السطور 56/60 + `--ks-pass pass:…` | `TEAM_COLLABORATION.md` §5 (رقعة `env:` + رفض غير-تفاعلي) | 2 |
| B4 | **R8 مع `-keep class com.tammtool.** { *; }`** = تقليص بلا تقليص + لا حفظ `mapping.txt` | `apps/<app>/app/proguard-rules.pro` (13 و17 سطراً، كلها keep/dontwarn) | `PLAY_STORE_RELEASE.md` §4 (أضف `-keepattributes`… ونسخ `mapping.txt` لكل إصدار) | 1 + 0 |
| B5 | `versionCode = 1` للتطبيقين بلا سياسة زيادة، ولا `changelists` | `defaultConfig { versionCode = 1; versionName = "1.0.0" }` في الملفين | `PLAY_STORE_RELEASE.md` §5 | 0 |

---

## C. طبقة الوظيفة والسياسة — «APK يعمل» و«لا يُرفض من Play»

### C1. تسجيل الدخول **لا يتحقق من كلمة المرور** إطلاقاً ❗

```bash
git show origin/arena/ff5110e8-tammtool:apps/marketer/app/src/main/java/com/tammtool/marketerapp/ui/viewmodel/AuthViewModel.kt | sed -n '23,36p'
```

```kotlin
fun login(phone: String, password: String) {
    …
    val existingUser = userRepository.getByPhone(phone)
    if (existingUser != null && existingUser.isActive) {   // ← password غير مستخدمة
        _user.value = existingUser
```

نفس البنية في `apps/orders-delivery/…/AuthViewModel.kt:23-29`. ولا يوجد **أي** `MessageDigest`
أو `PBKDF2`/BCrypt في المستودع، مع عمود `password_hash` يُخزَّن بلا تجزئة:

```bash
git grep -n -I -E "MessageDigest|PBKDF2|BCrypt|Tink" origin/arena/ff5110e8-tammtool -- apps   # ← لا نتيجة
```

**الحد الأدنى:** تجزئة `PBKDF2WithHmacSHA256` (ملح 16 بايت، ≥ 120,000 تكرار) عند `register()` ومقارنتها
ثابتة الزمن في `login()`، وهجرة الأعمدة القديمة — لا `sha256(password)` عارية. **المالك: الوكيل 1.**

### C2. لا طبقة شبكة إطلاقاً ⇒ لا مزامنة بين التطبيقين

لا `Retrofit`/`OkHttp`/`Ktor`/`baseUrl` في أي `build.gradle.kts` ولا في الكود (تحقق: `git grep -I
-E "retrofit|okhttp|ktor|baseUrl" origin/arena/ff5110e8-tammtool -- apps` → فارغ). كل البيانات
محلية في Room على الجهاز. `INTERNET`+`ACCESS_NETWORK_STATE` معلنة بلا مستخدم (عدا Coil في
`marketer` المعلن **غير المستخدم** في الكود). ⇒ **قرار مطلوب من المنتج/المنسّق:** (أ) إصدار MVP
محلي صريح (ونُزيل إذن `INTERNET` ونعلن ذلك في نموذج أمان البيانات)، أو (ب) إضافة `:core:network`
مع خادم. لا يمكن تعبئة نموذج «Data safety» بدقة قبل هذا القرار.

### C3. أذونات معلَّنة بلا أي كود ⇒ رفض/تعليق في مراجعة Play

`RECEIVE_SMS` (التطبيقان) و`SEND_SMS` (orders) و`WAKE_LOCK` + `FOREGROUND_SERVICE` (orders)
موجودة في `AndroidManifest.xml`، بينما:

```bash
git grep -l -I -E "SmsManager|SMS_RECEIVED|ContentObserver.*sms|class .*: (Service|BroadcastReceiver)" origin/arena/ff5110e8-tammtool -- apps
# ← لا نتيجة: لا قارئ SMS، لا Service، لا Receiver
```

`FOREGROUND_SERVICE` بلا أي `<service>` في المانيفست = إذن ميت؛ و`RECEIVE_SMS`/`SEND_SMS`
تفرضان «SMS and Call Log policy declaration» وتُرفض عادةً لغير تطبيق SMS الافتراضي.
**الأقل كسراً:** حذف الأسطر غير المستخدمة من المانيفست، أو تنفيذ الميزة كاملاً وتعبئة الإقرار.

### C4. «الإشعارات» جدولٌ في قاعدة البيانات فقط

`MarketerNotification` / `Notification` كيانا Room + شاشتان، لكن لا `NotificationManager` ولا
`NotificationChannel` في الكود، ولا إذن `POST_NOTIFICATIONS` (مطلوب API 33+):

```bash
git grep -l -I -E "NotificationManager|NotificationChannel" origin/arena/ff5110e8-tammtool -- apps   # ← فارغ
```

⇒ إمّا تنفيذ إشعار نظامي (قناة + إذن + طلبه وقت التشغيل) أو تسمية الميزة «صندوق وارد داخل
التطبيق» في الوصف والاختبارات. **المالك: الوكيل 1.**

### C5. `allowBackup="true"` بلا `dataExtractionRules`/`fullBackupContent`

المانيفست (التطبيقان) يترك النسخ الاحتياطي كاملاً ⇒ قاعدة Room (مستخدمون، كلمات مرور، طلبات،
بيانات مالية) تذهب إلى Google Drive وتنتقل عبر Device-to-device transfer. أضِف
`android:dataExtractionRules="@xml/data_extraction_rules"` + `fullBackupContent="@xml/backup_rules"`
واستثنِ `marketer_app_db`/قاعدة orders. (الملفان غير موجودين: `git ls-tree … -- "*/res/xml"` فارغ.)

### C6. قفل الاتجاه + هدف SDK 35 ⇒ سياسة الشاشات الكبيرة

`android:screenOrientation="portrait"` على `MainActivity` في التطبيقين، ومع `targetSdk = 35`
تطلب Google Play قابلية تغيير الحجم/دعم شاشات 600dp+ أو **طلب إعفاء صريح** من سياسة
orientation/resizability. إمّا إزالة القفل/دعم التكيّف، أو تقديم طلب الإعفاء في Console قبل الرفض.

### C7 (إضافي، ليس حاجزاً). لا اختبارات على الإطلاق

```bash
git ls-tree -r --name-only origin/arena/ff5110e8-tammtool -- apps | grep -cE "src/(test|androidTest)/"   # → 0
```

⇒ `./scripts/build-apk.sh unit-test marketer` ينجح بلا أن يختبر شيئاً. أقلّ نافع: اختبار Room
DAO واحد + اختبار ViewModel لتسجيل الدخول (يمنع C1 من الرجوع)، و`androidTest` واحد للتشغيل.
البديل المؤقت الجاهز: `./scripts/apk-test.sh test --app <app>` على هاتف (فحص تثبيت/تشغيل/انهيار/لقطة).

---

## D. الترتيب الذي يولّد APK صالحاً (مقترح للوكيل 0)

| # | خطوة | أمر إنهاء مُلزم |
|---|---|---|
| 1 | `git am patches/0001` و`patches/0002` (على `74f0a54`) و`patches/0003` (على `8f92000`) | `bash -n scripts/android-sdk-setup.sh` سليم؛ `jvmargs` موجود في الملفين؛ `room.schemaLocation` في الملفين |
| 2 | دمج `apps/` من `ff5110e8` + `scripts/` والوثائق من `arena/68a3e358-tammtool` | `bash scripts/tests/mock-smoke.sh` = 89/89 |
| 3 | بناء محلي (لا يحتاج CI): `./scripts/build-apk.sh debug marketer --yes --low-memory` | `dist/marketer-debug-<ver>-<sha>.apk` أكبر من 1MB و`./scripts/apk-test.sh validate` rc=0 |
| 4 | رفع الـ workflow المصلَّح (A4) | `./scripts/ci-logs.sh <run> --gate; echo $?` → `0` وأثر APK > 1MB |
| 5 | قرار B1/B2 (توقيع) + قرار C2 (شبكة أم MVP محلي) | `bundle` موقّع في `dist/` + بصمة = بصمة Console |
| 6 | تنظيف C3/C4/C5/C6 (أذونات، إشعارات، نسخ احتياطي، اتجاه) | `aapt2 dump badging` يعرض الأذونات المطلوبة فقط؛ `grep allowBackup` مضبوط |
| 7 | اختبار حيّ: `./scripts/apk-test.sh test --app marketer` و`--app orders-delivery` | تقرير في `test-reports/` rc=0 |

**أصغر طريق لتجربة «APK على هاتف» اليوم (لا يحتاج CI ولا توقيع):** خطوة 3 وحدها —
`./scripts/build-apk.sh debug marketer` على جهاز فيه JDK 17 + SDK، مع A1 مصلَّحاً.

---

## 6. ما لم أتحقق منه (بصراحة)

- **لم أشغّل Gradle**: لا JDK ولا Android SDK ولا `services.gradle.org` في هذه البيئة. لذلك A1
  مستنتَج من قواعد Room (الافتراضي `exportSchema = true` في Room ≥ 2.x ومتطلب `schemaLocation`)
  ومن غياب أي إعداد — **وليس** من رسالة خطأ فعلية. أول `assembleDebug` حقيقي سيؤكد أو ينفي؛
  إن ظهر أنه تحذير لا خطأ فاحذف `patches/0003` وأبقِ `exportSchema = false` كإجراء وقائي.
- **C6/B4**: تفسير سياسة Play للشاشات الكبيرة وسلوك R8 مع `-keep class com.tammtool.**` عام —
  يحتاج تأكيد المنسّق من Console وقت الرفع (لا يمكن الوصول إليه من هنا).
- **لم أفحص** كل مرجع موارد (`R.*`) داخل 98 ملف Kotlin للتأكد من عدم وجود مرجع لمورد غير موجود؛
  الفحص الحقيقي يحدث في `processDebugResources` عند أول بناء.
- لم أراجع `apps/` على `6b69a15d` إلا لإثبات أنها **أقدم/أكثر كسراً** من `ff5110e8` (الأخطاء
  الأربعة ما تزال هناك)؛ لا تعتبر هذا حكماً على كود الوكيل 1 في فرعه.

---

## 7. الحالة بعد التنفيذ — ما أُصلح فعلاً في `arena/68a3e358-tammtool`

«مُطبَّق» = التعديل في الشيفرة + كل ما يمكن التحقق منه بلا Gradle (بناء `bash -n`، تحليل XML/YAML،
`git diff --check`، `scripts/tests/mock-smoke.sh` 89/89، توازن أقواس Kotlin، ومحاكاة منطق التجزئة في Python).
«لا يزال» = يحتاج Gradle/شبكة/قرار منتج لا يملكه هذا الفرع.

| البند | الحالة | ما تم بالضبط | كيف تتحقق |
|---|---|---|---|
| **A1** مخطط Room | ✅ مُطبَّق | `kapt { room.schemaLocation }` + `app/schemas/` في التطبيقين + `androidTest.assets.srcDir` ليقرأ `MigrationTestHelper` المخططات المرفوعة | `grep -n schemaLocation apps/*/app/build.gradle.kts` |
| **A2** ذاكرة Gradle | ✅ مُطبَّق (سابقاً) | `org.gradle.jvmargs=-Xmx3g` + `kotlin.daemon.jvm.options=-Xmx1536m` + `kapt.workers.isolation=process` في `apps/*/gradle.properties` | `grep -n jvmargs apps/*/gradle.properties` |
| **A3** الـ Wrapper | ⚠️ جزئي | `download-gradlew.sh` صار يحترم وسيط النسخة (كان يكتب 8.5 دائماً)، افتراضيه 8.7، واكتشاف المشاريع آلياً (4 مشاريع مُختبَرة هنا). **`gradle-wrapper.jar` لا يزال غير مرفوع** — التحميل من `services.gradle.org` محجوب في هذه البيئة | `bash scripts/download-gradlew.sh 8.7 --dry-run` + `git ls-files apps/*/*/gradle/wrapper` |
| **A4** CI الأخضر الزائف | ✅ مُطبَّق | `.github/workflows/build-apk.yml` استُبدل بالنسخة المقترحة: 12 خطوة، matrix للتطبيقين، **بوّابة «APK حقيقي > 1MB»**، رفع السجل كـ artifact (لا `git add`)، `annotations` من `* What went wrong:`، بلا `contents: write` | `python3 -c "import yaml;d=yaml.safe_load(open('.github/workflows/build-apk.yml'));print(len(d['jobs']['build']['steps']))"` → 12 |
| **A5** `android-sdk-setup.sh` | ✅ مُطبَّق | السطر 83 `<<<<>>> echo …` → `echo …`؛ معلق كوري → عربي؛ «síesno» → «sdkmanager». `bash -n` نظيف | `bash -n scripts/android-sdk-setup.sh` |
| **B1** توقيع الإصدار | ✅ مُطبَّق | `signingConfigs.create("release")` يُبنى فقط إن وُجد `keystore.properties` في الجذر، و`release` يشير إليه — بدونه يبقى السلوك القديم (ملف غير موقّع) بلا فشل جديد | `grep -n signingConfig apps/marketer/app/build.gradle.kts` |
| **B2** سياسة keystore | ✅ موثَّقة | `keystore.properties` مقبول (والـ Gradle يقرأه) + سياسة عدم الرفع والنسخ في `PLAY_STORE_RELEASE.md` §2؛ التوليد بـ keytool موصوف هناك | `ls keystore.properties 2>&1` (يجب ألا يكون مرفوعاً) |
| **B3** كلمات السر في argv | ✅ مُطبَّق | `sign-apk.sh`: `env:KEYSTORE_PASSWORD` بدل `pass:…`، ورفض صريح بلا طرفية (`[[ -t 0 ]]`) بدل تعليق `read`، + `apksigner verify --print-certs` وبصمة SHA‑256 + فحص `zipalign -c` | `grep -n "env:KEY" scripts/sign-apk.sh` |
| **B4** R8 | ⚠️ جزئي | قواعد `proguard-rules.pro` صارت نطاقاً أدق (Room/Hilt/serialization/Compose) بدل keep الشامل، مع `*Annotation*,SourceFile` و`-renamesourcefileattribute` ومِظلّة `-keep class com.tammtool.** { *; }` في النهاية قابلة للحذف. **الاحتفاظ بـ `mapping.txt` لكل إصدار ما يزال خطوة يدوية** (مسارها مذكور في `PLAY_STORE_RELEASE.md`) | `grep -c "^[[:space:]]*#" apps/marketer/app/proguard-rules.pro` |
| **B5** versionCode | ✅ مُطبَّق | `versionCode = System.getenv("TAMM_VERSION_CODE")?.toIntOrNull() ?: 1` ونفس الشيء لاسم النسخة، والـ CI يضبطهما من `github.run_number` ⇒ تسلسل monotonic تلقائي | `grep -n ciVersionCode apps/*/app/build.gradle.kts` |
| **C1** كلمة المرور لا تُتحقق | ✅ مُطبَّق | `util/PasswordHasher.kt` (PBKDF2‑HMAC‑SHA256، 120k تكرار، ملح 16 بايت، صيغة `pbkdf2:<alg>:<iter>$salt$hash`، `MessageDigest.isEqual`)؛ `login()` صار يتحقق ويرقّي المفتاح القديم؛ `register()` في التطبيقين؛ `count()` في DAO/Repository؛ أول تشغيل ينقل الشاشة لنموذج إنشاء الحساب؛ زر «إنشاء حساب جديد» المعطّل في orders فُعِّل؛ **9 فحوص وحدة لكل تطبيق** في `src/test/java` (`PasswordHasherTest`) | `ls apps/*/app/src/test -R \| head` + `python3 -` (محاكاة الصيغة في Python: 7 حالات نجحت) |
| **C2** لا طبقة شبكة | ⛔ لا يزال | قرار منتج: MVP محلي أم نقطة نهاية؟ لا يمكن «حلّه» بكتابة عميل عشوائي. المطلوب من 0+1: حقل `base_url` في `gradle.properties` + Retrofit/OkHttp أو Ktor، وإلا ابقِه محلياً وصرّح بذلك في نموذج «أمان البيانات» | `git grep -l "Retrofit\|OkHttp" -- apps` |
| **C3** أذونات ميتة | ✅ مُطبَّق | حُذفت `RECEIVE_SMS`/`SEND_SMS`/`WAKE_LOCK`/`FOREGROUND_SERVICE`/`VIBRATE` من المانيفستين مع تعليق يشرح ما يلزم إعادتها (Receiver + إقرار سياسة SMS / `<service>` + `foregroundServiceType` + `POST_NOTIFICATIONS`) | `grep -c uses-permission apps/*/app/src/main/AndroidManifest.xml` → 2 |
| **C4** الإشعارات | ⛔ لا يزال (قرار) | لا يوجد أي كود إشعارات؛ إضافته تعني `POST_NOTIFICATIONS` + طلب وقت التشغيل + `NotificationChannel` ⇒ خارج «إصلاح عيب» وتدخل في «ميزة جديدة». الجداول في Room جاهزة كطابور؛ الإمساك الحقيقي يحتاج FCM/WorkManager | `git grep -l NotificationManager -- apps` → لا نتيجة |
| **C5** النسخ الاحتياطي | ✅ مُطبَّق | `res/xml/backup_rules.xml` + `data_extraction_rules.xml` في التطبيقين تستثني `*_app_db`/`*_delivery_db` ومذكراتها و`sharedpref`، مع `fullBackupContent` (≤30) و`dataExtractionRules` (31+) | `python3 -c "import xml.etree.ElementTree as E;E.parse('apps/marketer/app/src/main/res/xml/data_extraction_rules.xml')"` |
| **C6** قفل الاتجاه | ✅ مُطبَّق | أُزيل `android:screenOrientation="portrait"` من `MainActivity` (تعارض targetSdk 35 مع سياسة الشاشات الكبيرة). إن أردت القفل فافعله عبر `WindowSizeClass` أو اطلب إعفاءً في Console | `grep -c screenOrientation apps/*/app/src/main/AndroidManifest.xml` → 0 |
| **C7** الاختبارات/التوابع | ⚠️ جزئي | صارت هناك اختبارات وحدة فعلية (ملف في كل تطبيق، 9 فحوص: منطق التجزئة/الصيغة/الرفض) + `testInstrumentationRunner` + توابع junit/espresso/coroutines-test + خطوة `unit-test` في CI. **لم يُضَف** `androidTest` على جهاز، وCoil (في orders) وTimber (في التطبيقين) ما يزالان معلَّنين بلا استخدام، وأيقونة orders ما تزال vector فقط | `find apps/*/app/src/test -name "*.kt" \| wc -l` → 2 |
| `check-env.sh` | ✅ محسَّن | فحص Java رقمياً (`17.0.2`→17، و`11.0.17`→11 — كان `grep -E '17\|21'` يمرّر JDK 11)، وفحص Wrapper **لكل مشروع** مع رسالة الإصلاح، وألوان الملخص بـ `echo -e` | `bash scripts/check-env.sh` (يفشل 7 ويذكر الأوامر) |

**ما لم يتغيّر رغم إمكانية إصلاحه هنا (عمداً، بانتظار صاحب القرار):** C2 (طبقة الشبكة)، C4 (الإشعارات)،
رفع `gradle-wrapper.jar` (شبكة محجوبة)، توليد keystore حقيقي (لا يُخزَّن في git أصلاً)، أي تأكيد
أن `assembleDebug` يمرّ — هذا كله للمنسّق 0 في CI، و**الآن بعد الدمج لا تُطبَّق `patches/0001..0003`
على هذا الفرع** لأنها صارت داخل الشيفرة (راجع `patches/README.md`).

**ترتيب التشغيل عند المنسّق 0 بعد الدمج:**

```bash
git fetch origin && git merge --no-ff origin/arena/68a3e358-tammtool
bash scripts/check-env.sh                      # يجب أن يفشل بفقرتي wrapper فقط
bash scripts/tests/mock-smoke.sh | tail -2     # 89/89
./scripts/download-gradlew.sh 8.7              # ينشئ gradlew لكل مشروع مُكتشَف
git add -f apps/*/gradle/wrapper/gradle-wrapper.jar apps/*/gradlew && git commit -m "chore: add gradle wrapper"
gh run watch                                   # الآن الفشل الحقيقي يظهر، لا «نجاح» فارغ
```

**أوامر إعادة إنتاج هذا الملف كله (بلا JDK):**

```bash
git fetch origin 'refs/heads/arena/*:refs/remotes/origin/arena/*'
B=origin/arena/ff5110e8-tammtool
git grep -n "room.schemaLocation\|exportSchema" $B -- apps
git grep -n "password\|MessageDigest" $B -- "apps/*AuthViewModel.kt"
git grep -n "RECEIVE_SMS\|FOREGROUND_SERVICE\|allowBackup\|screenOrientation" $B -- "*/AndroidManifest.xml"
git grep -l "Retrofit\|OkHttp\|NotificationManager" $B -- apps ; echo "rc=$? (1 = غير موجود ✓)"
git ls-tree -r --name-only $B -- apps | grep -cE "src/(test|androidTest)/"
```

— الوكيل 3 · 2026-11-06 · الفرع `arena/68a3e358-tammtool`
