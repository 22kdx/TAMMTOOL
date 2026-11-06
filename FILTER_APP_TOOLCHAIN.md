# سلسلة أدوات «تطبيق الفلتر» — ما اختير، ولماذا، وما لم يُتحقق

> وثيقة قرار + كتالوج. 2026‑11‑06 · الوكيل 3. الأرقام والترخيص لكل بند في
> [`tools/tools.lock`](tools/tools.lock)؛ الاستخدام العملي في [`tools/README.md`](tools/README.md).

## 1. ما المطلوب بالضبط

طلب المستخدم: أدوات بناء وتشغيل واختبار، وكل ما هو مفتوح المصدر ويستطيع الوكيل استخدامه **في
المستودع** لبناء «تطبيق فلتر» وتجربته. لذلك النتيجة ثلاث طبقات، لا واحدة:

1. **قفل إصدارات** (`tools/tools.lock`) — لا «آخر نسخة» الغدِرة، ولا أرقام في رؤوس الوكلاء.
2. **أدوات تعمل بلا شبكة وبلا SDK** — لأن هذه البيئة محرومة منها، ولأن أول 15 دقيقة في CI هي
   التي تكشف الكذب: `install-gradle-wrapper.sh`، `verify-filter-app.sh`، `toolchain-smoke.sh`.
3. **قالب تطبيق فلتر حقيقي** (`tools/filter-app-template/` → `apps/filter/`) — بلا شيء «يُبنى
   ويُجرَّب» لا معنى للأدوات.

## 2. قرار البنية: AGSL من المنصة، لا مكتبة فلاتر خارجية

| الخيار | الترخيص | الحجم على الجهاز | native؟ | النتيجة |
|---|---|---|---|---|
| **`android.graphics.RuntimeShader` (AGSL)، API 33+** | جزء من Android | **0 بايت** | لا | ✅ **المسار الأساسي** — الفلاتر السبعة كلها AGSL في `app/src/main/assets/shaders/` |
| `wasabeef/android-gpuimage` (9153★) | غير محسوم (upstream BSD) | ~1–2 MB `.so` | نعم (NDK) | ❌ متوقف منذ 2022 + NDK + ترخيص يحتاج مراجعة قانونية |
| `wysaid/android-gpuimage-plus` (MIT، نشط) | MIT | ~3 MB | نعم | ⏸ بديل إن طُلبت فلاترFace/Beautification؛ ليس في القالب |
| OpenCV (`opencv/opencv`, Apache‑2.0, 91k★) | Apache‑2.0 | 10 MB+ AAR | نعم | ❌ للقالب: الميزان ليس «معرّف حافة» بل «فلاتر ألوان» |
| `wuhaoyu1990/MagicCamera` (5514★) | **لا ترخيص** | — | نعم | ⚠ قراءة تعليمية فقط؛ بلا ترخيص = لا يُدمج |
| `arthenica/ffmpeg-kit` (LGPL‑3.0) | LGPL‑3.0 | 15 MB+ | نعم | ❌ **archived** (آخر دفعة 2026‑07) ⇒ لا يُبنى عليه مشروع جديد؛ للفلاتر على فيديو: `androidx.media3:media3-transformer` (Apache‑2.0) |
| ML Kit Selfie Segmentation | **غير مفتوح** (Play Services) | تنزيل ديناميكي | — | ⏸ إن طُلب «عزل الخلفية»: ميزة اختيارية لا مسار أساسي (لا يعمل بلا Play Services) |

**الذي لم يُنفَّذ في القالب، بوضوح:** مسار GLES 3.0 للأجهزة API 24–32. `FilterCapability` يقرّر
`RenderPath.GLES` و`RenderEffectFactory` يُرجع `null` هناك ⇒ على جهاز قديم تظهر الصورة بلا فلتر
**لا انهيار** (وهذا مُختبَر بوحدة: `FilterCapabilityTest`). إضافته = حلقة `GL_SURFACE` + `GLES30`
في `render/`، وهي عمل يوم للوكيل 1 إن قرّرنا أن minSdk 24 يعني فعلياً دعم الأجهزة القديمة.

## 3. أدوات البناء والاختيار المقفل

| الأداة | النسخة | الترخيص | الدور في حلقة الوكيل |
|---|---|---|---|
| Gradle wrapper (مُخزَّن) | 8.7.0 (`gradle/gradle@v8.7.0`) | Apache‑2.0 | يغلق A3 بلا `services.gradle.org` |
| Temurin JDK | `latest` (17.0.21+9 وقت الكتابة) | GPL‑2.0 + Classpath Exception | AGP 8.x يتطلب 17 — `check-env.sh` صار يفحصه رقمياً |
| `pinterest/ktlint` | 1.8.0 | MIT | `ktlint --format "apps/filter/**/*.kt"` |
| `detekt/detekt` | v1.23.8 | Apache‑2.0 | قواعد تعقيد/روائح بلا إعداد |
| `koalaman/shellcheck` | v0.11.0 | **GPL‑3.0** | فحص `tools/*.sh` و`scripts/*.sh` (كان غائباً عن بيئتنا، فاستعضنا عنه بـ `bash -n`) |
| `iBotPeaches/Apktool` | v3.0.3 | Apache‑2.0 | فكّ APK للتأكد من المانيفست/الحزمة بعد البناء |
| `skylot/jadx` | v1.5.6 | Apache‑2.0 | قراءة الكود المُصغَّر للتحقق أن R8 لم يمسح ما يجب بقاؤه |
| `Genymobile/scrcpy` | v5.0.1 | Apache‑2.0 | عكس شاشة الهاتف + تسجيل `--record` لتوثيق «جرّبته فعلاً» |
| `ReactiveCircus/android-emulator-runner` | v2 | Apache‑2.0 | إن أردنا `androidTest` في CI (وظيفة منفصلة عن البناء) |

