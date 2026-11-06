# استكشاف الأخطاء وإصلاحها — TAMMTOOL

> مرجع الأعراض → الأسباب → الحلول لبناء وتشغيل تطبيقَي TAMMTOOL محلياً وفي GitHub Actions.
> **آخر تحديث:** 2026-11-06 (الوكيل 3 — التوثيق). راجع `BUILD_GUIDE.md` لخطوات البناء.

---

## 0. ابدأ من هنا (دقيقة واحدة)

```bash
./scripts/build-apk.sh --print-env                    # هل يرَي JDK/SDK/Gradle كما تتوقع؟
./scripts/build-apk.sh debug marketer --low-memory --no-daemon --yes
tail -n 60 build-logs/$(ls -1t build-logs | head -1) # آخر سجل بناء (أو افتح الملف كاملاً)
./scripts/apk-test.sh doctor                           # بيئة الاختبار والأجهزة
./scripts/apk-test.sh validate --app marketer          # هل الـ APK الناتج سليم أصلاً؟
```

| العرض | اذهب إلى |
|---|---|
| CI أحمر ولا أعرف السبب | §1 |
| CI **أخضر** لكن لا APK (أو artifact بحجم 153 بايت) | §1.5 |
| `Java heap space` / `OutOfMemoryError` | §2.1 |
| `SDK location not found` | §4.1 |
| `Unsupported class file major version` / `requires Java 17` | §3 |
| فشل بعد تعديل `build.gradle.kts` (Kotlin/Compose/Hilt) | §5 |
| `app-release-unsigned.apk` لا يُثبَّت | §6 |
| `no devices/emulators found` / `unauthorized` | §7 |
| خطأ غريب على Windows | §8.1 |

---

## 1. حالة CI الحالية — لماذا يفشل البناء؟

### 1.1 السبب المؤكّد (نسخة ff51): **نفاد ذاكرة Gradle — `Java heap space`** ✅

استُخرج هذا من GitHub Checks API (وليس من سجلات `--log` غير المتاحة في البيئات المقيدة):

```
run 42264822833 · branch arena/ff5110e8-tammtool · job "build"
  ✗ Build Debug APK
  annotations:
    .github:69  Java heap space
    .github:28  > Task :app:checkKotlinGradlePluginConfigurationErrors
    .github:31..35  > Task :app:generateDebugResources … :app:parseDebugLocalResources
    .github:981 Process completed with exit code 1.
```

**السبب:** `apps/*/gradle.properties` لا يضبط `org.gradle.jvmargs` إطلاقاً:

```properties
android.useAndroidX=true
android.enableJetifier=true
kotlin.code.style=official
```

فيحصل Daemon Gradle على افتراضات JVM (ربع ذاكرة الجهاز ≈ 1.75GB على `ubuntu-24.04`)،
وبناءً مع Compose + kapt (Hilt + Room) + DataBinding + Jetifier يحتاج أكثر من ذلك بكثير.

**الحل (ابدأ من هنا — عدّل الملفَين `apps/marketer/gradle.properties` و `apps/orders-delivery/gradle.properties`):**

```properties
# الذاكرة — يمنع Java heap space في CI وعلى اللابتوبات
org.gradle.jvmargs=-Xmx3g -XX:MaxMetaspaceSize=1g -Dfile.encoding=UTF-8 -XX:+HeapDumpOnOutOfMemoryError
kotlin.daemon.jvm.options=-Xmx1536m
kapt.use.worker.api=true
kapt.workers.isolation=process

# السرعة والتخزين المؤقت
org.gradle.parallel=true
org.gradle.caching=true
org.gradle.configuration-cache=false

# Jetifier ثقيل ولا حاجة له هنا (لا توجد مكتبات support قديمة) — عطّله لتوفير الذاكرة
android.enableJetifier=false
android.nonTransitiveRClass=true
```

> ملاحظة: `android.enableJetifier=true` وحده يضيف دقائق للبناء وذاكرة إضافية، ولا يوجد ما يبرّره
> في مشروع يعتمد AndroidX بالكامل.

### 1.2 سبب إضافي على فرع CI (`6b69a15d`): **إخفاء الفشل الحقيقي** ✅

```
run 42264967594 · branch arena/6b69a15d-tammtool · job "build"
  ✓ Build Debug APK - capture output to root log      ← لم يُمرَّر رمز الخروج!
  ✗ Save build log to repository (always)             ← هنا يموت الـ job
  - Upload APK artifact                                 (skipped)
```

أي أن الـ workflow الحالي يفشل **بسبب حفظ السجل** (كتابة `../ci-build.log` خارج مجلد العمل ثم
`git commit/push`) بينما نتيجة Gradle الحقيقية مفقودة. القاعدة: *لا تجعل خطوة تسجيل السجلات
تقرّر نتيجة الـ job، ولا تكتب خارج `$GITHUB_WORKSPACE`.*

