## الوكيل 2 — الأدوات والسكريبتات

الحالة: اكتمل تنفيذ السكريبتات واختبار منطقها دون اتصال؛ البناء الحقيقي محجوب بغياب المصادر والأدوات.

### الملفات
- `scripts/build-apk.sh`: بناء `all|marketer|orders-delivery` بنوعي `debug|release`، تفضيل Gradle wrapper، إيقاف التنفيذ عند فشل Gradle أو غياب APK، عرض معلومات الناتج.
- release: يتطلب `APK_KEYSTORE`, `APK_KEY_ALIAS`, `APK_STORE_PASSWORD`, `APK_KEY_PASSWORD`؛ يستخدم zipalign وapksigner ويتحقق من التوقيع. كلمات المرور تمر عبر متغيرات البيئة لا معاملات سطر الأوامر. المخرجات `*-signed.apk` بجوار APK الأصلي. هذا توقيع لاحق للبناء، وليس إعداد signingConfig داخل Gradle.
- `scripts/apk-test.sh`: الأمر `info APK` يعرض الحجم واسم الحزمة والإصدار بواسطة aapt إن توفر؛ الأمر `install APK [DEVICE_SERIAL]` يثبت عبر ADB ويدعم ANDROID_SERIAL ويرفض الأجهزة غير المعتمدة وغياب الأجهزة وتعددها دون اختيار صريح.
- `scripts/check-env.sh`: فحص Java وGradle wrapper/Gradle وSDK وADB وإرجاع حالة فشل واضحة. غياب ADB يفشل فحص البيئة الكامل لكنه لا يمنع سكريبت البناء وحده.
- `scripts/android-sdk-setup.sh`: إعداد SDK على Linux، تنزيل أدوات CLI بإصدار محدد، تثبيت platform-tools وplatform وbuild-tools، قبول الرخص صراحة عبر ANDROID_ACCEPT_LICENSES=1، إعداد GITHUB_ENV/GITHUB_PATH. يمكن تحديد ANDROID_API_LEVEL وANDROID_BUILD_TOOLS_VERSION وANDROID_CMDLINE_TOOLS_REVISION وANDROID_CMDLINE_TOOLS_SHA256. يتطلب الوصول إلى dl.google.com ومستودعات SDK؛ checksum اختياري ويُنصح بتوفيره من مصدر موثوق.
- `scripts/tests/test_build_tools.py`: اختبارات مستقلة بمصادر وأدوات وهمية ضمن مجلد مؤقت، دون تغيير ملفات التطبيقات.

### التحقق
- `python3 -m unittest discover -s scripts/tests -v`: نجاح 8 اختبارات (التطبيقان، فشل Gradle، غياب المشروع، متطلبات توقيع release، معلومات APK، غياب الأجهزة وتعددها وعدم اعتمادها).
- `bash -n` لكل سكريبت: ناجح.
- `git diff --check`: ناجح.
- `scripts/check-env.sh`: أبلغ عن غياب Java وGradle وSDK وADB، كما هو متوقع في هذه البيئة.

### حدود التحقق والتسليم
وقت التنفيذ لم يحتوِ المستودع إلا على README.md، ولم تتوفر apps/ أو أدوات Android. لم يتم بناء APK فعلي أو اختبار توقيع حقيقي أو تثبيت على جهاز، ولم يتم تأكيد إعداد SDK عبر الشبكة. بيئة الوكيل لا تسمح بالوصول إلى مضيف تنزيل Google. يجب إعادة الاختبار في CI أو محليًا بعد توفير المصادر وJDK وSDK ومفاتيح توقيع مخصصة عبر مخزن أسرار. لم تُعدّل ملفات Kotlin أو Gradle أو GitHub Actions أو توثيق الوكيل 3.

### أمثلة تسليم للموثق
```bash
ANDROID_ACCEPT_LICENSES=1 bash scripts/android-sdk-setup.sh
bash scripts/check-env.sh
bash scripts/build-apk.sh all debug
bash scripts/build-apk.sh marketer release  # بعد ضبط متغيرات التوقيع بأمان
bash scripts/apk-test.sh info path/to/app.apk
bash scripts/apk-test.sh install path/to/app.apk DEVICE_SERIAL
```

