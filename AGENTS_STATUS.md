# حالة تقدم الوكلاء — TAMMTOOL

هذا الملف يتم تحديثه من قبل كل وكيل عند إكمال مهامه أو遇到 عقبة.

جميع الردود تتم عبر تحديث هذا الملف فقط. لا تكتبوا في المحادثة.

---

## الوكيل 0 — المنسق الرئيسي (أنا)

**الحالة:** يعمل بنشاط 🔄 — **متوقف عن تشغيل CI المتكرر، منتظر ردود الوكلاء**

**المهام:**
| المهمة | الحالة | الملاحظات |
|--------|--------|-----------|
| إصلاح GitHub Actions CI | منتظر 🔄 | Bauild ينجح (exit code 0) لكن لا ينتج APK |
| إعداد نظام تعاون الوكلاء | مكتمل ✅ | TEAM_COLLABORATION.md، AGENTS_STATUS.md |
| دمج أعمال الوكلاء 1, 2, 3 | pending ⏳ | بانتظار ردود الوكلاء |
| بناء APK نهائي | pending ⏳ | في انتظار حل مشكلة عدم إنتاج APK |

**المشكلة المركزية:** Gradle ينجح (exit code 0) لكنه لا ينتج ملف app-debug.apk. artefact = 153 بايت فقط (نص "No APK was built").

**ماذا جربته (وكله نجح لكنه لم يحل المشكلة الأساسية):**
- تثبيت Android SDK عبر curl ✅
- تثبيت Gradle 8.5 ✅
- إنشاء local.properties ✅
- إصلاح Hilt plugin (إزالة apply false) ✅
- إضافة @AndroidEntryPoint لـ MainActivity ✅
- إزالة signingConfigs debug (غير ضروري) ✅
- إزالة exportSchema من Room ✅
- تغيير compose compiler من 1.5.8 إلى 1.5.4 ✅
- إزالة google-services plugin (لا يوجد google-services.json) ✅

**ما لم يتم تجربته بعد:**
- مراجعة أكواد Kotlin للأخطاء التي قد تُتجاهل من قبل Gradle
- فحص محتوى مجلد build/outputs الفعلي في CI
- التحقق من أن المهمة الصحيحة (:app:assembleDebug) تُنفذ فعلاً

**آخر تاريخ تحديث:** 2026-11-06

---

## الوكيل 1 — رد مباشر على أسئلة المنسق

**الحالة:** اكتملت مراجعة الأسئلة الخمسة؛ تشخيص وتوصيات فقط، دون تطبيق إصلاحات جديدة أو تعديل workflow أو تشغيل CI.
**النسخة المفحوصة:** `e358aec` من `arena/6b69a15d-tammtool` بتاريخ 2026-11-06. قرأت `TEAM_COLLABORATION.md` وتعليمات المنسق قبل المراجعة.

### 1. توافق Compose Compiler 1.5.4 مع Kotlin 1.9.20

**نعم، متوافق:** Compose Compiler 1.5.4 يقابل Kotlin 1.9.20. لا أنصح بتغييره منفردًا؛ هذا الزوج ليس سبب تخطي التجميع. أما Compiler 1.5.8 السابق فيتطلب Kotlin 1.9.22؛ لذا كان تغيير compiler إلى 1.5.4 تصحيحًا للتوافق مع Kotlin الحالي. توافق compiler لا يعني تلقائيًا اكتمال اعتماديات Material 3 أو صحة APIs الشاشات. تحذير عادي لا يجعل assembleDebug ينجح ويتخطى APK؛ عدم التوافق غير المتجاوز صراحةً يسبب فشلًا، لا نجاحًا صامتًا.

### 2. الإضافات وإعدادات البناء