### 1.3 كيف تقرأ سجلات CI حين يفشل `gh run view --log-failed`

`gh run view --log-failed` يرسل طلباً إلى `results-receiver.actions.githubusercontent.com`
(غير متاح خلف جدار الشبكة/الوكيل). الثلاثة التالية تعمل عبر `api.github.com` فقط:

```bash
# ① ما هي الخطوة الفاشلة؟
gh api repos/22kdx/TAMMTOOL/actions/runs/<RUN_ID>/jobs \
  --jq '.jobs[].steps[] | select(.conclusion=="failure") | .name'

# ② ماذا قالت الخطوة؟ (التعليقات فيها أسطر الخطأ الفعلية)
CRI=$(gh api repos/22kdx/TAMMTOOL/actions/runs/<RUN_ID>/jobs --jq '.jobs[0].check_run_url' | sed 's|.*/check-runs/||')
gh api "repos/22kdx/TAMMTOOL/check-runs/$CRI/annotations" \
  --jq '.[] | select(.annotation_level=="failure") | "\(.path):\(.start_line) \(.message)"'

# ③ إن رُفع السجل كـ artifact
gh run download <RUN_ID> --repo 22kdx/TAMMTOOL --name marketer-ci-build-log --dir ./ci-log
```

ولتجعل هذا متاحاً دائماً، أضف في الـ workflow (قبل خطوة رفع الـ artifact):

```yaml
      - name: Print build log (so it is visible in the raw log too)
        if: failure()
        run: tail -n 300 apps/marketer/ci-build.log || true
```

### 1.4 بناء محلي يضاهي CI تماماً (لاستنساخ الفشل على جهازك)

```bash
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export ANDROID_HOME="$HOME/android-sdk"
cd apps/marketer
gradle --no-daemon --console=plain :app:assembleDebug     # نفس أمر CI (Gradle 8.7)
# أو بالسكربت الذي يفعل ما سبق + يجمع السجل في build-logs/:
cd ../.. && ./scripts/build-apk.sh debug marketer --no-daemon --yes
```

### 1.5 الحالة بتاريخ 2026-11-06 (مساءً): **CI أخضر بلا APK** — فشل صامت ✅

بعد إضافة `continue-on-error: true` إلى خطوة السجل، صارت التشغيلات **تنجح** بينما لم يُبنَ شيء:

```
run 42267633951 · arena/6b69a15d-tammtool · «Build Afghani Orders APK» → success
  ✓ Build Debug APK - capture output          ← set +e، وBUILD_EXIT لا يفحصه أحد
  ✓ Save build log to repository (always)     ← «COMMIT FAILED» لأن *.log في .gitignore
  ✓ Find and upload APK artifact              ← لم يجد APK فكتب apk-output/no-apk.txt
  artifact: afghani-orders-apk = 153 بايت      ← نص «No APK was built»، ليس APK
run 42266809044 → success بلا أي artifact · run 42267253047 → فشل في خطوة البحث عن APK
```

**كيف تميّز الزيف في ثانية؟**

```bash
./scripts/ci-logs.sh <RUN_ID>          # يشرح الخطوات + الـ annotations + أحجام الـ artifacts
./scripts/ci-logs.sh <RUN_ID> --gate   # rc=1 إذا لم يكن هناك APK حقيقي (> 1MB) — صالح كبوابة CI
file <apk> && unzip -l <apk> | grep -c classes.dex
```

**الأربعة التي يجب أن تُصلَح في الـ workflow** (نسخة كاملة جاهزة في `TEAM_COLLABORATION.md` §0.4):

| الخلل | الإصلاح |
|---|---|
| `set +e` + حفظ `BUILD_EXIT` بلا فحص | `exit "$BUILD_EXIT"` في نهاية خطوة البناء، أو خطوة Gate |
| إنشاء `no-apk.txt` + `if-no-files-found: warn` | احذف الـ placeholder واجعل `if-no-files-found: error` |
| حفظ السجل بـ `git add` (مرفوض بـ `*.log`) ثم `git push` | ارفع `build-logs/` بـ `upload-artifact` و`if: always()`؛ لا commit من CI |
| لا `::error::` annotations | `grep -nE 'FAILURE: \|\* What went wrong: \|error: ' log \| sed 's/^/::error::/'` في خطوة `if: failure()` |

> **لا تثق بـ ✓ وحده في هذا المستودع.** قبل الإعلان عن «APK جاهز» نفّذ §0.8 في
> `TEAM_COLLABORATION.md` (تنزيل الأثر ثم `./scripts/apk-test.sh validate <apk>`).

---