### تنسيق التواصل
تم اعتماد التواصل عبر ملفات المستودع فقط. أُضيفت رسالة تسليم وتنسيق في `TEAM_COLLABORATION.md`. الوكيل 2 في انتظار توفر المصادر وبيئة Android أو تعليمات جديدة؛ لا يوجد طلب قرار معلّق من المنسق حاليًا.

### تحديث تنفيذ توجيه الوكيل 0 — 2026-11-06
- جُلب الفرع `arena/6b69a15d-tammtool` للقراءة عبر `git fetch` دون تبديل فرع العمل `arena/43aae3e2-tammtool` أو تعديل ملفات التطبيقين.
- المصادر متاحة في فرع المنسق، لكنها ليست ضمن شجرة العمل المحلية الحالية؛ تقارير غياب المصادر أعلاه تصف وقت التنفيذ الأول، لا حالة فرع المنسق الآن.
- روجعت واجهة السكريبتات في فرع المنسق: أُضيف توافق `build-apk.sh debug marketer` إلى جانب `build-apk.sh marketer debug`، ودعم أسماء التطبيقات البديلة. الأمر bundle/AAB الموجود في فرع المنسق غير مشمول بهذا التنفيذ؛ يجب الاحتفاظ به عند الدمج إن كان مطلوبًا. كذلك أوامر uninstall/logcat/screenshot غير مشمولة؛ لا تستبدل سكريبت فرع المنسق دون مراجعة هذه الفروق.
- أضيف حفظ خرج Gradle الكامل مع stacktrace في `.build-logs/<app>-<variant>.log`، مع الحفاظ على رمز فشل Gradle عبر pipefail. يمكن تخصيص المكان بـ BUILD_LOG_DIR؛ يُرجى من المنسق رفع هذه السجلات كـ CI artifact حتى عند فشل البناء. لا تتضمن السكريبتات طباعة أسرار التوقيع، لكن يجب مراجعة أي سجل قبل نشره للعامة.
- أضيفت أوامر `devices` و`launch PACKAGE [SERIAL]` و`test APK [SERIAL]`. يستخرج test اسم الحزمة الحقيقي بواسطة aapt ويثبت ويشغل التطبيق المختار دون حذف بيانات المستخدم أو إزالة التطبيق الآخر؛ لا يدعي اجتياز اختبار وظيفي.
- نتائج التحقق المحدّثة: 10 اختبارات وهمية ناجحة، تشمل واجهة المنسق القديمة وحفظ سجل البناء واستخراج الحزمة والتثبيت والتشغيل دون uninstall؛ وفحص Bash ناجح. لم يتم تنفيذ بناء Android فعلي.
- ملاحظة إحالة للوكيل 1/المنسق من قراءة `apps/marketer/app/build.gradle.kts` في الفرع المذكور: Java targetCompatibility مضبوط على 1.8 بينما kotlinOptions.jvmTarget مضبوط على 17؛ هذا تعارض محتمل للتحقق من JVM targets في Kotlin Gradle. يُرجى توحيد الأهداف بعد مراجعة إعدادات المشروع؛ لم أعدل Gradle لأنه خارج نطاق الوكيل 2.
- التسليم جاهز للمراجعة والدمج من فرع هذه الجلسة، دون ادعاء إصلاح سبب CI أو إنتاج APK نهائي.

### فحص رد الوكيل/المنسق بطلب المستخدم — 2026-11-06
- تم تحديث القراءة من فرع المنسق `arena/6b69a15d-tammtool` عند الالتزام `e0cdea0947a553918d75726986d6b8e06a46c99a` وفحص `AGENTS_STATUS.md` و`TEAM_COLLABORATION.md` فيه، إلى جانب النسختين المحليتين.
- النتيجة: لا يوجد رد جديد موجّه للوكيل 2 أو تعليمات إضافية في الملفين المفحوصين. ما زال قسم الوكيل 2 في فرع المنسق يعرض «قيد الانتظار / لم يبدأ بعد»، ولا يعكس التنفيذ المحلي الموثق أعلاه.
- ملاحظات المنسق المتاحة تؤكد فشل assembleDebug وتعذر قراءة سجلات API وكتابة ci-build.log؛ لا تتضمن سجل خطأ تجميع محددًا أو تأكيد دمج سكريبتات الوكيل 2.
- الإجراء: لا تغيير في نطاق العمل ولا ادعاء وصول رد غير موجود. التسليم المحلي جاهز؛ يلزم تنسيق دمجه وتحديث حالة الوكيل 2 في فرع المنسق. لم يتم تبديل فرع الجلسة أو تعديل فرع المنسق.

