# دليل البناء — TAMMTOOL (محلياً وعبر CI)

> **لمن هذا الدليل؟** لمطوّر يملك لابتوب عادياً (Linux / macOS / Windows+WSL) ويريد
> بناء APK لتطبيقي TAMMTOOL وتشغيله على هاتفه، دون تثبيت Android Studio ودون صلاحيات مدير.
>
> **آخر تحديث:** 2026-11-06 (الوكيل 3 — التوثيق) · سكربتات الإصدار `2.0`

---

## 0. خريطة المستودع

```
TAMMTOOL/
├── apps/
│   ├── marketer/            ← تطبيق «طلبات الأفغاني» (المسوق) — مشروع Gradle مستقل
│   │   ├── settings.gradle.kts
│   │   ├── build.gradle.kts       (جذر المشروع: buildscript + classpath)
│   │   ├── gradle.properties
│   │   └── app/                   ← وحدة التطبيق :app
│   │       ├── build.gradle.kts   (namespace / applicationId / compileSdk …)
│   │       └── src/main/…
│   └── orders-delivery/     ← التطبيق الرئيسي (إدارة الطلبات والتوصيل) — نفس البنية
├── scripts/                 ← سكربتات البناء والاختبار (هذا الدليل يشرحها)
├── docs/                    ← ملاحظات سير عمل GitHub Actions
├── .github/workflows/build-apk.yml   ← بناء CI
├── dist/                    ← ← ناتج البناء المحلي (غير متابع في git)
├── build-logs/              ← سجلات كل بناء (غير متابعة في git)
└── test-reports/            ← تقارير apk-test.sh (غير متابعة في git)
```

**نقطتان مهمتان:**

1. كل تطبيق **مشروع Gradle مستقل بذاته** (`apps/<app>/settings.gradle.kts`). لا يوجد مشروع جذر واحد،
   لذلك كل أمر gradle يجب أن يُنفَّذ **داخل** `apps/<app>` — وهو ما يفعله `scripts/build-apk.sh` نيابة عنك.
2. **لا يوجد Gradle Wrapper (`gradlew`) مرفوعاً في المستودع** حتى الآن. السكربت يولّده تلقائياً
   عند أول بناء (يتطلب `gradle` على الجهاز أو تنزيلاً لمرة واحدة)، ويُنصح بشدّة أن يُضاف
   `gradlew` + `gradle/wrapper/gradle-wrapper.jar` إلى git لاحقاً ليصبح البناء متطابقاً محلياً وفي CI.

---

## 1. المتطلبات الدنيا

| المكوّن | الحد الأدنى | ملاحظة |
|---|---|---|
| JDK | **17** (يُفضّل Temurin 17) | JDK 21 يعمل أيضاً؛ JDK 11 **يفشل** |
| Gradle | 8.2+ (المُوصى: **8.7**) | النسخة المستخدمة في CI هي 8.7 |
| Android SDK | Platform `android-35` + Build-Tools `34.0.0`/`35.0.0` + Platform-Tools | يُثبَّت عبر `scripts/android-sdk-setup.sh` |
| ذاكرة RAM | 8GB (الحد الأدنى العملي 6GB مع `--low-memory`) | kapt + Compose شره للذاكرة |
| مساحة قرص | ~12GB | 5GB كاش Gradle بعد أول بناء + SDK ~3GB |
| إنترنت | مطلوب **لأول بناء فقط** | بعدها استخدم `--offline` |

تحقق سريع من بيئتك:

```bash
./scripts/check-env.sh          # فحص JDK / SDK / adb / apksigner / Wrapper
./scripts/build-apk.sh --print-env   # ما رآه سكريبت البناء بالضبط
```

---

## 2. التثبيت حسب النظام

> كل الأوامر التالية لا تحتاج سوى ما كُتب `sudo` أمامه. الخيارات بدون `sudo`
> (sdkman / تحميل يدوي) تعمل على جهاز مقفول الصلاحيات.

### 2.1 Ubuntu / Debian (22.04 و 24.04)

```bash
sudo apt-get update
sudo apt-get install -y openjdk-17-jdk unzip curl git
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
```

### 2.2 Fedora / CentOS Stream

