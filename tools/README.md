# أدوات بناء وتجربة «تطبيق الفلتر» — دليل الاستخدام

> مجلد `tools/` :: من الوكيل 3 (2026‑11‑06) — طلب المستخدم: «أضف أدوات بناء وكل الإضافات والبرامج
> مفتوحة المصدر التي يستطيع الوكيل استخدامها في المستودع لبناء وتجربة تطبيق فلتر».
> القائمة الكاملة المُقفلة بالإصدارات في [`tools.lock`](tools.lock) · قرارات الاختيار في
> [`../FILTER_APP_TOOLCHAIN.md`](../FILTER_APP_TOOLCHAIN.md).

## 0. الخريطة

| الملف | ما هو | متى تستخدمه |
|---|---|---|
| `tools.lock` | **مصدر الحقيقة الوحيد** للإصدارات/التراخيص/الأغراض (أدوات + اعتماديات + خطوات CI + ملاحظات سياسة) | قبل أن تُثبّت نسخة يدوياً |
| `install-toolchain.sh` | يقرأ القفل: `--list` · `--check` · `--install` · `--emit-deps` · `--emit-ci` · `--emit-env` · `--verify` | تجهيز جهاز/CI أو توليد كتلة `dependencies {}` |
| `install-gradle-wrapper.sh` | يزرع `gradlew` + `gradle-wrapper.jar` **من `tools/vendor/`** (بلا خدمات Gradle) لكل مشروع | أينما قال CI «لا wrapper» (الفجوة A3) |
| `scaffold-filter-app.sh` | يولّد `apps/filter/` من `filter-app-template/` (+ اختيارياً wrapper + فحص) | من الصفر إلى مشروع فلتر قابل للبناء |
| `verify-filter-app.sh` | **14 فحصاً بنيوياً بلا Gradle ولا SDK** مع `--gate` | بعد كل تعديل على تطبيق الفلتر، وقبل طلب CI |
| `filter-app-template/` | القالب نفسه (38 ملفاً): Kotlin + AGSL + مانيفيست + اختبارات | اقرأه/عدّله، ثم أعد التوليد أو انسخ فوق الهدف |
| `vendor/gradle-wrapper/8.7.0/` | wrapper رسمي من وسم `gradle/gradle@v8.7.0` (jar 43٬453 بايت، بmanifest) | المرجع الذي ينسخه `install-gradle-wrapper.sh` |
| `tests/toolchain-smoke.sh` | **43 فحصاً** للسكربتات أعلاه (تشمل فحوصاً سلبية) — يُشغَّل آلياً من `scripts/tests/mock-smoke.sh` | `bash tools/tests/toolchain-smoke.sh` |

## 1. خمس دقائق من الاستنساخ إلى أول محاولة بناء

```bash
cd TAMMTOOL
./tools/scaffold-filter-app.sh --wrapper --verify --force-apps-ci   # → apps/filter + فحص 14/14 ✓
./tools/install-toolchain.sh --check                                # ما المتوفر وما الناقص
TAMM_GRADLE_BIN=gradle ./scripts/build-apk.sh debug filter --yes    # البناء (wrapper غير لازم)
./scripts/build-apk.sh unit-test filter --yes                       # 16 فحص @Test على JVM
./scripts/apk-test.sh validate --app filter                         # فحص APK بلا محاكي
```

بلا `TAMM_GRADLE_BIN` سيشغَّل `./gradlew` — وهذا ممكن الآن لأن `--wrapper` زرعه من `tools/vendor/`
(الملفات تُنزَّل عند أول تشغيل من `services.gradle.org`؛ إن كانت محجوبة فاستمر بـ `TAMM_GRADLE_BIN`).

## 2. `tools.lock` — كيف تُضيف بنداً ولا تكسر شيئاً

```ini
[tool:my-tool]
kind = tool            # tool | gradle-dep | ci-action | note
repo = owner/name      # للـ tools
tag = v1.2.3           # وسم موجود فعلاً في المستودع (لا «latest» إلا لو كان مقصوداً)
asset = my-tool-{ver}.{os}.{arch2}.tar.gz
extract = tar          # tar | zip | jar | copy
bin = bin/my-tool
license = Apache-2.0
verified = github-api@YYYY-MM-DD   # أو repo-fact / needs-online — الصيغة إلزامية
purpose = سطر واحد: ما الذي يفتحه/يغلقه هذا البند
group = quality        # مجموعات --emit-deps: camera,compose,tests,quality,images,debug,device,build
```

فرضيات يفحصها `toolchain-smoke.sh` (ولن ينجح CI إن خالفتها): ≥25 بنداً، كل بند فيه `kind`/`purpose`/
`verified`/`license`، كل `gradle-dep` إحداثياته `group:artifact:version`، وكل `tool` له `repo`،
و`verified` إحدى القيم الثلاث المذكورة. **إن لم تتحقق من شيء من الشبكة فاكتب `needs-online` ولا تكذب
على القارئ** — هذه القاعدة هي ما يمنع «التوثيق يطمئن والبناء يكذب».

## 3. `--emit-deps`: الاعتماديات من القفل، لا من الذاكرة

