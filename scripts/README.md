# `scripts/` — مرجع السكربتات (بناء · توقيع · اختبار · تجهيز البيئة)

> كل السكربتات: Bash فقط، بلا اعتماديات خارجية سوى `curl`/`wget` و`unzip`،
> تعمل من أي مجلد (تحدّد جذر المستودع بنفسها)، وتحترم `NO_COLOR`.
> الدليل الشامل بالخطوات: [`../BUILD_GUIDE.md`](../BUILD_GUIDE.md) · المشاكل والحلول: [`../TROUBLESHOOTING.md`](../TROUBLESHOOTING.md)

## أي سكربت أستخدم؟

| أريد أن… | السكربت |
|---|---|
| أعرف إن كان جهازي جاهزاً للبناء | `check-env.sh` أو `build-apk.sh --print-env` |
| أثبّت Android SDK بلا Android Studio | `build-apk.sh --setup-sdk` أو `android-sdk-setup.sh` |
| أضيف Gradle Wrapper للمشروع | `build-apk.sh` (يولّده تلقائياً) أو `download-gradlew.sh` |
| أبني APK / AAB محلياً | `build-apk.sh` |
| أوقّع نسخة release | `sign-apk.sh` |
| أختبر APK على هاتفي أو محاكي | `apk-test.sh test` |
| أفحص APK فقط (بلا هاتف) | `apk-test.sh validate` |
| أتأكد أن السكربتات نفسها سليمة | `tests/mock-smoke.sh` أو `apk-test.sh selftest` |

```
scripts/
├── build-apk.sh          ← البناء (debug · release · bundle · unit-test · lint)
├── apk-test.sh           ← الفحص والاختبار على الأجهزة (info · validate · test · …)
├── sign-apk.sh           ← التوقيع بـ apksigner
├── check-env.sh          ← فحص عام للبيئة
├── android-sdk-setup.sh  ← تثبيت Android SDK  (⚠ فيه خطأ صيغة حالياً — راجع §6)
├── download-gradlew.sh   ← توليد Gradle Wrapper يدوياً
└── tests/mock-smoke.sh   ← اختبار السكربتات نفسها بأدوات مزيفة
```

---

## 1. `build-apk.sh` — البناء المحلي (الإصدار 2.0)

```bash
./scripts/build-apk.sh [نوع_البناء] [اسم_التطبيق] [خيارات…]
```

### أنواع البناء

| النوع | مهمة Gradle | المخرج |
|---|---|---|
| `debug` (افتراضي) | `:app:assembleDebug` | `app/build/outputs/apk/debug/app-debug.apk` |
| `release` | `:app:assembleRelease` | `app-release.apk` أو `app-release-unsigned.apk` |
| `bundle` / `aab` | `:app:bundleRelease` | `app/build/outputs/bundle/release/app-release.aab` |
| `unit-test` | `:app:testDebugUnitTest` | نتائج JUnit + سجل في `build-logs/` |
| `lint` | `:app:lintDebug` | تقرير Lint |
| `clean` | `:app:clean` | — |

اسم التطبيق: `marketer` · `orders-delivery` · `all` · أو **أي** مجلد داخل `apps/` أو `examples/`
أو `templates/` (الاكتشاف تلقائي). الأسماء المستعارة مقبولة: `afghani`، `orders`، `delivery`.

### أمثلة

```bash
./scripts/build-apk.sh                                  # debug / marketer
./scripts/build-apk.sh debug marketer                     # نفس الشيء، صريحاً
./scripts/build-apk.sh release orders-delivery --clean    # release بعد تنظيف
./scripts/build-apk.sh bundle marketer --yes              # AAB للمتجر
./scripts/build-apk.sh unit-test all                      # اختبارات وحدات التطبيقين
./scripts/build-apk.sh debug marketer --offline --low-memory --no-daemon   # لابتوب ضعيف
./scripts/build-apk.sh debug --setup-sdk                  # يثبّت SDK ثم يبني
./scripts/build-apk.sh --task ":app:installDebug" marketer # مهمة Gradle خام
./scripts/build-apk.sh debug marketer --install           # بناء + تثبيت على الهاتف
./scripts/build-apk.sh --dry-run --print-env              # ماذا سيحدث؟ (بلا تنفيذ)
```

### كل الخيارات