### إلى الوكيل 0 — تحليل فقط بطلب المستخدم، دون إصلاحات
المرجع المفحوص: نسخة FETCH_HEAD من فرع المنسق، الالتزام `e0cdea0947a553918d75726986d6b8e06a46c99a`. لم يُنفذ بناء أو تعديل كود أو سكريبتات أو CI أو دفع Git في هذه المراجعة؛ التغيير الوحيد هو تسجيل هذا البلاغ.

**عوائق إعداد مؤكدة من الملفات، وليست تشخيصًا مثبتًا لأول خطأ في CI:**
1. في التطبيقين، settings.gradle.kts يفرض `FAIL_ON_PROJECT_REPOS`، بينما build.gradle.kts الجذري يضيف `allprojects.repositories`. هذا تعارض إعداد مستودعات يمنع تهيئة البناء عند إضافة مستودعات المشروع. التوصية للمسؤول: توحيد تعريف مستودعات الاعتماديات في settings.
2. في app/build.gradle.kts للتطبيقين توجد استدعاءات `kapt(...)` لـ Hilt وRoom دون تطبيق `org.jetbrains.kotlin.kapt` ضمن قائمة plugins. يُتوقع أن يؤدي ذلك إلى unresolved reference أثناء تجميع سكريبت Kotlin DSL؛ وتوليد Hilt/Room يحتاج إلى معالج annotations مفعل. التوصية: مراجعة تفعيل kapt المتوافق مع إصدار Kotlin.
3. Java source/target مضبوط على 1.8، وKotlin jvmTarget مضبوط على 17 في التطبيقين. هذا تعارض أهداف JVM مرشح لفشل تحقق Kotlin. التوصية: توحيد الأهداف.
4. Kotlin مضبوط على 1.9.20 بينما Compose compiler مضبوط على 1.5.8؛ هذا الزوج غير متوافق (1.5.8 يستهدف Kotlin 1.9.22). التوصية: اختيار زوج متوافق والتحقق وفق جدول Compose/Kotlin قبل التغيير.

**مشكلات رصد CI في .github/workflows/build-apk.yml:**
5. البناء يعمل داخل apps/marketer ويكتب إلى `../ci-build.log`، أي `apps/ci-build.log`، وليس جذر المستودع. خطوة الحفظ تبحث عن ملف الجذر ثم تكتب `NO BUILD OUTPUT` عند غيابه، ولا تنقل الملف الذي تجده عبر find. هذا يفسر فقدان سجل Gradle الحقيقي في الملف المحفوظ.
6. البناء يستخدم `set +e` ويحفظ BUILD_EXIT دون إرجاعه بـ exit؛ لذلك قد تبدو الخطوة ناجحة رغم فشل Gradle، وتعمل خطوة artifact بشرط success() دون APK. التوصية: حفظ/رفع السجلات دائمًا مع إبقاء فشل البناء ظاهرًا.
7. تعريف `ANDROID_HOME: $HOME/android-sdk` في env لخطوة البناء لا يخضع لتوسيع shell متكرر؛ قد يصل للمهمة حرفيًا ويغطي القيمة الصحيحة المحفوظة في GITHUB_ENV. local.properties يشير لمسار صحيح، لذا التأثير النهائي يحتاج سجل التشغيل، لكن الإعداد متعارض.
8. تثبيت حزم SDK يخفي المخرجات ويتجاوز الفشل بواسطة `|| true`؛ نجاح sdkmanager --version لا يثبت تثبيت platform/build-tools.
9. AGP 8.2.0 مع compileSdk 35 خارج مستوى API المدعوم رسميًا لذلك الإصدار؛ ملاحظة توافق إضافية وليست دليلًا وحدها على سبب الفشل الحالي.

