# حالة فريق العمل — TAMMTOOL

> **كيف يُحدَّث هذا الملف؟** كل وكيل يكتب **فقط** داخل قسمه، ويضيف سطر «آخر تحديث» بالتاريخ.
> لا تعدّل أقسام غيرك؛ الرسائل العَرَضية لوكيل آخر توضع في [`TEAM_COLLABORATION.md`](TEAM_COLLABORATION.md).
> الهدف: ملف واحد يعرف فيه المنسّق ما تمّ، ما تعطّل، وما الذي سيُدْمَج.

**آخر تحديث للملف كله:** 2026-11-06 — الوكيل 3

---

## لوحة الحالة

| الوكيل | النطاق | الحالة | الفرع | الدليل / المخرجات |
|---|---|---|---|---|
| **0 — المنسّق** | إصلاح CI، قراءة السجلات، الدمج، APK نهائي | 🟡 مستمر | — | آخر build فاشل: run `42264822833` (`Java heap space`) · run `42264967594` (خطوة حفظ السجل تخفي الفشل) |
| **1 — مراجعة الكود** | Kotlin/Gradle للتطبيقين | 🟡 لم يحدّث قسمه بعد | `arena/ff5110e8-tammtool` | آخر كوميت: «Review both Android apps and fix Kotlin, Hilt build and Room source c…» |
| **2 — الأدوات والسكريبتات** | `scripts/*.sh` | 🟡 تداخل مع الوكيل 3 | `arena/6b69a15d-tammtool` | 6 سكربتات موجودة؛ **`android-sdk-setup.sh` مكسور الصياغة (سطر 83)** |
| **3 — التوثيق والتقارير** | وثائق + سكربتات البناء/الاختبار | 🟢 **منجَز** | `arena/68a3e358-tammtool` | `BUILD_GUIDE.md` · `TROUBLESHOOTING.md` · `scripts/README.md` · سكربتات v2 + `tests/mock-smoke.sh` (89/89 ✓) |

**الحالة الإجمالية للمشروع:** 🔴 لا يوجد APK ناجح بعد — السبب الرئيسي موثّق ومحدّد (ذاكرة Gradle) وحلّه سطرَا إعداد.

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

**الكوميتات:** `b0cea60` (السكربتات + `BUILD_GUIDE.md`) + كوميت التوثيق الحالي على `arena/68a3e358-tammtool`.

### ما لم أتحقق منه (بصراحة)

- **لم يُنفَّذ بناء APK حقيقي هنا:** بيئة العمل بلا `java` ولا `gradle` ولا Android SDK (والشبكة
  مقيّدة بنطاقات محددة). لذا مسار `build-apk.sh` مُتحقَّق منه **منطقياً** بمحاكاة
  `gradlew`/`adb`/`aapt2`، لا بأداة Gradle فعلية. أول بناء على جهاز فيه JDK 17 سيبقى الاختبار الحقيقي.
- `emulator --create` يعتمد على `sdkmanager`/`avdmanager` الحقيقيَّين؛ لم يُجرَّب (تنزيل ~1.5GB).
- أرقام توافق Compose/Kotlin في §5 من `TROUBLESHOOTING.md` من جداول التوافق المعروفة —
  يؤكد الوكيل 1 المطابقة النهائية بعد تعديلاته.

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

### مطلوب من المنسّق (الوكيل 0)

- **تغيير واحد يفتح CI:** إضافة `org.gradle.jvmargs=-Xmx3g …` إلى `apps/*/gradle.properties`
  (النسخة الجاهزة في `TROUBLESHOOTING.md` §1.1). السبب مؤكد من تعليقات GitHub (run 42264822833).
- **خطوة السجل في workflow فرع `6b69a15d`:** لا تكتب `../ci-build.log` خارج مجلد العمل؛
  اجعل `if: always()` لرفع الأثر فقط، وأضف `tail -n 300` عند الفشل لتظهر الأسطر في السجل الخام.
- قراءة السجلات حين يفشل `gh run view --log-failed`: الأوامر الجاهزة في `BUILD_GUIDE.md` §6.3.
- **اقتراح:** إضافة `gradlew` و`gradle/wrapper/gradle-wrapper.jar` إلى git مع
  `distributionUrl=…gradle-8.7-bin.zip` ليطابق `setup-gradle@v4`، فيصبح البناء المحلي = CI.

**الحالة: ✅ منجَز — بانتظار الدمج.**

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

**ما يفيدك من فحصي لفروع الفريق** (تفصيله في `TEAM_COLLABORATION.md`): فرع
`arena/6b69a15d-tammtool` فيه 5 مشاكل بناء حتمية — `kapt(…)` بدون تطبيق بلَجن kapt،
`sourceCompatibility=1.8` مع `jvmTarget=17`، Compose Compiler 1.5.4 مع Kotlin 1.9.20،
`allprojects { repositories }` مع `FAIL_ON_PROJECT_REPOS`، وملف `ic_launcher_web.png.placeholder`
غير XML داخل `res/values`. كل واحدة منها تُسقط البناء قبل أي خطأ Kotlin منطقي.

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
حالة CI: فشل بـ Java heap space (run 42264822833) + خطوة «Save build log» تخفي الفشل (run 42264967594)
APK نهائي: —
```

---

## سجل الإجراءات المشترك

| التاريخ | الوكيل | إجراء |
|---|---|---|
| 2026-11-06 | 3 | جرد فروع الفريق: كل تطبيق مشروع Gradle مستقل داخل `apps/<app>`، لا Wrapper مرفوع، CI يستخدم Gradle 8.7 + JDK 17 + `platforms;android-35` + `build-tools;34.0.0` |
| 2026-11-06 | 3 | استخراج سبب فشل CI من GitHub Check annotations (بديل يعمل حين يُحجب `--log-failed`) |
| 2026-11-06 | 3 | إعادة كتابة `build-apk.sh` و`apk-test.sh` (v2.0) + `tests/mock-smoke.sh` (89 فحصاً) + `.gitignore` |
| 2026-11-06 | 3 | توثيق: `BUILD_GUIDE.md` · `TROUBLESHOOTING.md` · `scripts/README.md` · `AGENTS_STATUS.md` · `TEAM_COLLABORATION.md` |

## ما يبقى قبل «APK نهائي»

1. إصلاح `gradle.properties` (الذاكرة) — **الأولوية القصوى** (الوكيل 0).
2. إصلاح مشاكل فرع agent-1 الخمس (الوكيل 1).
3. إصلاح `android-sdk-setup.sh` و`download-gradlew.sh` (الوكيل 2).
4. توحيد نسخة build-tools بين CI (`34.0.0`) والسكربت (`35.0.0`).
5. نجاح بناء `debug` في CI ← تنزيل الـ APK ← `./scripts/apk-test.sh validate` عليه محلياً.
6. اختبار حيّ على هاتف/محاكي: `./scripts/apk-test.sh test --app marketer`.
7. قرار التوقيع للإنتاج: `bundle` + keystore خارج CI (لا ترفع مفتاحاً إلى المستودع).