### 1.6 أول فشل **صادق** على `arena/68a3e358` — وما كشفه (2026‑11‑06، ليلاً) ✅

`42273932002` · `completed · failure` بعد 6 دقائق لكل وظيفتين؛ سبب الفشل هذه المرة حقيقي ومفصَّل:
`Java heap space` في D8 (لا `org.gradle.jvmargs` في `apps/*/gradle.properties`) + إحداثية Compose
غير موجودة في `orders-delivery`. التفاصيل والإصلاحات في `GAP_TO_APK.md` §8 و§2.4 أعلاه.

**العبرة لأي وكيل:** إذا مرّت `Install Android SDK`/`Install Gradle`/`Self-test` وفشل `Build debug APK`
فالمشكلة في `apps/` أو في `gradle.properties` الخاص بها — **لا** في السكربتات/CI، ولا تُصلح بزيادة
مهلة أو بتجاهل الفشل. وإن نجحت كل الخطوات بلا APK ⇒ البوّابة (`Gate`) هي التي تكشف ذلك الآن.

## 2. أخطاء Gradle

| الرسالة | السبب المرجّح | الحل |
|---|---|---|
| `Java heap space` / `GC overhead limit exceeded` | لا `org.gradle.jvmargs` | §1.1 · محلياً: `--low-memory` أو `export GRADLE_OPTS="-Dorg.gradle.jvmargs=-Xmx3g"` |
| `SDK location not found` | لا `ANDROID_HOME` ولا `local.properties` | §4.1 |
| `Unsupported class file major version 65/61` | Gradle أقدم من JDK (21/17) | استعمل Gradle 8.7+ أو JDK 17 |
| `Could not determine the dependencies of task ':app:...'` | تلف كاش أو انقطاع تنزيل | `--refresh` ثم أعد المحاولة بـ `--offline` |
| `Could not GET 'https://services.gradle.org/...'` | بروكسي/جدار شبكة | `TAMM_GRADLE_BIN=/path/to/gradle` أو انسخ التوزيع إلى `~/.cache/tammtool/gradle` |
| `BUILD FAILED ... > Task :app:kaptGenerateStubsDebugKotlin` | kapt + وحدات JDK 17 module system | أضف `org.gradle.jvmargs` مع `--add-opens=jdk.compiler/com.sun.tools.javac.{code,comp,file,main,model,processing,tree,util}=ALL-UNNAMED` |
| `Task 'assembleRelease' not found` | الوحدة ليست `app` أو المشروع بلا وحدة | `./scripts/build-apk.sh --module <اسم> …` أو `--task ":app:tasks"` |
| `Gradle wrapper missing` / `gradle-wrapper.jar` مفقود | Wrapper غير مرفوع في git | `gradle wrapper --gradle-version 8.7` (السكربت يعرض فعلها تلقائياً) |
| `daemon will not start` / بطء شديد | daemon عالق | `gradle --stop` ثم `--no-daemon` |
| `./gradlew: bad substitution` أو `^M: bad interpreter` | CRLF على Windows | §8.1 |
| `Permission denied` على `./gradlew` | فقد صلاحية التنفيذ (NTFS/WSL) | `chmod +x gradlew` أو `sh ./gradlew` أو `git update-index --chmod=+x gradlew` |

---

### 2.4 `Could not find androidx.compose.material:material-window-size-class:1.6.4` ✅

رُصد في CI ‏42273932002 على `apps/orders-delivery` داخل `:app:dataBindingMergeDependencyArtifactsDebug`.

* **السبب:** إحداثية غير موجودة — `window-size-class` تُنشر تحت
  `androidx.compose.material3:material3-window-size-class`، لا تحت `androidx.compose.material`.
  ولا يوجد أي `import` لها في الشيفرة ⇒ تابعة ميتة، فحُذفت (مع تعليق في `build.gradle.kts` يسمّي البديل).
* **القاعدة العامة:** رسالة `Could not find <g>:<a>:<v>` في `debugCompileClasspath` تُصحَّح **بمسار
  الإحداثية/النسخة** لا بتعطيل المهمة؛ وتعطيل `dataBinding` هنا جاء لأنه بلا أي ملف `layout/*.xml`
  في التطبيقين (Compose فقط)، فهو خيار يُقلّل tasks والاستهلاك لا «تحييد» للخطأ.
* **تحقق محلي سريع:** `grep -rn "window-size-class" apps/*/*/build.gradle.kts` (يجب أن يُظهر تعليقاً لا `implementation`).

## 3. أخطاء JDK / Java