```bash
sudo dnf install -y java-17-openjdk-devel unzip curl git
export JAVA_HOME=$(readlink -f /usr/lib/jvm/java-17-openjdk | sed 's|/bin/java||')
```

### 2.3 Arch Linux

```bash
sudo pacman -S --noconfirm jdk17-openjdk unzip curl git
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
```

### 2.4 macOS (Intel و Apple Silicon)

```bash
brew install --cask temurin@17
brew install unzip curl git
# Android SDK (إن أردت إدارته يدوياً)
brew install --cask android-commandlinetools
export ANDROID_HOME="$(brew --prefix)/share/android-commandlinetools"
```

### 2.5 Windows

الطريقتان المدعومتان:

* **WSL2 (موصى به):**
  ```powershell
  wsl --install -d Ubuntu-24.04
  ```
  ثم من داخل Ubuntu نفّذ خطوات 2.1، و clone المستودع داخل WSL (لا في `/mnt/c`) لأن
  البناء على نظام ملفات Windows أبطأ بعشرة أضعاف ويسبب مشاكل صلاحيات.
* **Git Bash:** يعمل للبناء، لكن `scripts/android-sdk-setup.sh` لا يدعم Windows مباشرة؛
  استخدم Android Studio SDK Manager أو صدّق `--sdk` إلى SDK موجود.

### 2.6 بدون صلاحيات مدير (أي توزيعة)

```bash
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"
sdk install java 17.0.11-tem
sdk install gradle 8.7
```

### 2.7 Android SDK (بلا Android Studio)

```bash
./scripts/android-sdk-setup.sh --sdk-dir "$HOME/android-sdk" --accept-licenses
export ANDROID_HOME="$HOME/android-sdk"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
```

أو يدوياً (نفس ما يفعله CI بالضبط):

```bash
SDK="$HOME/android-sdk"; mkdir -p "$SDK/cmdline-tools"
curl -fsSL -o /tmp/clt.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
unzip -q /tmp/clt.zip -d "$SDK/cmdline-tools" && mv "$SDK/cmdline-tools/cmdline-tools" "$SDK/cmdline-tools/latest"
yes | "$SDK/cmdline-tools/latest/bin/sdkmanager" --sdk_root="$SDK" --licenses >/dev/null
"$SDK/cmdline-tools/latest/bin/sdkmanager" --sdk_root="$SDK" 'platform-tools' 'platforms;android-35' 'build-tools;35.0.0'
```

### 2.8 Gradle (اختياري — السكربت يدبّر نفسه)

```bash
# إن كان لديك gradle على النظام، فسكريبت البناء سيولّد Wrapper تلقائياً:
gradle --version        # يجب أن تكون 8.2 أو أحدث
```

إن لم يكن: `build-apk.sh` يعرض تحميل توزيع Gradle الرسمي إلى `~/.cache/tammtool/gradle`
(مرة واحدة، بلا `sudo`)، أو حدّده بنفسك: `TAMM_GRADLE_BIN=/path/to/gradle`.

---

## 3. البناء محلياً — 5 دقائق من الصفر

```bash
git clone https://github.com/22kdx/TAMMTOOL.git && cd TAMMTOOL
export ANDROID_HOME="$HOME/android-sdk"          # إن لم يكن مضبوطاً

./scripts/build-apk.sh debug marketer            # ① أهم أمر في الدليل
./scripts/apk-test.sh validate --app marketer     # ② فحص الـ APK (لا يحتاج هاتفاً)
./scripts/apk-test.sh test --app marketer         # ③ تثبيته وتشغيله على هاتفك
```

* أول بناء ينزّل الاعتماديات (~2–5GB) فقد يستغرق 10–25 دقيقة حسب الشبكة.
* البناءات التالية ثوانٍ إلى دقائق قليلة.
* الناتج النهائي يُنسخ تلقائياً إلى `dist/` باسم يحمل التطبيق والنوع والإصدار ورقم الـ commit،
  مع ملف `.sha256` وملخص `dist/latest-<app>-<type>.env`:

```
dist/marketer-debug-v1.0.0-bd81524.apk
dist/marketer-debug-v1.0.0-bd81524.apk.sha256
dist/latest-marketer-debug.env
```

### 3.1 كل أنواع البناء