| الخيار | الوصف |
|---|---|
| `--app NAME` · `--type TYPE` · `--module NAME` · `--task TASK` | بدائل صريحة للوسائط الموقوفة |
| `--sdk DIR` · `--jdk DIR` | تجاوز اكتشاف SDK / JDK |
| `--gradle-version V` | النسخة عند توليد Wrapper أو التحميل (افتراضي 8.7، أو `TAMM_GRADLE_VERSION`) |
| `--setup-sdk` | يثبّت Android SDK عند غيابه (بالسكريبت المساعد أو بالتثبيت الداخلي) |
| `--install-sdk-pkgs` | `sdkmanager` للحزم الناقصة (`platforms;android-35`, `build-tools;35.0.0`) |
| `--offline` | منع أي تنزيل (استخدام كاش `~/.gradle`) |
| `--no-daemon` | تشغيل بلا Gradle daemon |
| `--low-memory` | `-Xmx1536m` + `--no-daemon` + `--max-workers=2` |
| `--clean` | `clean` قبل البناء |
| `--refresh` | `--refresh-dependencies` |
| `--skip-env-check` | لا يفحص JDK/SDK/Gradle |
| `--output-dir DIR` | مجلد نسخ المخرجات (افتراضي `./dist`) |
| `--install` | استدعاء `apk-test.sh install` بعد نجاح البناء |
| `--dry-run` | طباعة الأوامر فقط |
| `--print-env` | طباعة ما اكتشفه من بيئة ثم الخروج |
| `--yes`, `-y` | بلا أسئلة (CI والطرفيات غير التفاعلية) |
| `--verbose`, `-v` | `--stacktrace --info` + عرض كل أمر |
| `--no-color`, `--help`, `--version` | — |

### ما يفعله بالترتيب

1. يكتشف التطبيقات ويحوّل الاسم إلى مجلد + وحدة Gradle (من `settings.gradle*`).
2. **JDK:** `JAVA_HOME` ← `PATH` ← مسارات التوزيعات (Linux/macOS/Homebrew/sdkman) — ويرفض < 17 مع أمر التثبيت المناسب لتوزيعك.
3. **SDK:** `--sdk` ← `local.properties` ← `ANDROID_HOME`/`ANDROID_SDK_ROOT` ← مسارات شائعة — ويكتب `apps/<app>/local.properties` إن لم يوجد.
4. **Gradle:** `./gradlew` ← توليد Wrapper بـ `gradle wrapper` ← تحميل توزيع رسمي إلى `~/.cache/tammtool/gradle` (مرة واحدة، بلا `sudo`).
5. البناء مع `--console=plain` وتسجيل الناتج كاملاً في `build-logs/`.
6. البحث عن المخرجات (يتحمّل تسمية `*-unsigned`) ونسخها إلى `dist/` باسم:
   `dist/<app>-<type>-v<versionName>-<gitsha>.apk` + `<…>.sha256` + `dist/latest-<app>-<type>.env`.
7. عند الفشل: يستخرج `* What went wrong:` ويطبع تلميحات مصنّفة (SDK، ذاكرة، تراخيص، اعتماديات، توقيع…).

### متغيرات البيئة

```bash
ANDROID_HOME / ANDROID_SDK_ROOT / TAMM_ANDROID_SDK
JAVA_HOME / TAMM_JDK
TAMM_GRADLE_VERSION=8.7           # النسخة الافتراضية
TAMM_GRADLE_BIN=/path/to/gradle    # مشغّل يدوي
TAMM_GRADLE_DIST_DIR=…             # أين يُخزَّن التوزيع المحمّل
TAMM_EXTRA_GRADLE_ARGS="--scan"    # وسائط إضافية
TAMM_YES=1 · NO_COLOR=1
```

### قراءة مخرجات `dist/latest-*.env`

```bash
source dist/latest-marketer-debug.env
echo "$artifact → $size · sha256=$sha256 · git=$git"
sha256sum -c dist/latest-marketer-debug.env 2>/dev/null || (cd dist && sha256sum -c "$(basename "$artifact").sha256")
```

---

## 2. `apk-test.sh` — الفحص والاختبار (الإصدار 2.0)

```bash
./scripts/apk-test.sh <أمر> [وسيط] [خيارات…]
```

**مقسّم إلى أوامر لا تحتاج جهازاً** (تعمل على أي لابتوب) **وأوامر تحتاج هاتفاً/محاكياً**:

| الأمر | جهاز؟ | يفعل |
|---|---|---|
| `info [apk]` | لا | الحزمة، الإصدار، minSdk/targetSdk، الأذونات، الحجم، SHA-256، أكبر الملفات |
| `validate [apk]` | لا | فحوص حقيقية: سلامة الأرشيف، `AndroidManifest.xml`، `classes.dex`، `resources.arsc`، التوقيع، عتبات min/targetSdk |
| `devices` | لا (يقرأ فقط) | حالة `adb devices` + ماذا تفعل إن كانت فارغة |
| `doctor` | لا | كل الأدوات المتاحة (adb · aapt2 · apksigner · emulator · …) والأجهزة |
| `emulator [--create]` | — | عرض أجهزة AVD؛ `--create` يثبّت الحزم وينشئ AVD عبر `sdkmanager`/`avdmanager` |
| `selftest` | لا | فحص صيغة السكربتات وسلاسة أوامرها |
| `install [apk]` | نعم | `adb install -r` (+`-g` مع `--grant`، +`-d` مع `--allow-downgrade`، `--reinstall` = إزالة ثم تثبيت) |
| `launch <pkg>` | نعم | يحلّ النشاط الرئيسي بـ `cmd package resolve-activity` ثم `am start -W` (وبدائل monkey) |
| `logcat <pkg>` | نعم | يحفظ آخر السجلات إلى `test-reports/…-logcat.txt` ويستخرج الأخطاء؛ `--follow` للبث الحي |
| `screenshot [file.png]` | نعم | لقطة شاشة (`exec-out screencap` وبديل `screencap`+`pull`) |
| `uninstall <pkg>` | نعم | إزالة التطبيق |
| `connect <ip:port>` | — | ربط ADB عبر الشبكة (WiFi debugging) |
| `test [apk]` | **نعم** | الاختبار الكامل: `validate` → تثبيت → تشغيل → تأكيد `pidof` → بحث `FATAL EXCEPTION`/ANR → لقطة → تقرير |

### أمثلة

```bash
./scripts/apk-test.sh validate --app marketer              # بلا هاتف، سريع ومفيد
./scripts/apk-test.sh test --app marketer --reinstall      # دورة كاملة على هاتفك
./scripts/apk-test.sh test dist/marketer-debug-v1.0.0-abcd.apk --timeout 40 --json
./scripts/apk-test.sh logcat com.tammtool.marketerapp --follow
./scripts/apk-test.sh install dist/orders-delivery-debug-v1.0.0-abcd12.apk --grant
./scripts/apk-test.sh devices
./scripts/apk-test.sh connect 192.168.1.20:5555
```

### الخيارات

`--app NAME` · `--apk PATH` · `--package PKG` · `--serial ID` · `--sdk DIR` ·
`--timeout N` (افتراضي 25) · `--out DIR` (افتراضي `test-reports/`) · `--screenshots DIR` ·
`--reinstall` · `--grant` · `--allow-downgrade` · `--no-launch` · `--no-logcat` ·
`--no-screenshot` · `--follow` · `--json` · `--dry-run` · `--yes` · `--verbose`

### رموز الخروج (صالحة كبوابة في CI)

| رمز | المعنى |
|---|---|
| 0 | نجاح كل الفحوص |
| 1 | خطأ استخدام/بيئة (أمر مجهول، `adb` غير مثبت، APK مفقود…) |
| 2 | فشل التثبيت (`INSTALL_FAILED_*`) |
| 3 | فشل التشغيل |
| 4 | انهيار / ANR / فشل الفحص الثابت |
| 5 | لا يوجد جهاز متجهز |

مثال في CI:

```bash
./scripts/apk-test.sh validate --app marketer || exit 1
./scripts/apk-test.sh test --app marketer --json --timeout 60 || exit 1
```

التقارير: `test-reports/<timestamp>-<package>-test.md` (أو `.json` مع `--json`)، وسجلات `logcat`
في نفس المجلد، واللقطات في `screenshots/`.

---

## 3. `sign-apk.sh` — التوقيع

```bash
./scripts/sign-apk.sh <input.apk> <keystore.jks> <key-alias> [output.apk]

# أو بدون كتابة كلمة المرور في سطر الأوامر:
KEYSTORE_PASSWORD='…' KEY_PASSWORD='…' \
  ./scripts/sign-apk.sh dist/marketer-release-v1.0.0-abcd.apk keystore/release.jks release-key
```

* ينفّذ `cd` إلى جذر المستودع، فاستخدم مسارات مطلقة أو نسبةً إلى الجذر.
* المخرج الافتراضي: `<input>-signed.apk`.
* ⚠ ملاحظتان (مفتوحتان، يملكهما الوكيل 2): كلمات المرور تمرر بـ `pass:…` (مرئية في `ps`)،
  وطلبها بـ `read -rp` يفشل في الطرفيات غير التفاعلية. التوثيق الموسّع في
  `../docs/workflow-sign-apk.md` (على فروع الفريق).