**الأولوية المقترحة للمنسق:** استعادة سجل Gradle الصحيح أولًا، ثم مراجعة تعارض المستودعات وغياب kapt، ثم أهداف JVM وتوافق Compose/Kotlin، ثم إعادة البناء. لا يمكن تأكيد أول خطأ فعلي أو نجاح الحل دون سجل وتجربة بناء. هذا التقرير محلي على فرع الوكيل 2 وغير مدفوع؛ لا أدعي وصوله تلقائيًا إلى فرع المنسق.

### التحقق مما يحتاجه الوكيل 0 — آخر قراءة 2026-11-06
- فُحص أحدث فرع المنسق عند `64773c7e4851981f035113a0ac941a2d23cbc8cc` للقراءة فقط. لا توجد رسالة جديدة تطلب مساعدة محددة في ملفي الحالة والتنسيق؛ ما زالت حالات الوكلاء فيهما قديمة.
- آخر تغييرات المنسق تركز على البحث عن APK وجعل حفظ السجلات غير حاسم. لم أجد ملف ci-build.log متتبعًا في شجرة ذلك الالتزام؛ لذلك لا يتوفر بعد سجل فعلي نستخرج منه أول خطأ Gradle.
- ما يحتاجه المنسق عمليًا: (1) إخراج سجل Gradle الحقيقي كـ artifact حتى عند الفشل، (2) إعادة رمز فشل Gradle للـ CI بدل إخفائه، (3) مراجعة عوائق Gradle/Kotlin المحددة في التقرير السابق، (4) تنسيق استلام تغييرات الوكيل 2 التي ما زالت محلية وغير مدفوعة.
- تنبيه: workflow الحالي قد يرفع `no-apk.txt` داخل artifact باسم afghani-orders-apk عند غياب APK، ويستخدم continue-on-error في البحث. وجود artifact أو مرور خطوة الرفع ليس دليل نجاح بناء التطبيق. يلزم تحقق صريح من وجود APK الناتج من مهمة البناء المطلوبة، وليس أول APK عشوائي من المستودع.
- لم أنفذ إصلاحات أو بناء أو دفعًا في هذا الفحص. هذا تحديث تحليلي فقط، ولا أدعي أن المنسق قرأ النسخة المحلية منه.

### إتاحة المساعدة للمنسق بطلب المستخدم
أُعيد فحص فرع المنسق ولم تظهر تعليمات جديدة؛ ما زال عند الالتزام `64773c7`. لتجاوز عائق عدم وصول التحليل المحلي، سيُنشر ملف التقرير هذا وحده على فرع الوكيل 2 `arena/43aae3e2-tammtool`، دون دمج أو تعديل فرع المنسق أو تشغيل CI أو نشر السكريبتات غير المراجعة.

إلى الوكيل 0: يمكن قراءة هذا الملف من فرع الوكيل 2 مباشرة. أهم مساعدة جاهزة هي تحليل عوائق الإعداد ومسارات السجل أعلاه. يرجى وضع أي طلب تنفيذ محدد في قسم المنسق بملف AGENTS_STATUS.md على فرعكم. سكريبتات الوكيل 2 واختباراتها ما زالت محلية ولم تُنشر ضمن هذا التسليم التحليلي، ولن تُستبدل سكريبتاتكم تلقائيًا. نشر التقرير لا يعني أن المنسق قرأه أو وافق على توصياته.

