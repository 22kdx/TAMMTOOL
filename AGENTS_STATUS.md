# حالة فريق العمل — TAMMTOOL

> **كيف يُحدَّث هذا الملف؟** كل وكيل يكتب **فقط** داخل قسمه، ويضيف سطر «آخر تحديث» بالتاريخ.
> لا تعدّل أقسام غيرك؛ الرسائل العَرَضية لوكيل آخر توضع في [`TEAM_COLLABORATION.md`](TEAM_COLLABORATION.md).
> الهدف: ملف واحد يعرف فيه المنسّق ما تمّ، ما تعطّل، وما الذي سيُدْمَج. التواصل كله هنا داخل
> المستودع (هذا الملف + `TEAM_COLLABORATION.md`) — لا رسائل خارجه؛ وإن كان لك سؤال على وكيل،
> اكتب سطر «مطلوب من الوكيل N» في قسمك واشر إليه برقم القسم في الملف الآخر.

**آخر تحديث للملف كله:** 2026-11-06 (مسائي) — الوكيل 3 · التسليم إلى الوكيل 0 في `TEAM_COLLABORATION.md` §0

---

## لوحة الحالة

| الوكيل | النطاق | الحالة | الفرع | الدليل / المخرجات |
|---|---|---|---|---|
| **0 — المنسّق** | إصلاح CI، قراءة السجلات، الدمج، APK نهائي | 🔴 يحتاج تدخلاً | فرعاه: `6b69a15d` (CI) · `ff5110e8` (كود) | **CI «أخضر زائف»**: run `42267633951` = success مع artifact وحيد `afghani-orders-apk` بحجم **153 بايت** (placeholder) · run `42266809044` = success بلا أي artifact · السبب الجذري الأصلي `Java heap space` (run `42264822833`) لم يُصلَّح بعد |
| **1 — مراجعة الكود** | Kotlin/Gradle للتطبيقين | 🟢 تقدّم واضح (لم يحدّث قسمه) | `arena/ff5110e8-tammtool` | أصلح kapt · `VERSION_17` · Compose 1.5.8/Kotlin 1.9.22 + AGP 8.6.1 · حذف ملف `res/values/*.placeholder` · أزال `allprojects { repositories }`. **باقٍ:** `gradle.properties` بلا `jvmargs` |
| **2 — الأدوات والسكريبتات** | `scripts/*.sh` | 🟡 تداخل مع الوكيل 3 | `arena/6b69a15d-tammtool` | 6 سكربتات؛ **`android-sdk-setup.sh` سطر 83 معطّل الصياغة**؛ `sign-apk.sh` يمرّر كلمات السر في argv |
| **3 — التوثيق والتقارير** | وثائق + سكربتات البناء/الاختبار + قراءة CI | 🟢 **منجَز ومسلَّم** | `arena/68a3e358-tammtool` (HEAD `fe81f1c` فروع أخرى تتحرك) | `BUILD_GUIDE.md` · `TROUBLESHOOTING.md` · `scripts/README.md` · `build-apk.sh` v2.1 · `apk-test.sh` v2 · `ci-logs.sh` (جديد) · `tests/mock-smoke.sh` (89/89 ✓) |

**الحالة الإجمالية للمشروع:** 🔴 لا APK من CI. المشكلتان مستقلتان ويجب إصلاحهما معاً:
**(أ)** نفاد ذاكرة Gradle (`Java heap space`) — سطرَان في `gradle.properties`؛
**(ب)** الـ workflow يخفي الفشل (بناء بـ `set +e` + placeholder + `if-no-files-found: warn`) فلا يرى أحد أن البناء لم يُنتج شيئاً. الرقعتان جاهزتان في `TEAM_COLLABORATION.md` §0.3/§0.4.

---

## الوكيل 3 — التوثيق والتقارير (+ أعمال سكربتات مساندة)

### ما تم إنجازه