---

## 4. `check-env.sh` و `download-gradlew.sh`

```bash
./scripts/check-env.sh                    # JDK · SDK · adb · apksigner · Wrapper · git
./scripts/download-gradlew.sh 8.7         # يولّد gradlew/gradlew.bat + gradle-wrapper.*
```

* `check-env.sh` يبحث عن `./gradlew` في **جذر المستودع**؛ وبما أن كل تطبيق مشروع مستقل،
  فالنتيجة الطبيعية «Wrapper غير موجود» — الأنسب استخدام `./scripts/build-apk.sh --print-env`.
* `download-gradlew.sh` يكتب `distributionUrl` ثابتاً على Gradle 8.5 بغضّ النظر عن الوسائط —
  راجع `../TROUBLESHOOTING.md` §9؛ والأأمن: `./scripts/build-apk.sh debug --yes` (يولّد Wrapper
  بالإصدار الصحيح من `gradle wrapper`).

---

## 5. `android-sdk-setup.sh` — تثبيت SDK

```bash
./scripts/android-sdk-setup.sh --sdk-dir "$HOME/android-sdk" --accept-licenses
```

يحمّل Command-line Tools من Google (Linux/macOS)، يقبل التراخيص، ويثبّت
`platform-tools` + `platforms;android-35` + `build-tools;35.0.0`.

**⚠ حالة معروفة (مفتوحة):** في الفروع الحالية السطر 83 يحتوي بقايا دمج
(`<<<<>>> echo …`) فيفشل `bash -n` ويُعطّل السكربت كله. `build-apk.sh --setup-sdk`
يكتشف ذلك ويثبّت SDK داخلياً بدلاً منه، أو استخدم أوامر التثبيت اليدوي في
[`../BUILD_GUIDE.md`](../BUILD_GUIDE.md) §2.7.

---

## 6. `tests/mock-smoke.sh` — هل السكربتات نفسها سليمة؟

```bash
./scripts/tests/mock-smoke.sh        # 89 فحصاً
./scripts/tests/mock-smoke.sh -v     # مع مخرجات الحالات الفاشلة
```

يبني مستودعاً وهمياً في `/tmp` مع `java`/`gradle`/`gradlew`/`adb`/`aapt2` مزيفة، ويشغّل:
بناء debug/release/bundle/unit-test، توليد Wrapper، فشل بناء مع تشخيص، `--offline`،
`--dry-run`، نسخ `dist/` + SHA-256، `validate` (موقّع/غير موقّع)، `test` كاملاً مع تقرير
md/json، غياب الجهاز (رمز 5)، وغياب `adb`. **لا يحتاج إنترنت ولا JDK ولا صلاحيات مدير** —
صلح أن يكون خطوة أولى في CI.

---

## 7. أنماط مشتركة بين كل السكربتات

* **بلا أسئلة في CI:** كل تفاعل اختياري؛ في غير TTY يُجاب «لا» تلقائياً. استخدم `--yes` للقبول.
* **قفل البناء:** `build-apk.sh` يمنع بناءين متزامنين على نفس المستودع
  (قفل في `${TMPDIR:-/tmp}/.tamm-build-<hash>.lock`)، ورسائله تشرح كيف تحرره.
* **السجلات:** `build-logs/` (بناء) و `test-reports/` (اختبار) — كلاهما خارج git.
* **إعادة التشغيل بأمان:** كل السكربتات idempotent؛ يمكن تنفيذها بأي ترتيب وعلى أي عدد من الأجهزة.
* **الألوان:** تُعطَّل تلقائياً إن لم يكن الخرج طرفية، أو بـ `NO_COLOR=1`.

## 8. المسارات التي تُنشأ في جذر المستودع

| المسار | من | يُحذف متى |
|---|---|---|
| `dist/` | `build-apk.sh` | قبل بناء جديد أو عند التسليم |
| `build-logs/` | `build-apk.sh` | بعد تشخيص فشل |
| `test-reports/` | `apk-test.sh` | بعد مراجعة التقرير |
| `screenshots/` | `apk-test.sh` | بعد الاختبار |
| `apps/*/local.properties` | `build-apk.sh` | لا تحذفه (يحتوي `sdk.dir`) لكنه محلي |
| `~/.cache/tammtool/gradle` | `build-apk.sh` | عند تغيير نسخة Gradle |

كل ما عدا `local.properties` مُستثنى في `.gitignore`.