| الرسالة | الحل |
|---|---|
| `JAVA_HOME is not set` | `export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64` (Linux) · `export JAVA_HOME=$(/usr/libexec/java_home -v 17)` (macOS) |
| `Android Gradle plugin requires Java 17 to run. You are currently using Java 11.` | ثبّت Temurin 17 و حدّده: `./scripts/build-apk.sh --jdk /usr/lib/jvm/java-17-openjdk-amd64 debug marketer` |
| `error: invalid target release: 17` | JDK الفعلي أقدم؛ تحقق: `java -version` و `javac -version` — قد يكون هناك أكثر من JDK |
| `JAVA_HOME is set to an invalid directory` | `JAVA_HOME` يجب أن يشير إلى جذر JDK (فيه `bin/java`) لا إلى `bin/java` نفسه |

تحقق سريع:

```bash
java -version && javac -version
readlink -f "$(command -v java)"          # أين يقود فعلًا؟
./scripts/build-apk.sh debug marketer --dry-run --yes | head -20   # ماذا سيُستخدم
```

---

## 4. أخطاء Android SDK

### 4.1 `SDK location not found`

```bash
export ANDROID_HOME="$HOME/android-sdk"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
# أو مرّر المسار للسكربت (يكتب local.properties تلقائياً):
./scripts/build-apk.sh debug marketer --sdk /path/to/android-sdk
```