### تسليم تنفيذي للوكيل 0 — متابعة طلب المستخدم
- قبل بدء المتابعة قُرئ ملف TEAM_COLLABORATION.md وملف الحالة من فرع المنسق عند `c258068835ab26ac273965609cf3946a4256f2c3`؛ لم يوجد تكليف إضافي، لذلك استُكمل نطاق الوكيل 2 الأصلي بدل الانتظار.
- جُهزت السكريبتات الأربعة واختباراتها للنشر على فرع الوكيل 2، دون المساس بفرع المنسق أو Kotlin/Gradle أو workflow.
- أضيف دعم `android-sdk-setup.sh --accept-licenses` للتوافق مع الاستدعاء الموجود بفرع المنسق، ورفض الخيارات غير المعروفة.
- تحقق فعلي محلي: 13 اختبارًا وهميًا ناجحًا، تشمل الآن مسار توقيع release والتحقق منه باستخدام أدوات وهمية، ورفض نجاح Gradle دون APK. فحص bash -n لكل سكريبت ناجح. لم ينتج APK Android حقيقي ولم يُختبر SDK عبر الإنترنت.
- تنبيه الدمج: سكريبتات هذا الفرع مبنية على النسخة الأولية الفارغة؛ على المنسق مراجعة الفروق لا استبدال ملفاته آليًا. دعم bundle/AAB وuninstall/logcat/screenshot الموجود عند المنسق غير موجود هنا، كما أن check-env يُعامل غياب ADB كبيئة غير مكتملة، لا كمانع للبناء وحده. لا تُدمج ملفات الحالة فوق تقارير باقي الوكلاء دون حفظ أقسامهم.
- طريقة الاستفادة: استعراض scripts/ على فرع arena/43aae3e2-tammtool ونقل التحسينات المرغوبة بعد المراجعة؛ مسار السجلات .build-logs/ يدعم رفعها كـ artifact بدل كتابة سجلات آلية إلى Git.

### استجابة لطلب المنسق الجديد: سكريبت تشخيص عدم إنتاج APK
في مراجعة التواصل قبل التوقف ظهر تحديث `7eccab826352b3823b74632606d8ffc9dfbba372` وفيه طلب صريح للوكيل 2 بإضافة سكريبت تشخيص؛ تم تنفيذه بدل التوقف.
- أُضيف `scripts/diagnose-apk.sh [marketer|orders-delivery|all]`: يجمع فحص البيئة، يشغّل البناء مع السجل الكامل، يحفظ BUILD_EXIT الفعلي في التقرير وملف exit-code منفصل، ويجرد مسارات APK وoutput-metadata.json. لا يكتب إلى Git ولا ينشئ APK وهميًا؛ ويرجع رمز الفشل الحقيقي.
- الاختبار: 15 اختبارًا وهميًا ناجحًا بما فيها حفظ فشل Gradle 7 وتشخيص النجاح؛ bash -n ناجح. لا يوجد بناء Android حقيقي في هذه البيئة.
- تصحيح تفسير المنسق: نجاح خطوة shell الحالية لا يثبت أن Gradle رجع 0؛ بعد set +e تُحفظ قيمة Gradle ثم تنتهي الخطوة بـ echo ناجح. يلزم قراءة BUILD_EXIT نفسه أو استخدام سكريبت التشخيص الذي يعيد القيمة الفعلية.
- سبب محدد لتعطل حفظ السجل حاليًا: الخطوة تبدأ داخل apps/marketer ثم تنفذ cd .. فتصل apps/؛ الأمر git add apps/marketer/ci-build.log يصبح نسبيًا إلى apps/، فيستهدف مسارًا خاطئًا. الحل المقترح للمنسق: العمل من جذر المستودع أو رفع apps/marketer/ci-build.log كـ artifact دون git commit.

مثال CI مقترح للمنسق بعد دمج السكريبتات (لم يُعدل workflow هنا):
```yaml
- name: Diagnose marketer APK
  run: bash scripts/diagnose-apk.sh marketer
- name: Upload build diagnostics
  if: always()
  uses: actions/upload-artifact@v4
  with:
    name: marketer-build-diagnostics
    path: .build-logs/
    include-hidden-files: true
    if-no-files-found: error
```
يجب إزالة ANDROID_HOME الحرفي `$HOME/android-sdk` من env خطوة البناء أو استبداله بمسار محلول، والحفاظ على إعداد SDK الصحيح. يحتوي تسليم b9cb2af على الأدوات الأساسية، والتسليم التالي على التشخيص؛ التغييرات متاحة بفرع الوكيل 2 للمراجعة ولا تعني دمجها أو قراءتها تلقائيًا من المنسق.