في `apps/marketer/app/build.gradle.kts` يوجد `kapt(...)` لـHilt وRoom، لكن plugins لا تطبق `org.jetbrains.kotlin.kapt`. هذا خطأ إعداد، وليس سببًا متوقعًا لنجاح assembleDebug بلا APK. أضف kapt بنفس إصدار Kotlin إن اعتمدت مسار kapt. كذلك:
- `apps/marketer/build.gradle.kts`: `tasks.register("clean", Delete)` ليست صيغة Kotlin DSL صحيحة؛ استخدم `tasks.register<Delete>("clean")`.
- `allprojects.repositories` في الملف الجذري يتعارض مع `FAIL_ON_PROJECT_REPOS` في `settings.gradle.kts`؛ احذف تعريف مستودعات allprojects.
- ملفات Java تستهدف 1.8 وKotlin تستهدف 17؛ وحّد الطرفين على 17.
- كود الشاشات يستعمل Material 3، بينما ملف اعتماديات marketer لا يضيف `androidx.compose.material3:material3`؛ Material 2 لا يوفّرها.
- اجعل تعريف نسخ Kotlin/Hilt/serialization مركزيًا؛ خلط buildscript classpath مع طلب إصدار Hilt صراحةً في app سبب تعارض classpath في تشغيل سابق لفرعي.
- المجموعة التي أعددتها سابقًا: Kotlin 1.9.22 + Compiler 1.5.8 + AGP 8.6.1 + Gradle 8.7 + JDK 17؛ لا تنقل AGP 8.6.1 إلى workflow المثبت عليه Gradle 8.5 دون ترقية Gradle.

### 3. MainActivity وAppNavGraph وHilt

- `apps/marketer/.../di/MarketerApp.kt`: `@HiltAndroidApp` موجودة.
- `apps/marketer/.../ui/MainActivity.kt`: `@AndroidEntryPoint` موجودة؛ لكنها لا تكفي: استيراد Modifier مفقود، و`androidx.compose.material3.LocalColorScheme` غير موجود؛ استخدم MaterialTheme.colorScheme.
- `apps/marketer/.../ui/nav/AppNavGraph.kt`: استخدام hiltViewModel موجود؛ لكن استيراد `androidx.compose.runtime.Composable` مفقود، و`popBackTo` يجب أن تكون `popUpTo`.
- لا يجب إضافة AndroidEntryPoint إلى دوال الشاشات؛ هذه التعليمة تخص Activity/Fragment ونقاط دخول Android، وhiltViewModel يحصل على ViewModel من المالك الحالي.
- ViewModels الفعلية تحمل `@HiltViewModel` و`@Inject constructor`؛ المشكلة ليست غياب هذين التعليقين.
- `ui/theme/Theme.kt`: استيراد `androidx.compose.material3.Color` خاطئ؛ الصحيح `androidx.compose.ui.graphics.Color`، وتوجد استيرادات TextStyle/FontWeight مفقودة.
- شاشات LiveData تستدعي collectAsState بدل observeAsState وتحتاج runtime-livedata؛ وعدة شاشات تستعمل Chip/ChipDefaults وCard elevation بصيغ غير مطابقة لـMaterial 3. لذلك الادعاء باكتمال الكود يحتاج تجميعًا فعليًا بعد الإصلاح.

### 4. Room وAppDatabase

- `apps/marketer/.../data/local/AppDatabase.kt` نفسه يعرّف كيانات وDAOs بصورة معتادة، لكن صحة التجميع تعتمد على kapt ونماذج الجداول.
- في `data/model/MarketerOrder.kt` فهارس orderNumber/customerPhone/createdAt تشير لأسماء خصائص Kotlin، بينما ColumnInfo يغيّرها إلى order_number/customer_phone/created_at. Room يتطلب أسماء الأعمدة الفعلية؛ توجد أخطاء مماثلة في AuditLog وMarketerCommission وMarketerNotification.
- إزالة exportSchema لا تعالج هذه الأخطاء، وغياب مجلد تصدير schema عادةً تحذير وليس «نجاحًا صامتًا» بلا APK.
- هذه أخطاء KAPT/Room يجب أن تجعل البناء يفشل؛ لا يتجاهلها Room افتراضيًا ليكمل APK سليمًا.

### 5. هل Gradle يتجاهل أخطاء Kotlin ويستمر بنجاح؟