تحقق: `cat apps/marketer/local.properties` يجب أن يحتوي `sdk.dir=/…/android-sdk`.
انتبه: `sdk.dir` على Windows يُكتب بمسارات فيها `\` — استخدم `/` (يقبلها AGP):
`sdk.dir=C:/Users/you/AppData/Local/Android/Sdk`.

### 4.2 أخطاء متكررة أخرى

| الرسالة | الحل |
|---|---|
| `Failed to find target with hash string 'android:35'` | `sdkmanager "platforms;android-35"` |
| `Failed to find Build Tools revision 35.0.0` | `sdkmanager "build-tools;35.0.0"` |
| `License for package Android SDK Build-Tools … not accepted` | `yes \| sdkmanager --licenses` |
| `aapt2 … cannot execute binary file` | SDK مثبّت لمعمارية مختلفة (arm64 vs x86_64) — أعد التثبيت بالسكربت |
| `Android SDK not installed. install-sdk-required` | استخدم `./scripts/build-apk.sh --setup-sdk debug marketer` |
| `sdkmanager: command not found` | أضف `cmdline-tools/latest/bin` إلى PATH (وليس `tools/bin` القديم) |

**⚠️ معروفة ومؤكّدة في المستودع:** `scripts/android-sdk-setup.sh` على الفروع الحالية
**لا يعمل إطلاقاً** — السطر 83 يحتوي بقايا تعديل/دمج:

```bash
<<<<>>> echo "أدوات البناء: $BUILD_TOOLS_VERSION"
```

`bash -n scripts/android-sdk-setup.sh` يفشل → أي مسار يعتمد عليه يموت فوراً.
الحل المؤقت: `build-apk.sh` (الإصدار 2.0) **يكتشف تلف السكريبت ويثبّت SDK داخلياً** بنفسه؛
أو ثبّت SDK بالأوامر في `BUILD_GUIDE.md` §2.7. الحل الدائم: إصلاح السطر 83 (مطلوب من الوكيل 2).

---

## 5. أخطاء Kotlin / AGP / Compose / Hilt / Room

### 5.1 مصفوفة التوافق (ثبّت هذه الأرقام قبل أي تعديل)

| المكوّن | القيمة الآمنة الآن | لماذا |
|---|---|---|
| JDK | 17 | مطلوب لـ AGP 8.x |
| Gradle | 8.7 | تستخدمه CI؛ AGP 8.6 يطلب 8.7+ |
| AGP (`com.android.tools.build:gradle`) | **8.6.1** | AGP 8.2 مجرّب حتى compileSdk 34 فقط |
| Kotlin | **1.9.22** | مرتبط بإصدار Compose Compiler |
| Compose Compiler | **1.5.8** | ↔ Kotlin 1.9.22 (القائمة: release notes لـ `androidx.compose.compiler`) |
| Hilt | 2.50 | متوافق مع Kotlin 1.9.x + kapt |
| Room | 2.6.1 | يتطلب kapt/ksp + schema export dir |

أخطاء المواجهة عندما تخرق القاعدة:

| الرسالة | المعنى |
|---|---|
| `Inconsistent JVM-target compatibility detected for tasks 'compileDebugJavaWithJavac' (1.8) and 'compileDebugKotlin' (17)` | اجعل `compileOptions.sourceCompatibility/targetCompatibility` تساوي `kotlinOptions.jvmTarget` (كلها 17) |
| `Compose Compiler Kotlin plugin version (x) is not compatible with the current Kotlin version (y)` | راجع الجدول أعلاه — المواءمة بين `composeOptions.kotlinCompilerExtensionVersion` ونسخة Kotlin |
| `Could not find method kapt() for arguments […]` | نقص `id("org.jetbrains.kotlin.kapt")` في كتلة `plugins {}` مع استخدام `kapt(…)` في الاعتماديات |
| `Build was configured to prefer settings repositories over project repositories but repository 'Google' was found in build file` | يوجد `allprojects { repositories { … } }` مع `FAIL_ON_PROJECT_REPOS` في `settings.gradle.kts` — احذف `allprojects` أو غيّر الوضع إلى `PREFER_SETTINGS` |
| `Plugin with id 'com.google.gms.google-services' not found` | أما أضف `classpath`/plugin management أو احذفه (استخدام Firebase غير مطلوب محلياً) |
| `cannot find symbol class Hilt_MarketerApp` | kapt لا يعمل (انظر السطران أعلاه) |
| `warning: The following options were not recognized by any processor: '[room.schemaLocation…]'` | إعداد Room schema غير مضبوط — ليس قاتلاً لكن يزيل التتبع |

**أربع مشاكل موثّقة على فرع CI (`arena/6b69a15d-tammtool`) وتؤدي لفشل بناء حتمي**
(صُلحت كلها في `arena/ff5110e8-tammtool`؛ آخر فحص 2026-11-06 على الكوميت `7eccab8`):

1. `apps/*/app/build.gradle.kts` تستخدم `kapt(…)` بدون تطبيق `org.jetbrains.kotlin.kapt` ❌
2. `sourceCompatibility = VERSION_1_8` مع `jvmTarget = "17"` ❌
3. `allprojects { repositories }` في `apps/*/build.gradle.kts` مع `FAIL_ON_PROJECT_REPOS` ❌
4. `apps/*/app/src/main/res/values/ic_launcher_web.png.placeholder` — ملف غير XML داخل `res/values` ❌
   (AAPT2 يرفضه؛ حُذف في `ff5110e8` وباقٍ في `6b69a15d`، على التطبيقين معاً)

> **تصحيح لملاحظة سابقة:** Kotlin 1.9.20 مع Compose Compiler **1.5.4** اقتران **صحيح**
> (1.5.4 أصدرت لـ 1.9.20)، فليست عيباً — لا تُصلحها. العيب الوحيد هو خلط نسخ بين الملفين:
> 1.5.4↔1.9.20 · 1.5.5↔1.9.21 · 1.5.6…1.5.8↔1.9.22 · 1.5.14↔1.9.24 (يتأكد منها الوكيل 1
> من release notes؛ لا يمكن الوصول إليها من هذه البيئة).
>
> **انتبه عند الدمج:** `ff5110e8` ينتقل إلى AGP **8.6.1** الذي يتطلب Gradle **8.7+**، بينما
> workflow فرع CI يثبّت Gradle **8.5** ⇒ لو أُدمج `apps/` من `ff5110e8` مع workflow `6b69a15d`
> ستحصل على `Minimum supported Gradle version is 8.7. Current version is 8.5`. الرقعة في
> `TEAM_COLLABORATION.md` §0.4 تستخدم `gradle/actions/setup-gradle@v4` مع `8.7`.

### 5.2 موارد غير XML في `res/` (فشل AAPT2 غريب المظهر)

الرسالة عادة: `ERROR: <file> resource values/…; unexpected file extension` أو `AAPT2 aapt2-… error`.
القاعدة: داخل `res/values/` **XML فقط**. الملفات المؤقتة ضعها في `assets/` أو خارج `app/src`،
واحذف أي `.placeholder` (وهو ما يفعله فرع `ff5110e8` في الكوميت «Remove non-XML placeholder…»).

---

### 5.3 «بيانات الدخول غير صحيحة» رغم أن الحساب صحيح — أو لا يمكن الدخول إطلاقاً ✅

**الحالة (كانت كذلك قبل 2026‑11‑06 مساءً):** `AuthViewModel.login()` كان يبحث بالهاتف ويفحص
`isActive` **فقط** — أي كلمة مرور تُقبل؛ ولا يوجد أي مسار لإنشاء مستخدم ⇒ جدول `users` يبقى
فارغاً والدخول مستحيلاً عملياً.

**الحل المطبَّق:** `util/PasswordHasher.kt` (PBKDF2‑HMAC‑SHA256، 120k تكرار، ملح 16 بايت،
الصيغة `pbkdf2:<alg>:<iters>$<salt-hex>$<hash-hex>`) + تحقق في `login` + `register` في التطبيقين
+ `COUNT(*)` في DAO/Repository + شاشة الدخول تعرض «إنشاء أول حساب» حين تكون القاعدة فارغة.

| العَرَض | السبب | العلاج |
|---|---|---|
| «بيانات الدخول غير صحيحة» لحساب جديد | أنشأت الحساب قبل التحديث (الحقل كان نصاً صريحاً/فارغاً) | سجّل الدخول مرة بوضع الإنشاء من جديد، أو احذف بيانات التطبيق: `adb shell pm clear com.tammtool.marketerapp` |
| الدخول بطيء ~0.2–0.5 ثانية | 120k تكرار PBKDF2 — مقصود لمقاومة القوة الغاشمة | لا تُنقصه تحت 100k؛ إن أردت تحسيناً ارفع إلى `Dispatchers.IO` وقد خُصص لذلك عبر `launchBlock` |
| مستخدم قديم على API 24/25 | `PBKDF2WithHmacSHA256` غير متوفر هناك | المسار يسقط إلى `PBKDF2WithHmacSHA1` تلقائياً، واسم الخوارزمية مخزَّن داخل الصيغة نفسها |
| «رقم الهاتف مسجل مسبقاً» في أول تشغيل | هناك صف واحد على الأقل في الجدول | أضف دوراً من إدارة المستخدمين، أو امسُح القاعدة من إعدادات التطبيق |

**لا تقارن كلمات المرور يدوياً في أي كود جديد:** استخدم `PasswordHasher.verify(raw, stored)`
(يرفض النص الصريح والصيغ القصيرة ويستخدم `MessageDigest.isEqual`)، وراقب الترقية بصمت عبر
`needsRehash`. الاختبارات: `apps/*/app/src/test/java/**/PasswordHasherTest.kt` (9 فحوص لكل تطبيق).

## 6. أخطاء التوقيع والإصدار

| الرسالة | الحل |
|---|---|
| الناتج اسمه `app-release-unsigned.apk` | لا يوجد `signingConfig` — هذا طبيعي. وقّعه: `./scripts/sign-apk.sh …` ثم ثبّت الملف الموقّع |
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` على الهاتف | النسخة المثبتة موقعة بمفتاح آخر: `./scripts/apk-test.sh install … --reinstall` |
| `V1 signing only` عند الرفع للمتجر | استخدم AAB (`bundle`) ومحاذاة `apksigner --v2-signing-enabled true` |
| `Keystore file not found` | `sign-apk.sh` ينفّذ `cd` إلى جذر المستودع، فالمسارات النسبية تُحسب من هناك — استخدم مساراً مطلقاً أو `./keystore/release.jks` من الجذر |
| `keystore password was incorrect` | انتبه لـ `KEYSTORE_PASSWORD` المحفوظ بـ UTF-8/BOM أو لمسارات `$` في shell |
| `APK Signature Version 2 is required` | وقّع بـ apksigner (وليس jarsigner) |
| رفع APK إلى Play ورسالة “Debug build” | لا ترفع نسخة debug — استخدم `bundle` موقّعاً |