### بحث حلول وأدوات وطرق بديلة — رسالة للوكيل 0 (2026-11-06)
**قراءة التواصل:** تمت قراءة TEAM_COLLABORATION.md وAGENTS_STATUS.md من فرعكم عند `d5966225db04cd0cc410f5e4224296f642f791a3`. الطلب الصريح ما زال تشخيص عدم إنتاج APK؛ السكريبت المطلوب منشور بالفعل في تسليم `aca10ea` على فرع الوكيل 2.

#### نتائج جديدة من GitHub API، لا تخمينات
- نجح `gh run list` وقراءة jobs وartifacts وcheck annotations من هذه البيئة، بخلاف تحميل سجل التشغيل الكامل الذي فشل بـ EOF عند التحويل إلى results-receiver.actions.githubusercontent.com. المشكلة ليست انقطاع API بالكامل؛ مضيف تحميل السجلات خارج المضيفات المسموحة لبيئة الوكيل.
- آخر تشغيل مفحوص: https://github.com/22kdx/TAMMTOOL/actions/runs/42268790783 على الالتزام d5966225، حالته success. artifact المسمى afghani-orders-apk حجمه **153 بايت** وفق metadata؛ لم يُحمّل محتواه هنا، والحجم وحده ليس برهانًا على نوعه. النص البديل في workflow وتقريركم السابق يفسران الاشتباه بأنه ليس APK.
- check-run `128067629639` يحتوي annotation مستوى failure نصه `Process completed with exit code 128.` رغم نجاح job العام. لا يحدد annotation وحده الأمر المسبب ولا يعني أن Gradle رجع 128. هناك تحذيرات منفصلة بشأن Node 20 وsetup-java v4 وتغير ubuntu-latest؛ ليست دليلًا على سبب خطأ التجميع.
- تعارض cd/git add ما زال قائمًا في workflow، كما بقيت set +e دون exit BUILD_EXIT وANDROID_HOME الحرفي وملف no-apk.txt. لذلك لا يصح استنتاج نجاح Gradle من اللون الأخضر للمهمة.

#### طرق بديلة لاسترجاع التشخيص عند تعذر تنزيل logs
1. **annotations عبر API (متاحة ومجربة):**
   ```bash
   gh run list --repo 22kdx/TAMMTOOL --branch arena/6b69a15d-tammtool --limit 5
   gh api repos/22kdx/TAMMTOOL/actions/runs/42268790783/jobs
   gh api repos/22kdx/TAMMTOOL/check-runs/128067629639/annotations
   gh api repos/22kdx/TAMMTOOL/actions/runs/42268790783/artifacts
   ```
   metadata ليست بديلًا كاملًا عن سجل Gradle، لكنها تكشف أخطاء runner التي يخفيها continue-on-error.
2. **سجل artifact دائم:** استخدموا diagnose-apk.sh المنشور، ثم upload-artifact مع if: always() وinclude-hidden-files: true لمسار .build-logs/؛ ملف منفصل لكل تطبيق يمنع تضارب السجلات. سيظل تنزيل artifact قد يحتاج مضيفات تخزين إضافية؛ يمكن تنزيله من المتصفح خارج بيئة الوكيل.
3. **Job Summary / annotations مختصرة:** اكتبوا رمز Gradle الحقيقي ومقتطفًا محدودًا ومراجعًا من أول خطأ إلى GITHUB_STEP_SUMMARY، وأصدروا `::error::Gradle failed; see diagnostics` عند الفشل. يمكن قراءته من واجهة التشغيل دون دفع سجلات إلى المستودع. لا تنشروا أسرارًا أو مخرجات debug غير مراجعة. يمكن قراءة annotations المختصرة من API المتاح هنا.
4. **المتصفح أو جهاز محلي غير مقيّد:** gh run view RUN_ID --log وgh run download RUN_ID يعملان فقط عند السماح بمضيفات تنزيل GitHub؛ عدم نجاحهما هنا لا يثبت فشلهما على جهازكم. لا تطلبوا رموز دخول في الدردشة.
5. **Git كحل أخير:** إن أصررتم على حفظ سجل في المستودع، اجعلوا المسارات من جذر git عبر `git -C "$GITHUB_WORKSPACE" add -- apps/marketer/ci-build.log`، مع منع إعادة تشغيل push workflow بسبب commits السجل ومراجعة محتواه. artifact أفضل لتجنب تضخم Git وحلقات CI. هذا اقتراح فقط ولم أعدل workflow أو أدفع إلى فرعكم.

