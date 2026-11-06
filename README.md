# TAMMTOOL

منصة طلبات وتوصيل + تطبيق مسوق، عبارة عن مستودع واحد (monorepo) فيه تطبيقا Android مستقلان.

## التطبيقات

| المسار | التطبيق | معرّف الحزمة |
|---|---|---|
| `apps/marketer` | طلبات الأفغاني (تطبيق المسوّق) | `com.tammtool.marketerapp` |
| `apps/orders-delivery` | إدارة الطلبات والتوصيل (التطبيق الرئيسي) | `com.tammtool.ordersapp` |

كل مجلد تطبيق **مشروع Gradle مستقل** (`settings.gradle.kts` في جذره)، ولا يوجد مشروع جذر واحد —
لذلك تُنفَّذ أوامر البناء من داخل `apps/<app>`، وهو ما يقوم به `scripts/build-apk.sh` نيابة عنك.

## البناء السريع (على أي حاسوب عادي)

```bash
git clone https://github.com/22kdx/TAMMTOOL.git && cd TAMMTOOL
./scripts/build-apk.sh debug marketer           # ينتج dist/marketer-debug-v<ver>-<git>.apk
./scripts/apk-test.sh validate --app marketer    # فحص الـ APK — لا يحتاج هاتفاً
./scripts/apk-test.sh test --app marketer        # تثبيت + تشغيل + كشف انهيار على هاتفك/محاكيك
```

الحد الأدنى: JDK 17 + ~10GB مساحة + إنترنت لأول بناء فقط. التفاصيل كاملة في
[`BUILD_GUIDE.md`](BUILD_GUIDE.md)، وعند أي تعطّل ابدأ من
[`TROUBLESHOOTING.md`](TROUBLESHOOTING.md).

## الوثائق

| الملف | لما تستخدمه |
|---|---|
| [`BUILD_GUIDE.md`](BUILD_GUIDE.md) | خطوة بخطوة: تجهيز الجهاز، التثبيت على كل نظام، البناء، التوقيع، الاختبار، CI |
| [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md) | رسالة الخطأ ← السبب ← الحل (بما فيها حالة CI الحالية بالأدلة) |
| [`scripts/README.md`](scripts/README.md) | مرجع أوامر كل سكربتات `scripts/` وخياراتها (منها `ci-logs.sh` لقراءة CI) |
| [`GAP_TO_APK.md`](GAP_TO_APK.md) | **ما الذي ينقص لإنتاج التطبيق؟** — 16 فجوة بالأولوية مع أمر يثبتها وسطر يصلحها · **§7: جدول الحالة بعد التنفيذ (12/16 مُطبَّقة في `arena/68a3e358`)** |
| [`PLAY_STORE_RELEASE.md`](PLAY_STORE_RELEASE.md) | keystore، توقيع AAB/APK، R8/mapping، قائمة Play، وقوائم تحقق النشر |
| [`patches/README.md`](patches/README.md) | رقع `git am` جاهزة (CI الصادق · ذاكرة Gradle · مخطط Room) + سجل التحقق |
| [`AGENTS_STATUS.md`](AGENTS_STATUS.md) | حالة كل وكيل في فريق العمل، وما بقي قبل APK نهائي |
| [`TEAM_COLLABORATION.md`](TEAM_COLLABORATION.md) | ملاحظات متقاطعة على ملفات الوكلاء الآخرين (مع أرقام مراجع قابلة للتحقق) |
| `docs/workflow-*.md` | شرح سير عمل GitHub Actions (البناء، التوقيع، النشر) |

## السكربتات

`scripts/` فيها: `build-apk.sh` (بناء) · `apk-test.sh` (فحص واختبار) · `ci-logs.sh` (قراءة
نتائج CI) · `sign-apk.sh` (توقيع) · `check-env.sh` (فحص البيئة) · `android-sdk-setup.sh`
(تثبيت SDK) · `download-gradlew.sh` (Wrapper) · `tests/mock-smoke.sh` (اختبار السكربتات
نفسها بلا Android). المرجع الكامل: [`scripts/README.md`](scripts/README.md).

```bash
./scripts/tests/mock-smoke.sh      # 89 فحصاً بمحاكاة java/gradle/adb/aapt2 — بلا إنترنت ولا JDK
```

## حالة CI

🔴 **لا يوجد APK من CI بعد — والحالة «الخضراء» مضلِّلة.** منذ 2026-11-06 تُعلن التشغيلات
نجاحها بينما لا تُنتج شيئاً: run `42267633951` = success مع artifact بحجم **153 بايت**
(ملف `no-apk.txt`)، وrun `42266809044` = success بلا أي artifact. والسبب الجذري الأصلي لم
يُصلَّح بعد: **نفاد ذاكرة Gradle (`Java heap space`)** لأن `apps/*/gradle.properties` لا يضبط
`org.gradle.jvmargs`. التشخيص بالأسطر والأرقام في [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md) §1.5،
والرقعتان الجاهزتان وخطة الدمج في [`TEAM_COLLABORATION.md`](TEAM_COLLABORATION.md) §0،
وحالة كل وكيل في [`AGENTS_STATUS.md`](AGENTS_STATUS.md).

```bash
./scripts/ci-logs.sh --runs 8     # ماذا جرى في آخر تشغيلات؟ (عبر API فقط)
./scripts/ci-logs.sh <RUN> --gate # rc=0 فقط إذا وُجد APK حقيقي (>1MB)
```