اختبار سريع قبل الرفع للمتجر:

```bash
./scripts/build-apk.sh bundle marketer
./scripts/apk-test.sh validate dist/marketer-bundle-*.aab 2>/dev/null || true
./scripts/apk-test.sh validate --app marketer            # على APK الموقّع
```

---

## 7. أخطاء ADB / الأجهزة / المحاكي

| الرسالة | السبب | الحل |
|---|---|---|
| `adb: command not found` | platform-tools غير مثبت | `BUILD_GUIDE.md` §2، أو `export PATH="$ANDROID_HOME/platform-tools:$PATH"` |
| `adb: no devices/emulators found` | كابل/تصحيح USB | `adb devices`؛ جرّب كابل بيانات لا شاحن؛ `./scripts/apk-test.sh devices` |
| قائمة الأجهزة فيها `unauthorized` | لم تقبل نافذة التصحيح | اقبل «Allow USB debugging» على الهاتف، أو `adb kill-server && adb devices` |
| `offline` |adb قديم مقابل هاتف حديث | حدّث platform-tools؛ `adb kill-server` |
| أكثر من جهاز | `adb -s` مطلوب | `./scripts/apk-test.sh test --serial emulator-5554` |
| `INSTALL_FAILED_OLDER_SDK` | `minSdk=24` والجهاز Android 6 | استخدم هاتفاً ≥ 7.0 أو خفّض `minSdk` (قرار فريق) |
| `INSTALL_FAILED_INSUFFICIENT_STORAGE` | لا مساحة | أنظّف الهاتف أو `adb shell pm trim-caches 2G` |
| التطبيق يثبّت ثم ينهار فوراً | كراش حقيقي | `./scripts/apk-test.sh logcat com.tammtool.marketerapp --follow` — وابحث عن `FATAL EXCEPTION` |
| المحاكي لا يقلع / `emulator: ERROR: x86 emulation currently requires hardware acceleration` | KVM | `sudo apt-get install -y qemu-kvm`؛ `sudo chown -R $USER /dev/kvm`؛ فعّل VT-x/AMD-V من BIOS |
| المحاكي بطيء جداً | GPU/RAM | `-no-window -gpu swiftshader_indirect -no-snapshot -read-only`، و`--low-memory` للبناء |