#### أدوات بديلة جرى التحقق من مستودعاتها
- **gradle/actions/setup-gradle:** بدل تنزيل Gradle يدويًا؛ يوصي بالـ Wrapper ويدعم اختيار نسخة محددة عند غيابه. مرجع: https://github.com/gradle/actions/tree/main/setup-gradle و https://github.com/gradle/actions/blob/main/docs/setup-gradle.md . لا تعتمدوا latest؛ ثبّتوا إصدار Gradle الموافق لـ AGP وراجعوا متطلبات نسخة action المختارة، ويفضل pin إلى commit SHA موثوق. آخر وسوم شوهدت تتضمن v6.4.1؛ ليست توصية بترقية المشروع تلقائيًا.
- **android-actions/setup-android:** بديل لخطوة curl/unzip وقبول الرخص اليدوي، مع حزم منصات وbuild-tools مصرح بها؛ مرجع https://github.com/android-actions/setup-android . الوسوم المفحوصة تتضمن v4.0.4. لا يزال يحتاج الوصول لخوادم Google ولا يحل عيوب Gradle/Kotlin. قبول الرخص يتطلب تفويض صاحب المشروع.
- **actions/upload-artifact:** تحققت من action.yml عند v4 أن if-no-files-found وinclude-hidden-files مدعومان. اضبطوا if-no-files-found: error لمخرجات APK الحقيقية فقط، ولا تستخدموا placeholder لتمرير البناء. مرجع: https://github.com/actions/upload-artifact/blob/v4/action.yml .
- **Gradle Wrapper كامل ومثبت:** حفظ gradlew وgradlew.bat وgradle-wrapper.jar وproperties، والتحقق من توزيع Gradle بالـ checksum، يقلل اختلاف المحلي وCI. لا تنشئوا Wrapper جديدًا بإصدار عشوائي فوق المشروع دون مراجعة التوافق.
- **تشخيص تدريجي:** نفذوا `:app:tasks --all` و`:app:assembleDebug --dry-run` لعزل فشل تهيئة Gradle أولًا، ثم البناء الحقيقي بـ --stacktrace --info --console=plain. dry-run لا يجمع الكود ولا يثبت صحة Hilt/Room. يمكن إضافة --rerun-tasks إذا اشتُبه بمخرجات قديمة؛ لا تمسحوا caches عشوائيًا قبل حفظ السجل.
- **تحقق APK:** aapt dump badging أو apkanalyzer manifest application-id/version-name لبيانات الحزمة، وapksigner verify --verbose للتحقق من التوقيع. zipinfo/unzip -t يكشف فساد ZIP لكنه وحده لا يثبت أن الملف APK صالح. اختبار التثبيت عبر adb على جهاز/محاكي مرحلة منفصلة بعد نجاح البناء.

#### أولوية التنفيذ المقترحة
أولًا احصلوا على BUILD_EXIT الحقيقي وأول خطأ Gradle، ثم أصلحوا تعارض repositories/غياب kapt/اختلاف JVM/زوج Kotlin-Compose الواردة أعلاه حسب الخطأ الفعلي؛ بعدها تحققوا من APK والتوقيع ثم التثبيت. أدوات جديدة أو تحديث Actions لن تصلح هذه التعارضات تلقائيًا. لم أغير إعدادات CI أو Kotlin أو Gradle خلال هذا البحث ولم أدّعِ نجاح البناء.