| المطلوب | الأمر |
|---|---|
| Debug APK | `./scripts/build-apk.sh debug marketer` |
| Release APK | `./scripts/build-apk.sh release marketer` |
| AAB (للمتجر) | `./scripts/build-apk.sh bundle marketer` |
| اختبارات الوحدات | `./scripts/build-apk.sh unit-test marketer` |
| Lint | `./scripts/build-apk.sh lint marketer` |
| التطبيقان معاً | `./scripts/build-apk.sh debug all` |
| تطبيق خارج `apps/` | `./scripts/build-apk.sh debug hello-world` (من `examples/`) |
| مهمة Gradle خام | `./scripts/build-apk.sh --task ":app:assembleDebugAndroidTest" marketer` |

### 3.2 خيارات يستفيد منها Laptop الضعيف أو الشبكة السيئة

| الخيار | يفعل |
|---|---|
| `--low-memory` | `-Xmx1536m` + إيقاف daemon + `--max-workers=2` — يمنع «Java heap space» |
| `--offline` | بلا إنترنت: يستخدم كاش `~/.gradle` فقط |
| `--no-daemon` | لا إبقاء عملية Gradle في الخلفية (مفيد على الأجهزة الصغيرة و CI) |
| `--clean` | `clean` قبل البناء (عند الشك في كاش تالف) |
| `--refresh` | `--refresh-dependencies` عند تلف تنزيل اعتمادية |
| `--sdk DIR` / `--jdk DIR` | تجاوز الاكتشاف التلقائي |
| `--setup-sdk` | يثبّت Android SDK تلقائياً ثم يبني |
| `--dry-run` | يطبع ما سيفعله دون تنفيذ (ممتاز للاستكشاف) |
| `--yes` | لا يسأل؛ يوافق تلقائياً (CI / الطرفيات غير التفاعلية) |
| `--install` | يبني ثم يثبّت على الهاتف مباشرة |
| `--skip-env-check` | لا يفحص البيئة (من يعرف جهازه) |

مثال كامل لابتوب 4GB RAM بدون إنترنت مستقر:

```bash
./scripts/build-apk.sh debug marketer --low-memory --offline --no-daemon --yes
```

### 3.3 متغيرات بيئة مفيدة

```bash
export TAMM_ANDROID_SDK="$HOME/android-sdk"   # تجاوز ANDROID_HOME
export TAMM_JDK="/usr/lib/jvm/java-17-openjdk-amd64"
export TAMM_GRADLE_VERSION=8.7                 # النسخة عند توليد Wrapper
export TAMM_GRADLE_DIST_DIR="$HOME/.cache/tammtool/gradle"
export TAMM_EXTRA_GRADLE_ARGS="--scan"          # أي وسائط إضافية (على مسؤوليتك)
export TAMM_YES=1                                 # رد تلقائي بـ«نعم» على الأسئلة
export NO_COLOR=1                                 # بدون ألوان (لقصّ السجلات)
```

### 3.4 ماذا يحدث خلف الكواليس؟

`build-apk.sh` بالترتيب:

1. يكتشف التطبيقات من `apps/` و `examples/` (أي مجلد فيه `settings.gradle*` أو `app/build.gradle*`).
2. يبحث عن JDK (‏`JAVA_HOME` ← PATH ← مسارات التوزيعات الشائعة) ويتأكد أنه ≥ 17.
3. يبحث عن Android SDK (‏`--sdk` ← `local.properties` ← `ANDROID_HOME`/`ANDROID_SDK_ROOT` ← مسارات شائعة)
   ويكتب `apps/<app>/local.properties` إن لم يكن موجوداً (الملف مستثنى من git).
4. يختار مشغّل Gradle: إن وُجد `./gradlew` يستخدمه؛ وإلا يولّده بـ `gradle wrapper`؛ وإلا يحمّل توزيعاً محلياً.
5. يشغّل المهمة المطلوبة داخل `apps/<app>` مع `--console=plain`، ويسجّل كل شيء في
   `build-logs/<app>-<type>-<timestamp>.log`.
6. يبحث عن المخرج في `apps/<app>/app/build/outputs/…` (يتحمّل أسماء `app-release-unsigned.apk`)
   وينسخه إلى `dist/` مع SHA-256 وملخص.