الأداة السريعة: `./scripts/apk-test.sh doctor` تعرض كل ما هو مثبت وما هي حالة الأجهزة في شاشة واحدة.

---

## 8. مشاكل البيئة المحلية

### 8.1 Windows / WSL / Git Bash

| المشكلة | الحل |
|---|---|
| `^M: bad interpreter` أو `bad substitution` في `gradlew` | CRLF: `git config core.autocrlf input`، ثم `dos2unix gradlew scripts/*.sh`، واحذف `app/build` وابدأ من جديد |
| البناء بطيء جداً في WSL | المستودع داخل `/mnt/c` — انقله إلى `~/` (فرق 5–10×) |
| `Permission denied` على `./gradlew` | `chmod +x` لا يكفي على NTFS: شغّل `sh ./gradlew …` أو `git update-index --chmod=+x` |
| `android-sdk-setup.sh` لا يدعم Windows | ثبّت SDK من Android Studio و `./scripts/build-apk.sh --sdk "C:/Users/you/AppData/Local/Android/Sdk" …` |
| مسار SDK فيه مسافات (`Program Files`) | استخدم المسار القصير أو اربط symbolic link؛ السكربت يقتبس لكن AAPT2 القديم يتعثر |
| `Filename too long` في git | `git config --global core.longpaths true` |

### 8.2 موارد الجهاز

- **قرص ممتلئ:** كاش Gradle يكبر بسهولة إلى 5GB. `du -sh ~/.gradle` ثم
  `rm -rf ~/.gradle/caches/build-cache-1 ~/.gradle/caches/*/executionHistory`.
- **ذاكرة قليلة (<6GB):** السكربت يحذّر من تلقاء نفسه — استخدم `--low-memory --no-daemon`،
  وأغلق المتصفح، وزوّد swap مؤقتاً:
  ```bash
  sudo fallocate -l 6G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile
  ```
- **شبكة/بروكسي مؤسسي:** اضبط `JAVA_OPTS="-Dhttps.proxyHost=… -Dhttps.proxyPort=…"` أو
  أنشئ `~/.gradle/gradle.properties` بـ `systemProp.https.proxyHost=…`، ثم ابنِ بـ `--offline`
  بعد أول تنزيل ناجح.
- **مضاد فيروسات يحجز الملفات (Windows):** استثنِ مجلد المستودع و `~/.gradle`.

### 8.3 المساحة الناتجة عن السكربتات (يمكن حذفها بأمان)

```bash
rm -rf dist/ build-logs/ test-reports/ screenshots/ apps/*/.gradle apps/*/app/build
```

---

## 9. مشاكل سكربتات المستودع — ما هو معروف ومُصلَح