### منهج مهارات الوكيل بطلب المستخدم
- أُضيف skills/android-development.md كدليل ممارسة قابل لإعادة الاستخدام: فهم المشروع، تشخيص البناء، مراجعة Kotlin/Hilt/Room/Compose، الاختبارات، CI، الأمن والتسليم بين الوكلاء.
- هذه معرفة موثقة داخل المستودع وليست تدريبًا دائمًا للنموذج أو إثبات بناء Android ناجح. لم تُغير أدوار الفريق أو إعدادات التطبيقين.
- أعيد تشغيل الاختبارات المتاحة: 15 اختبارًا وهميًا ناجحًا. بقي التحقق على Android الحقيقي غير منفذ.

### رد الوكيل 2 على أسئلة المنسق المباشرة — 2026-11-06
قُرئ ملف التواصل وملف الحالة عند الالتزام `e358aecf4339dcbafe77416ea99eb1bf141377ba` من فرع المنسق. الرد التالي يخص الأدوات فقط، ولا يفترض أن التغييرات السابقة دُمجت.

1. **هل المهمة صحيحة؟** نعم: سكريبت فرع المنسق يمرر `:app:assembleDebug` عند اختيار debug. سكريبت فرع الوكيل 2 يمررها أيضًا ويشغل Gradle من apps/<app>، ويعيد فشله مع حفظ stdout/stderr. وجود الخطأ في task name ليس مثبتًا. اللون الأخضر الحالي لا يثبت BUILD_EXIT=0 بسبب set +e ثم echo الناجح. أخطاء Kotlin لا تُتجاهل عادة في مهمة التجميع؛ نحتاج أول خطأ حقيقي قبل استنتاج فشل صامت.
2. **طباعة outputs:** متاح بالفعل `bash scripts/diagnose-apk.sh marketer`؛ يسجل فحص البيئة والبناء، ويطبع ملفات APK وoutput-metadata.json داخل app/build/outputs أو يصرح بغياب المجلد، ويحفظ رمز الخروج في .build-logs/diagnose-marketer.exit-code. لا ينشئ placeholder.
3. **ضمان SDK المطلوب:** أُضيف الآن scripts/check-sdk.sh ليتحقق تحديدًا من android-35/android.jar غير فارغ وأدوات aapt2 وzipalign وapksigner القابلة للتنفيذ داخل build-tools/35.0.0. android-sdk-setup.sh يستدعيه بعد sdkmanager وقبل إعلان نجاح الإعداد. لا يتجاوز فشل التثبيت بـ || true. الفحص يثبت وجود الملفات فقط، لا صحة جميع محتويات SDK أو نجاح البناء.
4. **فحص CI قبل Gradle:** استخدموا `bash scripts/check-sdk.sh` بعد الإعداد وقبل البناء؛ لا يشترط ADB فلا يفشل CI لمجرد غياب جهاز. check-env.sh يظل فحصًا عامًا للأدوات، وليس البديل الدقيق لفحص نسخة SDK.

مقترح إدراج من المنسق بعد نقل scripts/ وتحقيق توافق واجهاته:
```yaml
- name: Verify Android 35 SDK
  run: bash scripts/check-sdk.sh
- name: Diagnose APK build
  run: bash scripts/diagnose-apk.sh marketer
- name: Upload diagnostics
  if: always()
  uses: actions/upload-artifact@v4
  with:
    name: marketer-build-diagnostics
    path: .build-logs/
    include-hidden-files: true
    if-no-files-found: error
```
قبل هذه الخطوات يجب تصحيح ANDROID_HOME الحرفي وإزالة التعارض مع ANDROID_SDK_ROOT إن وجد. لا أنصح بإعادة تشغيل CI مرارًا قبل اعتماد حفظ السجل ورمز الخروج.

**التحقق:** 17 اختبارًا وهميًا ناجحًا وفحص bash -n لكل السكريبتات ناجح؛ يشمل الاختبار الجديد رفض منصة مفقودة وأداة aapt2 مفقودة وقبول SDK وهمي دون ADB. لم يُختبر تنزيل SDK أو تجميع APK حقيقي. التعديلات على فرع الوكيل 2 فقط؛ لم تُعدل Kotlin/Gradle أو workflow أو فرع المنسق. المطلوب من المنسق مراجعة ونقل ملفات الأدوات المختارة، لا cherry-pick ملف الحالة كاملًا فوق أقسام باقي الوكلاء.
