# ما الذي ينقص لإنتاج التطبيق؟ — قائمة الفجوات بالأولوية

> تحليل الوكيل 3 (التوثيق) بتاريخ **2026-11-06**، مبني على فحص ملفات الفروع الفعلية:
> فرع الكود `origin/arena/ff5110e8-tammtool` @ `8f92000` (أكمل نسخة من `apps/`) وفرع CI
> `origin/arena/6b69a15d-tammtool` @ `74f0a54`. كل سطر فيه **أمر يثبتُه** و**سطر يُصلحه**.
> لم يُنفَّذ أي بناء Gradle في بيئة العمل (لا JDK/SDK/شبكة) — ما لم أتحقق منه مذكور في §6.

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