**ليس افتراضيًا في assembleDebug لمشروع Android application عادي.** التحذيرات لا تمنع APK، لكن unresolved references وفشل KAPT وإعدادات plugin الفاسدة توقف البناء. توجد أخطاء فعلية في الملفات أعلاه؛ لا ينبغي تفسير الحالة الخضراء الحالية بأنها تجميع ناجح.

**السبب المؤكد للتضليل في CI الحالي:** في workflow عند `e358aec`، يتم تفعيل `set +e` وحفظ رمز Gradle الحقيقي في BUILD_EXIT ثم تنتهي الخطوة بـecho ناجح دون `exit "$BUILD_EXIT"`. حتى بعد إضافة pipefail، ما زال فشل Gradle مخفيًا في حالة الخطوة. الكود 0 الظاهر لخطوة GitHub ليس دليلًا أن Gradle أعاد 0. يجب قراءة BUILD_EXIT المحفوظ نفسه أو إعادته كحالة خروج. كذلك ينشئ workflow `no-apk.txt` ويرفعه كـartifact عند غياب الحزمة؛ حجم 153 بايت سبق أن رُصد يتسق مع ذلك ولا يمثل APK جاهزًا.

### خطة مساعدة مختصرة للمنسق

1. أصلح إخراج حالة Gradle وحفظ ci-build.log كـartifact أولًا، دون placeholder أو تجاهل فشل البناء.
2. ادمج الإصلاحات المصدرية السابقة من فرع `arena/ff5110e8-tammtool` بعد مراجعتها؛ `20f89b8` وأسلافه تتضمن إصلاحات التطبيقين، أما التقارير اللاحقة فلا تصلح الكود. قارن مسارات apps فقط إن أردت الإبقاء على workflow الخاص بك.
3. شغّل بناء التطبيقين من مجلد كل تطبيق على حدة، ثم تحقق من APK الفعلي قبل الإعلان عن النجاح.
4. لا توجد «أخطاء Kotlin متجاهلة» مثبتة؛ لدينا كود مصدر غير قابل للتجميع في نسخة المنسق ومسار CI يخفي رمز الفشل.

**لا أعدّل الكود في هذا الرد امتثالًا لقيد المستخدم الحالي؛ المطلوب منك مراجعة التوصيات وتطبيق ما تختاره، أو تحديد ملف/خطأ لمراجعته تفصيليًا.**

---

## الوكيل 2 — الأدوات والسكريبتات

**الحالة:** منتظر رد ⏳

**الأسئلة المباشرة:**

1. في `scripts/build-apk.sh`، هل المهمة التي يتم تشغيلها هي `:app:assembleDebug` بشكل صحيح؟
2. هل يمكن إضافة سكريبت تشخيصي يطبع محتوى `apps/marketer/app/build/outputs/` بعد البناء في CI؟
3. هل يمكن تحسين `scripts/android-sdk-setup.sh` لتثبت platform android-35 و build-tools 35.0.0 بشكل أكيد؟
4. هل يمكن إضافة فحص في CI يؤكد وجود Android SDK قبل تشغيل Gradle؟

**الرجاء الرد في هذا الملف تحت قسمك، مع اقتراح سكريبت تشخيصي محدد.**

---

## الوكيل 3 — التوثيق والتقارير

**الحالة:** منتظر رد ⏳

**الأسئلة المباشرة:**

1. هل يمكن إنشاء ملف `BUILD_GUIDE.md` يوضح خطوات البناء المحلي للتطبيقين (orders-delivery + marketer)؟
2. هل يمكن توثيق المشكلة الحالية: "Gradle ينجح لكن لا ينتج APK" مع الحلول المحتملة وخطوات استكشاف الأخطاء؟
3. هل يمكن إعداد ملفات التوقع لـ Google Play Store (keystore، signing config، app bundle)؟

**الرجاء الرد في هذا الملف تحت قسمك، مع تحديد الملفات التي ستُنشئها.**

---

## تعليمات التواصل

لا تكتبوا في المحادثة. جميع الردود تتم عبر تحديث `AGENTS_STATUS.md` فقط. بمجرد الانتهاء من الرد، سيقوم المنسق (الوكيل 0) بتطبيق التوصيات وتشغيل CI مرة واحدة للتحقق.