7. عند الفشل يستخرج `* What went wrong:` من السجل ويطبع تلميحات مُصنّفة (انظر `TROUBLESHOOTING.md`).

---

## 4. التوقيع (Release / المتجر)

بناء `release` بدون keystore يعطي `app-release-unsigned.apk` **لا يُثبَّت على جهاز**. للتوقيع:

```bash
# ① أنشئ keystore مرة واحدة واحتفظ به في مكان آمن (فقدانه = استحالة التحديث على Play)
keytool -genkeypair -v -keystore keystore/release.jks -alias release-key \
        -keyalg RSA -keysize 2048 -validity 10000

# ② وقّع
KEYSTORE_PASSWORD='…' KEY_PASSWORD='…' \
  ./scripts/sign-apk.sh dist/marketer-release-v1.0.0-xxxx.apk \
                      keystore/release.jks release-key \
                      dist/marketer-release-signed.apk

# ③ تحقق
./scripts/apk-test.sh validate dist/marketer-release-signed.apk
```

> ⚠️ لا ترفع `keystore/` إلى git أبداً (`.gitignore` يستثني `*.jks` و`*.keystore`).
> ملاحظة أمنية على `scripts/sign-apk.sh` الحالي: يمرّر كلمات المرور عبر `--ks-pass pass:…`
> (مرئية في `ps`) ويقرأها بـ `read -rp` بدون تحقق — راجع `TEAM_COLLABORATION.md`.

قائمة قبل رفع أي نسخة للمتجر:

- [ ] `versionCode` أكبر من السابق، و `versionName` محدّث
- [ ] البناء `bundle` (AAB) لا APK للمتجر
- [ ] التوقيع بمفتاح الإصدار (وليس debug keystore)
- [ ] `./scripts/apk-test.sh validate` يمرّ بلا أخطاء
- [ ] تم تشغيله على هاتف حقيقي: `./scripts/apk-test.sh test --app marketer`

---

## 5. الاختبار على جهاز

### 5.1 هاتف عبر USB

1. فعّل **خيارات المطوّر** ← **تصحيح USB** على الهاتف.
2. `adb devices` — يجب أن تظهر الحالة `device` (لا `unauthorized` / `offline`).
3. ```bash
   ./scripts/apk-test.sh test --app marketer --reinstall
   ```
   يثبّت، يشغّل، يتأكد أن العملية حيّة، يبحث عن `FATAL EXCEPTION`/ANR، يلتقط شاشة،
   ويكتب تقريراً في `test-reports/<time>-<package>-test.md`. خروجه `0` فقط عند نجاح كل خطوة —
   لذا يصلح بوابةً في CI.

أوامر يدوية مفيدة:

```bash
./scripts/apk-test.sh devices
./scripts/apk-test.sh install dist/marketer-debug-v1.0.0-xxxx.apk --grant
./scripts/apk-test.sh launch com.tammtool.marketerapp
./scripts/apk-test.sh logcat com.tammtool.marketerapp          # آخر السجلات
./scripts/apk-test.sh logcat com.tammtool.marketerapp --follow # بثّ حي
./scripts/apk-test.sh screenshot ~/Desktop/screen.png
./scripts/apk-test.sh connect 192.168.1.20:5555               # ADB فوق WiFi
```

### 5.2 لا هاتف؟ محاكي محلي

```bash
sudo apt-get install -y qemu-kvm                 # تسريع (Linux)
./scripts/apk-test.sh emulator --create          # يثبّت الحزم وينشئ AVD باسم tamm_avd
"$HOME/android-sdk/emulator/emulator" -avd tamm_avd -no-window -no-audio &
adb wait-for-device
./scripts/apk-test.sh test --app marketer
```

يحتاج ~10GB مساحة ومعالجاً بدعم VT-x/AMD-V. على Apple Silicon استخدم صورة `*-google_apis_arm64`
بدل `x86_64` (عدّل الأمر داخل `cmd_emulator`).

### 5.3 بدون أي جهاز إطلاقاً

```bash
./scripts/apk-test.sh validate --app marketer     # بنية + توقيع + إصدارات + أحجام
./scripts/apk-test.sh info --app marketer
```