| # | المخرَج | التفاصيل | التحقق |
|---|---|---|---|
| 1 | `BUILD_GUIDE.md` | دليل خطوة بخطوة: المتطلبات، التثبيت لكل نظام (Ubuntu / Fedora / Arch / macOS / WSL / Git Bash / sdkman)، البناء المحلي بكل الأنواع، التوقيع، الاختبار على هاتف أو محاكي أو بلا جهاز، البناء عبر CI وقراءة سجلاته، التنظيف | كُتب بعد قراءة `apps/*/build.gradle.kts` و`.github/workflows/build-apk.yml` و`scripts/*` من فروع الفريق |
| 2 | `TROUBLESHOOTING.md` | 11 قسماً: حالة CI بالأدلة، جداول رسائل خطأ Gradle / JDK / SDK / Kotlin-AGP / التوقيع / ADB / المحاكي / Windows، جدول «مُصلَح ↔ مفتوح» للسكربتات، قوائم تحقق، قالب طلب مساعدة | السبب الجذري للـ CI مستخرج فعلياً من `gh api …/check-runs/<id>/annotations` |
| 3 | `scripts/README.md` | مرجع كامل لسكربتات `scripts/`: الأوامر، جداول الخيارات، متغيرات البيئة، رموز الخروج، أمثلة، وما يفعله كل سكربت بالترتيب | قُورن كل سطر بالسكربت الفعلي لا بوصفه |
| 4 | `scripts/build-apk.sh` v2.0 | اكتشاف JDK/SDK/Gradle، توليد Wrapper عند غيابه، تحميل Gradle محلياً بلا `sudo`، **تثبيت SDK داخلياً عند تلف `android-sdk-setup.sh`**، كتابة `local.properties`، نسخ المخرج إلى `dist/` مع SHA-256 وملخص `latest-*.env`، تشخيص فشل البناء من السجل، `--dry-run/--offline/--low-memory/--all/--print-env/--yes`، قفل يمنع بناءين متزامنين، متوافق مع bash 3.2 (macOS) | `shellcheck -S warning` نظيف · `bash -n` سليم · تغطية في `mock-smoke.sh` §2 (32 حالة) |
| 5 | `scripts/apk-test.sh` v2.0 | فصل الفحص الثابت عن الحيّ: `validate`/`info` بلا هاتف، و`test` بفحوص حقيقية (تثبيت · تشغيل · `pidof` · بحث `FATAL`/ANR · لقطة · تقرير md/json)، تشخيص `INSTALL_FAILED_*`، `--serial/--reinstall/--grant/--allow-downgrade`، `connect` للـ WiFi، `emulator --create`، `doctor`، `selftest`، رموز خروج 0–5 | تغطية في mock-smoke.sh §3 (41 حالة) + `apk-test.sh selftest` خاصة به |
| 6 | `scripts/tests/mock-smoke.sh` | 89 فحصاً للسكربتَين بأدوات مزيفة في `/tmp` — بلا Android، بلا JDK، بلا إنترنت | `✓ كل الفحوص نجحت (89)`، وثلاث تشغيلات متتالية بنتيجة واحدة |
| 7 | `.gitignore` | استثناء `dist/` و`build-logs/` و`test-reports/` و`screenshots/` و`local.properties` ومفاتيح التوقيع | — |
| 8 | `scripts/ci-logs.sh` (جديد) | قراءة نتائج Actions عبر `api.github.com` فقط: خطوات الـ run، الـ annotations، أحجام الـ artifacts، وحكم «أخضر زيف» + `--gate` كبوابة CI + `--json` | **اختُبر على المستودع الحقيقي**: أظهر `Java heap space` لـ run `42264822833` ووصف run `42267633951` بالزيف (153B) — `--gate` يرجع 1 |
| 9 | `PLAY_STORE_RELEASE.md` (جديد) | مسار النشر: قرار AAB/APK، توليد keystore وقواعد عدم فقدانه، `signingConfig` مقابل `sign-apk.sh`، R8 و`mapping.txt`، `versionCode`، جدول قائمة Play Console، جدولة أخطاء التوقيع، وقائمة تحقق قبل Publish | مبني على `apps/*/build.gradle.kts` (versionCode 1 · minify true · **بلا signingConfig**) و`scripts/sign-apk.sh`؛ لم يوقَّع ملف فعلياً هنا (لا `keytool`/`apksigner`) — موثّق في §9 منه |
| 10 | `build-apk.sh` v2.1 | إضافة قبول `TAMM_GRADLE_BIN=gradle` (اسم أمر، ليس مساراً) لتفادي توليد Wrapper في CI وتسريع التشغيل | shellcheck نظيف + mock-smoke 89/89 |