```bash
./tools/install-toolchain.sh --emit-deps camera,compose          # كتلة جاهزة للّصق
./tools/install-toolchain.sh --emit-deps all                     # كل gradle-dep
```
يُعلّم سطراً بـ `⚠ تحقق من النشر قبل الاعتماد` لكل بند `verified = needs-online` — أي أن القالب
والسكربت لا يُخفيان عدم التحقق. `--emit-ci` يعطيك خطوات Actions المقفلة لنفس السبب.

## 4. الـ wrapper المخبوء في المستودع (لماذا jar هنا؟)

`apps/*/gradle/wrapper/gradle-wrapper.jar` **غير مرفوع** في المستودع (A3) و`services.gradle.org` محجوب
في بيئة التوثيق — فكان الحل: جلب الملفات من **وسم Gradle الرسمي عبر `api.github.com`** وحفظها في
`tools/vendor/gradle-wrapper/8.7.0/` مع `manifest.json` (sha256 لكل ملف). `--verify` يعيد حساب البصم،
وسكربت الاختبار يتأكد أن الـ jar ملف ZIP صحيح. هذا «مصدر موثوق واحد» بدل أن يولّد كل وكيل نسخته.

```bash
./tools/install-gradle-wrapper.sh --verify            # ✓ البصمات مطابقة
./tools/install-gradle-wrapper.sh --apps              # زرع في apps/* المكتشفة
./tools/install-gradle-wrapper.sh --fetch 8.14.6      # نسخة أخرى من GitHub API (تحتاج gh + شبكة)
```

## 5. `verify-filter-app.sh`: ما يفحصه ولماذا كل فحص موجود

| # | الفحص | العطل الذي يمنعه (كله من حوادث حقيقية في هذا المستودع) |
|---|---|---|
| 01 | الملفات الإلزامية (بلا افتراض اسم الحزمة) | قالب مقطوع النص يبنى نصف بناء |
| 02 | توازن `{}`/`()` في `.kt` و`.kts` | قص/لصق يترك قوساً — كان سيظهر كرسالة Kotlin غامضة |
| 03 | كل XML يُحلَّل | مانيفست مكسور = `AAPT2` برسالة بلا سطر |
| 04 | كل فلتر في `FilterRegistry` له ملف شيدر، ولا ملف يتيماً | **أخطر نوع**: يترجم ويعمل، ثم يسقط عند الضغط على الفلتر |
| 05 | AGSL: `main` موجود، `content` معلن، الدوال قبل `main` | GLSL لا يقبل استعمالاً قبل تعريفه؛ المترجم على الجهاز يرفض بعد فوات الأوان |
| 06 | `RuntimeShader`/`RenderEffect` داخل شرط `SDK_INT`/`@RequiresApi` | `NoClassDefFoundError` على API 24–32، لا يظهر في البناء |
| 07 | كل `R.string.*` معرَّف، وكل نص له قيمة عربية | `Resources$NotFoundException` + RTL ناقص |
| 08 | كل `*Implementation` داخل `dependencies { }` | **خطأي في الجولة الأولى**: توابع بعد القوس ⇒ فشل DSL بلا سبب مفهوم |
| 09 | `org.gradle.jvmargs` مضبوط | `D8: Java heap space` (CI 42273932002) |
| 10 | المانيفست: CAMERA نعم، تخزين خارجي لا، لا قفل اتجاه، `allowBackup` آمن | سياسات Play (C3/C5/C6) |
| 11 | ≥3 ملفات اختبار و≥12 `@Test` و`testInstrumentationRunner` | «صفر اختبارات» (C7) |
| 12 | المصفوفة: minSdk 24 / target 35 / AGP 8.6.1 / Kotlin 1.9.22 / Compose 1.5.8 | خلط أزواج Kotlin↔Compose عند الدمج |
| 13 | لا `google-services` بلا JSON، لا `dataBinding` بلا layout، تنبيه kapt العديم | مهمات تفشل على خطأ classpath (CI 42273932002) |
| 14 | كل المسارات ASCII | أدوات SDK/CI تنكسر على أسماء غريبة (وحدث فعلاً مع ملفات عربية في git) |

الفحوص 04–08 و13 كُتبت **بعد** أن كشفها تشغيل السكربت نفسه على قالب به خلل (مسار مغلوط للاختبارات
وحساب اعتماديات خاطئ) — أي أنها ليست نظرية.

## 6. رموز الخروج (للربط في CI أو git hook)

| سكربت | 0 | 1 | 2 |
|---|---|---|---|
| `verify-filter-app.sh` | كل الفحوص ✓ | يوجد ✗ | لا مشروع/وسيط رديء |
| `install-gradle-wrapper.sh` | تمّ | خطأ استخدام/تحقق بصمة | شبكة/`gh` غير متاح |
| `install-toolchain.sh` | تمّ | فشل بند | `gh` غير مثبت (يطبع الأمر اليدوي) |
| `scaffold-filter-app.sh` | تُوليد + فحص ✓ | فشل `--verify` | هدف موجود بلا `--replace` |

مثال ربط محلي (قبل الدفعة): `./tools/verify-filter-app.sh --gate || exit 1`.