---

## 6. البناء عبر GitHub Actions

### 6.1 الحالي

الملف `.github/workflows/build-apk.yml` (على فروع العمل) يقوم بـ:

1. `setup-java` JDK 17 (temurin)
2. تثبيت Android SDK يدوياً بـ curl (‏`platform-tools` + `platforms;android-35` + `build-tools;34.0.0`)
3. `gradle/actions/setup-gradle@v4` بالإصدار **8.7**
4. `gradle :app:assembleDebug` داخل `apps/marketer` مع `tee ci-build.log`
5. رفع `ci-build.log` و `app-debug.apk` كـ artifacts

### 6.2 تنزيل APK من CI

```bash
gh run list --repo 22kdx/TAMMTOOL --limit 5
gh run download <RUN_ID> --repo 22kdx/TAMMTOOL --name marketer-debug-apk --dir ./ci-apk
```

### 6.3 قراءة سجل البناء عندما يفشل API

`gh run view --log-failed` يفشل في البيئات المقيدة (يذهب إلى
`results-receiver.actions.githubusercontent.com`). البديل الذي **يعمل عبر API الرسمي**:

```bash
RUN=42264822833
CRI=$(gh api "repos/22kdx/TAMMTOOL/actions/runs/$RUN/jobs" --jq '.jobs[0].check_run_url' | sed 's|.*/check-runs/||')
gh api "repos/22kdx/TAMMTOOL/check-runs/$CRI/annotations" \
  --jq '.[] | select(.annotation_level=="failure") | "\(.path):\(.start_line) \(.message)"'
```

هذا هو المصدر الذي اكتُشف منه سبب فشل CI الحالي («Java heap space») — التفاصيل في
`TROUBLESHOOTING.md` §1.

### 6.4 اقتراح لتحسين CI (سطر واحد يوفّر ساعات)

في `apps/*/gradle.properties` أضف (أو في workflow عبر `GRADLE_OPTS`):

```properties
org.gradle.jvmargs=-Xmx3g -XX:MaxMetaspaceSize=1g -Dfile.encoding=UTF-8
kotlin.daemon.jvm.options=-Xmx1536m
org.gradle.parallel=true
org.gradle.caching=true
```

ثم استبدل أمر البناء في CI بالسكربت الموحد ليصبح السلوك محلياً = CI:

```yaml
      - name: Build Debug APK
        run: ./scripts/build-apk.sh debug marketer --no-daemon --yes
```

---

## 7. اختبار السكربتات نفسها (بلا Android)

```bash
./scripts/apk-test.sh selftest        # فحص صيغة + سلاسة الأوامر
./scripts/tests/mock-smoke.sh         # 87 فحصاً بمحاكاة java/gradle/adb/aapt2
./scripts/tests/mock-smoke.sh -v      # مع عرض مخرجات الحالة الفاشلة
```

`mock-smoke.sh` يبني مستودعاً وهمياً في `/tmp` ويشغّل السكربتات على: بناء ناجح، فشل
بناء مع تشخيص، توليد Wrapper، APK غير موقّع، فحص ثابت، اختبار حيّ، غياب الجهاز، وغياب
`adb`. **لا يحتاج إنترنت ولا JDK** — آمن لتشغيله في CI قبل تشغيل البناء الحقيقي.

---

## 8. أنظّف، أبدأ من الصفر

```bash
./scripts/build-apk.sh clean marketer              # gradle clean
rm -rf ~/.gradle/caches/build-cache-1              # كاش بناء تالف
rm -rf apps/marketer/app/build dist build-logs     # ناتج محلي
gradle --stop                                       # إيقاف daemon المعلّق
```

---

## 9. اقرأ أيضاً

* `TROUBLESHOOTING.md` — الأعراض → الأسباب → الحلول (بما فيها حالة CI الحالية)
* `scripts/README.md` — مرجع أوامر السكربتات كاملاً
* `AGENTS_STATUS.md` — حالة الفريق وما تم إنجازه
* `TEAM_COLLABORATION.md` — ملاحظات متقاطعة على ملفات الوكلاء الآخرين
* `docs/workflow-build-apk.md`, `docs/workflow-sign-apk.md`, `docs/workflow-publish-play-store.md`