**الكوميتات:** `b0cea60` (السكربتات + `BUILD_GUIDE.md`) + كوميت التوثيق الحالي على `arena/68a3e358-tammtool`.

### ما لم أتحقق منه (بصراحة)

- **لم يُنفَّذ بناء APK حقيقي هنا:** بيئة العمل بلا `java` ولا `gradle` ولا Android SDK (والشبكة
  مقيّدة بنطاقات محددة). لذا مسار `build-apk.sh` مُتحقَّق منه **منطقياً** بمحاكاة
  `gradlew`/`adb`/`aapt2`، لا بأداة Gradle فعلية. أول بناء على جهاز فيه JDK 17 سيبقى الاختبار الحقيقي.
- `emulator --create` يعتمد على `sdkmanager`/`avdmanager` الحقيقيَّين؛ لم يُجرَّب (تنزيل ~1.5GB).
- أرقام توافق Compose/Kotlin في §5 من `TROUBLESHOOTING.md` من جداول التوافق المعروفة؛
  تحققتُ منها جزئياً من فروع الفريق: `ff5110e8` يستخدم Kotlin 1.9.22 + Compose 1.5.8 + AGP 8.6.1
  مع Gradle 8.7 في workflow ✓، و`6b69a15d` يستخدم 1.9.20 + 1.5.4 + AGP 8.2.0 مع Gradle 8.5 ✓
  (الاقترانان صحيحان — صوّبت ملاحظة سابقة كانت تعتبر الثاني خطأً).

### مطلوب من الوكيل 2 (قبل الدمج)

1. إصلاح `scripts/android-sdk-setup.sh` سطر 83 — السكربت حالياً **لا يعمل إطلاقاً**
   (التفاصيل والرقعة الجاهزة في `TEAM_COLLABORATION.md` §1). بعد الإصلاح سيتوقف
   `build-apk.sh` تلقائياً عن استخدام مساره الداخلي لأن الفحص `bash -n` سيمرّ.
2. جعل `download-gradlew.sh` يحترم نسخة Gradle المطلوبة (يكتب `gradle-8.5` ثابتاً).
3. تحديث `check-env.sh` ليفحص `apps/*/gradlew` بدل `./gradlew` في جذر المستودع.
4. في `sign-apk.sh`: استخدام `--ks-pass env:…` بدل `pass:…` ودعم التشغيل غير التفاعلي.
5. **ملاحظة دمج مهمة:** `build-apk.sh` و`apk-test.sh` عندي استبدالان كاملان (وليس ترقيعاً) مع
   الحفاظ على واجهة الاستخدام القديمة (`build-apk.sh debug marketer`). لا تدمجهما سطراً بسطر:
   خذ النسخة كاملة ثم أضف ما ينقصك فوقها.

### 📦 مسلَّم إلى المنسّق (الوكيل 0) — ماذا أحتاج منه، وما الذي جاهز له

**الرقع الجاهزة للنسخ** في `TEAM_COLLABORATION.md` §0: A (`gradle.properties`) · B (workflow كامل
يُصلح الإخفاء ويضيف Gate) · C (`android-sdk-setup.sh` سطر 83) · وخطة دمج بأوامر `git` حرفية (§0.7).

**ما أحتاجه منك — بالترتيب، وكل بند له أمر تحقق:**

1. **رقعة A الآن** (أصغر تغيير، أكبر أثر): `org.gradle.jvmargs=-Xmx3g …` في `apps/*/gradle.properties`.
   *تحقق:* `./scripts/ci-logs.sh latest --branch arena/<فرعُك>` لا يُظهر `Java heap space`.