| السكربت | المشكلة | الحالة |
|---|---|---|
| `build-apk.sh` | كان يبحث عن `app-release.apk` فيفشل على build غير موقّع | ✅ مُصلح: يبحث في `…/build/outputs` ويلتقط `app-release-unsigned.apk` |
| `build-apk.sh` | يفترض وجود `gradlew` ويسقط إن لم يوجد (المستودع لا يرفعه) | ✅ يولّده من `gradle` النظام أو يحمّل توزيعاً محلياً أو يستخدم `gradle` مباشرة |
| `build-apk.sh` | `read -r` يعلّق في CI/الأنابيب | ✅ لا يسأل أبداً في غير TTY؛ استخدم `--yes` |
| `build-apk.sh` | مسار المخرجات كان `app/outputs` بدل `app/build/outputs` | ✅ مُصلح (وغطّاه الاختبار الوهمي) |
| `build-apk.sh` | لا يتحقق من نسخة Java → رسائل خطأ غير مفهومة من Gradle | ✅ يفحص JDK ≥ 17 ويقترح أمر التثبيت لكل توزيعة |
| `apk-test.sh` | كان يفترض `com.tammtool.marketerapp` حتى لاختبار orders-delivery | ✅ يستخرج الحزمة من APK (aapt2 → aapt → apkanalyzer → تحليل Manifest) أو `--package` |
| `apk-test.sh` | `timeout … adb logcat \| grep` يكسر `pipefail` ويعطي نجاحاً زائفاً | ✅ فحوص فعلية (pid + بحث FATAL/ANR) ورموز خروج 2/3/4/5 |
| `apk-test.sh` | فشل غامض إن لم يكن `adb` مثبتاً | ✅ رسالة فيها أمر التثبيت لكل نظام، وكل أوامر الفحص الثابت تعمل بدونه |
| `android-sdk-setup.sh` | **سطر 83 فيه بقايا `<<<<>>>` → خطأ صيغة** | ✅ مُصلح في `arena/68a3e358` (2026‑11‑06): السطر أصبح `echo …`؛ وعُلِّق كوري صار عربياً؛ و«síesno» → «sdkmanager». `bash -n` نظيف، والـ workflow يناديه بـ `--sdk-dir … --accept-licenses` (الوسيطان موجودان فعلاً) |
| `android-sdk-setup.sh` | يثبّت `build-tools;35.0.0` بينما CI يثبّت `34.0.0` | ⚠️ تفاوت — يُفضّل توحيد الرقم (AGP 8.6 يعمل مع 34.0.0 و35.0.0) |
| `download-gradlew.sh` | يكتب `distributionUrl=gradle-8.5-bin.zip` ثابتاً بغض النظر عن نسخة الطلب | ✅ مُصلح: الـ heredoc صار غير مقبوس ويستخدم `$GRADLE_VERSION` (افتراضي **8.7** لمطابقة AGP 8.6) + `validateDistributionUrl=true` + اكتشاف المشاريع بدل قائمة يدوية (يُصلح `apps/marketer` و`apps/orders-delivery` و`examples/hello-world` و`templates/basic-app`) |
| `sign-apk.sh` | كلمات المرور في `--ks-pass pass:…` (مرئية في `ps`) وسؤال غير تفاعلي يفشل | ✅ مُصلح: `--ks-pass env:KEYSTORE_PASSWORD` / `env:KEY_PASSWORD`، وبلا TTY يرفض برسالة واضحة بدل التعليق، ويطبع `verify --verbose --print-certs` (البصمة التي تُقارَن في Play) + فحص `zipalign -c` |
| `check-env.sh` | يفحص `./gradlew` في جذر المستودع (حيث لا يوجد أبداً) | ✅ مُصلح: يفحص `gradlew` + `gradle-wrapper.jar` **لكل مشروع** ويأمر بـ `download-gradlew.sh 8.7` عند الغياب؛ وفحص Java صار رقمياً (`11.0.17` كان يمرّ لأن `grep -E '17\|21\|…'` يطابق أي سطر يحوي 17)؛ وألوان الملخص بـ `echo -e` |

**يبقى مفتوحاً هنا:** لا يمكن توليد `gradle-wrapper.jar` فعلياً في هذه البيئة (`services.gradle.org`
محجوب)، فأمر `download-gradlew.sh` يُنفَّذ في CI أو على جهازك ثم يُرفَع الـ jar:

```bash
./scripts/download-gradlew.sh 8.7
git add -f apps/*/gradlew apps/*/gradle/wrapper/gradle-wrapper.jar apps/*/gradle/wrapper/gradle-wrapper.properties
```

**للاطمئنان إلى السكربتات نفسها** (بلا Android، بلا هاتف، بلا إنترنت):

```bash
./scripts/tests/mock-smoke.sh        # 90 فحصاً بمحاكاة java/gradle/adb/aapt2
./scripts/apk-test.sh selftest       # فحص صيغة وسلاسة أوامر
```

---

## 10. قوائم تحقق

**قبل البناء:**

- [ ] `java -version` يُظهر 17 · [ ] `ANDROID_HOME` صحيح وموجود · [ ] مساحة ≥ 10GB
- [ ] `./scripts/build-apk.sh --print-env` يعرض التطبيق والمجلد الصحيحين

**بعد البناء وقبل التسليم:**

- [ ] `./scripts/apk-test.sh validate` بلا أخطاء · [ ] الحجم منطقي (debug ≈ 10–30MB، release أصغر)
- [ ] `minSdk`/`targetSdk` كما هو متفق · [ ] نسخة `release` موقعة (لا `unsigned`)

**قبل تثبيت على هاتف شخص ما:**

- [ ] وقّع debug بنفس المفتاح المألوف أو استخدم `--reinstall` · [ ] `adb devices` بحالة `device`
- [ ] `./scripts/apk-test.sh test` يعطي «نتيجة الاختبار: ناجح»

---

## 11. طلب المساعدة — أرفق هذا

```bash
{ echo "== build-apk =="; ./scripts/build-apk.sh --print-env;
  echo "== env =="; java -version; gradle --version; echo "$ANDROID_HOME"; uname -a;
  echo "== last build log =="; tail -n 80 build-logs/$(ls -1t build-logs 2>/dev/null | head -1);
} > tammtool-diagnostic.txt 2>&1
```

ثم أرسل `tammtool-diagnostic.txt` (لا ترسل لقطات شاشة فقط)، ومعها: الأمر الحرفي الذي
شغّلته، والفرع/الـ commit، وهل الفشل محلي أم في CI (و`RUN_ID` إن كان CI).