الترخيص لا يُشكّل التزاماً على تطبيقك إلا للارتباط (linking): أدوات سطر أوامر تُستدعى process‑level
فـ GPL‑3.0 (shellcheck) لا يسري على شيفرتك؛ وللمقارنة، لو استُخدم `ffmpeg-kit` (LGPL) **داخل** التطبيق
لزم إفصاح/ربط ديناميكي — سبب آخر لاستبعاده.

## 4. اختبار «تجربة التطبيق» بلا محاكي

| الطبقة | الأداة | ما يغطيه | حالته في القالب |
|---|---|---|---|
| منطق نقي | JUnit 4 على JVM | السجل، القصّ إلى النطاق، حراسة API، المسارات | ✅ 3 ملفات / 16 `@Test`، وتُدار بـ `./scripts/build-apk.sh unit-test filter` |
| بنية المشروع | `verify-filter-app.sh` | 14 فحصاً متقاطعاً (كود ↔ أصول ↔ Gradle ↔ مانيفست) | ✅ يعمل بلا أي أداة Android |
| سكربتات المستودع | `tools/tests/toolchain-smoke.sh` | 43 فحصاً (إيجابية **وسلبية**: نتأكد أن الفحوص تسقط عند العطل) | ✅ مُوصَّل بـ `mock-smoke.sh` ⇒ يَجري في CI كخطوة `Self-test` |
| لقطات الشاشة | Roborazzi أو Paparazzi | تغيّر شكل الفلتر، بصرياً، على JVM | ⏸ في القفل بـ `needs-online`؛ اختر **واحداً** وأضِف `group = tests` إلى `tools.lock` ثم `--emit-deps tests` |
| تسريب الذاكرة | `leakcanary-android` 2.14 | Bitmaps/Surfaces في تطبيق كاميرا | ⏸ `debugImplementation` عند أول اختبار حيّ |
| جهاز حقيقي | `scripts/apk-test.sh test` + `scrcpy` | تثبيت/تشغيل/انهيار/تسجيل | ✅ موجود، يملكه الوكيل 2 |

**لماذا لم أُضِف Roborazzi/Paparazzi إلى `app/build.gradle.kts` الآن؟** لأنّ التحقق من نشر الإحداثية
يحتاج `maven.google.com`/Maven Central، وكلاهما محجوب هنا؛ وإضافتها بلا تحقق هي بالضبط الطريقة التي
فشل بها CI في `42273932002` على إحداثية Compose غير موجودة. البند مُعلَّم `needs-online` ليُرفَع إلى
`verified` بعد فحص من شبكة فيها الإنترنت — لا لأُريح الضمير التوثيقي.

## 5. ما على كل وكيل (بلا تجاوز ملكيات)

* **الوكيل 0**: إضافة `filter` إلى `strategy.matrix.app` (سطر واحد) — أو تشغيل `build-apk.sh` محلياً.
  هو صاحب `.github/`، فلم ألمسه. بعد الدمج: `./tools/install-gradle-wrapper.sh --apps` تزرع wrapper
  لكل المشاريع الأربعة (مُجرَّب بـ dry‑run هنا).
* **الوكيل 1**: `apps/filter/` ملكك من هنا؛ القالب يُولَّد ولا يُفترض أنه القرار النهائي. ابدأ من
  `RenderEffectFactory` (مكان مسار GLES) ومن `ShaderSourceRepository`.
* **الوكيل 2**: إن أردت نقل `install-gradle-wrapper.sh` إلى `scripts/` أو توحيده مع
  `download-gradlew.sh` فذلك أفضلية — كلاهما يخدم A3، ولا أريد نسختين متباعدتين للأبد.
* **أنا**: القفل + الفحوص + التوثيق. لن أضيف اعتماديات غير موثَّقة ولا أعدّل CI.

## 6. ما لم أتحقق منه (بلا تجميل)

1. **لم تُبنَ أي شيفرة هنا**: لا JDK ولا Android SDK. كل «✓» في هذه الوثيقة يعني *فحصاً بنيوياً/تحليلاً
   آلياً*، لا ترجمة Kotlin ولا تشغيل AGSL على GPU.
2. صيغة AGSL كُتبت وفق وثائق `RuntimeShader` ( uniforms: `shader`/`float`/`float2`، دالة `main(float2)`)،
   **ولم تُجمَّع على جهاز**؛ احتمال خطأ نحوي في شيدر واحد وارد، وعلامته ستكون `Failed to compile shader`
   وقت التشغيل، لا في البناء.
3. **إحداثيات Maven** لـ CameraX/Roborazzi/LeakCanary/Robolectric مقترنة بـ `needs-online` —
   `tools/install-toolchain.sh --emit-deps` يكرّر التحذير في السطر نفسه.
4. `apps/filter/` المولَّد في هذا الفرع **لم يُختبَر في CI بعد** (ولن أشغّله: القرار لك).
5. القالب لا يشمل: التقاطاً فعلياً بـ `ImageCapture`، حفظاً في MediaStore، معرض صور، ولا مشاركة —
   هذه مهام للوكيل 1؛ البنية (assets ↔ registry ↔ ViewModel ↔ screens) جاهزة لها.

— الوكيل 3 · 2026‑11‑06 · `arena/68a3e358-tammtool`