2. **رقعة B**: استبدل `.github/workflows/build-apk.yml` بالنسخة في §0.4 (تبني التطبيقين بـ matrix،
   وتفشل لو لم يوجد APK > 1MB). *تحقق:* بعد أول تشغيل، `./scripts/ci-logs.sh <run> --gate; echo $?`
   يجب أن يطبع `0` فقط عند وجود APK حقيقي.
3. **لا commit للسجل من داخل CI**: احذف خطوة `git push` من الworkflow وارفع `build-logs/` كأثر
   (`if: always()`). السجل لا يُحفظ حالياً أصلاً لأن `.gitignore:52` يحتوي `*.log` ⇒ `git add` يفشل
   بصمت — ولهذا تراها «NA» في الفرع.
4. **الأداة**: `./scripts/ci-logs.sh` صارت في الفرع — استخدمها بدل `gh run view --log-failed`
   (المحجوب هنا). `--runs 10` للجدول، `--json` للسكريبتات، `--limit 80` للتعليقات كلها.
5. **قرار الدمج**: `apps/` من `ff5110e8`، `.github/` من `6b69a15d` (أو رقعة B)، و`scripts/` + الوثائق
   من `arena/68a3e358-tammtool`. لا تخلط `apps/` من `6b69a15d` — فيه الأخطاء الأربعة الحتمية (§3).
6. **سؤالي لك:** هل تريد أن أُنشئ PR دمجاً من فرعك إلى `main` كـ diff مراجعة فقط (بدون تطبيق)،
   أم تبقى المراجعات نصاً في هذين الملفين؟ أجاهز لتجهيزه متى قلت «نعم».

**الحالة: ✅ منجَز — بانتظار الدمج.** طلباتك في `AGENTS_STATUS.md` (فرع `6b69a15d`، `e05f5bc`)
مؤدّاة كلها، والردّ التفصيلي تحت كل سؤال في `TEAM_COLLABORATION.md` §0.9، ومنشور جديد:
[`PLAY_STORE_RELEASE.md`](PLAY_STORE_RELEASE.md) (keystore · AAB · R8/mapping · قائمة Play · قوائم تحقق).

---

## الوكيل 1 — مراجعة الكود المصدرية

_(لم يُحدَّث بعد — الهيكل جاهز للتعبئة)_

```
آخر تحديث: —
الحالة: —
ملفات تمت مراجعتها: —
أخطاء صُحِّحت: —
أخطاء باقية: —
مطلوب من وكلاء آخرين: —
```

**ملاحظة من الوكيل 3 إليك:** كل ما كان مطلوباً في `TEAM_COLLABORATION.md` §3 مُطبَّق في فرعك
`ff5110e8` ما عدا نقطتين: (1) `gradle.properties` بلا `org.gradle.jvmargs` — وهو سبب فشل CI
(الرقعة في §0.3)، و(2) CI عندك يثبّت `build-tools;34.0.0` مع `compileSdk = 35`. تصحيح صغير
لملاحظة سابقة كنتُ أعدّ فيها Compose 1.5.4 + Kotlin 1.9.20 خطأً — الاقتران صحيح، فلا تُغيّره.

---

## الوكيل 2 — الأدوات والسكريبتات

```
آخر تحديث: —
الحالة: —
السكربتات المحدَّثة: —
ما تم اختباره: —
مفتوح معروف: android-sdk-setup.sh (سطر 83) — تحايل عليه build-apk.sh v2 بتثبيت SDK داخلي
```

---

## الوكيل 0 — المنسّق

```
آخر تحديث: —
الحالة: —
قرارات الدمج: —
حالة CI: «أخضر زائف» — لا APK رغم success (runs 42267633951 / 42266809044)؛ الجذر الأصلي Java heap space (run 42264822833)
APK نهائي: لا شيء — كل artifacts آخر تشغيلات إما placeholder (153B) أو لا وجود
حالة التواصل: كل التقارير عبر AGENTS_STATUS.md + TEAM_COLLABORATION.md (§0 مُعدّ لك)
```

---

## سجل الإجراءات المشترك

| التاريخ | الوكيل | إجراء |
|---|---|---|
| 2026-11-06 | 3 | جرد فروع الفريق: كل تطبيق مشروع Gradle مستقل داخل `apps/<app>`، لا Wrapper مرفوع، CI يستخدم Gradle 8.7 + JDK 17 + `platforms;android-35` + `build-tools;34.0.0` |
| 2026-11-06 | 3 | استخراج سبب فشل CI من GitHub Check annotations (بديل يعمل حين يُحجب `--log-failed`) |
| 2026-11-06 | 3 | إعادة كتابة `build-apk.sh` و`apk-test.sh` (v2.0) + `tests/mock-smoke.sh` (89 فحصاً) + `.gitignore` |
| 2026-11-06 | 3 | توثيق: `BUILD_GUIDE.md` · `TROUBLESHOOTING.md` · `scripts/README.md` · `AGENTS_STATUS.md` · `TEAM_COLLABORATION.md` |
| 2026-11-06 | 3 | دفعة إلى `origin/arena/68a3e358-tammtool` (الكوميتان `b0cea60` ثم `fe81f1c`) |
| 2026-11-06 | 3 | قراءة CI بـ `gh api` فقط: تبيّن أن نجاحات اليوم **زائفة** (153B placeholder، لا artifact، `BUILD_EXIT` غير مفحوص، `*.log` مُتجاهَل) |
| 2026-11-06 | 3 | إضافة `scripts/ci-logs.sh` (تقرير run/annotations/artifacts/gate) + `build-apk.sh` v2.1 (`TAMM_GRADLE_BIN=gradle`) |
| 2026-11-06 | 3 | تسليم §0 في `TEAM_COLLABORATION.md` إلى الوكيل 0: رقعتان جاهزتان + خطة دمج + معيار «APK حقيقي» |
| 2026-11-06 | 3 | تصحيح ملاحظة §3: Compose Compiler 1.5.4 مع Kotlin 1.9.20 اقتران **صحيح** (كانت مُدرجة خطأً كعيب) |

## ما يبقى قبل «APK نهائي» — ترتيب مقترح

| # | المهمة | المالك | علامة الانتهاء |
|---|---|---|---|
| 1 | رقعة A: `org.gradle.jvmargs` في `apps/*/gradle.properties` | 0 (أو 1) | لا `Java heap space` في `./scripts/ci-logs.sh <run>` |
| 2 | رقعة B: workflow بلا `set +e`، بلا placeholder، مع Gate وannotations | 0 | `./scripts/ci-logs.sh <run> --gate; echo $?` → `0` فقط مع APK > 1MB |
| 3 | دمج `apps/` من `ff5110e8` + `scripts/` والوثائق من `68a3e358` | 0 | `bash scripts/tests/mock-smoke.sh` = 89/89 + PR أخضر حقيقي |
| 4 | إصلاح `android-sdk-setup.sh` سطر 83 و`download-gradlew.sh`/`check-env.sh` | 2 | `bash -n` نظيف على كل `scripts/*.sh` |
| 5 | توحيد build-tools (CI `34.0.0` مقابل `compileSdk 35`) ونسخة Gradle 8.7 | 0 + 1 | سطر واحد في مكان واحد مذكور في `BUILD_GUIDE.md` §5 |
| 6 | تنزيل APK من CI وفحصه بلا جهاز | 3 | `./scripts/apk-test.sh validate <apk>` = rc 0 |
| 7 | اختبار حيّ على هاتف/محاكي (تثبيت/تشغيل/انهيار/لقطة) | 1 + 3 | `./scripts/apk-test.sh test --app marketer` = rc 0 مع تقرير في `test-reports/` |
| 8 | توقيع الإنتاج: `bundle` + keystore خارج المستودع | 0 | keystore غير مرفوع + `apkanalyzer`/`apksigner verify` ✓ |

**لا يوجد أي عائق يمنع بدء 1 و2 اليوم** — لا يحتاجان JDK ولا جهاز، وكل ما فيهما نصّ جاهز في §0.
