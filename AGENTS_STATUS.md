# حالة تقدم الوكلاء — TAMMTOOL

هذا الملف يتم تحديثه من قبل كل وكيل عند إكمال مهامه أو遇到 عقبة.

## الوكيل 0 — المنسق الرئيسي (أنا)

**الحالة:** يعمل بنشاط 🔄

**المهام:**
| المهمة | الحالة | الملاحظات |
|--------|--------|-----------|
| إصلاح GitHub Actions CI | يعمل 🔄 | بناء APK يفشل في كل مرة، يتم تشخيص الخطأ |
| إعداد نظام تعاون الوكلاء | مكتمل ✅ | TEAM_COLLABORATION.md، AGENTS_STATUS.md созданы |
| دمج أعمال الوكلاء 1, 2, 3 | pending ⏳ | بانتظار إكمال المهام |
| بناء APK نهائي | pending ⏳ | بانتظار إصلاح CI |

**آخر تحديث:** 2026-11-06

---

## الوكيل 1 — مراجعة Kotlin وGradle

**التاريخ:** 2026-11-06  
**الفرع:** `arena/ff5110e8-tammtool`  
**الحالة:** اكتملت المراجعة المصدرية والإصلاحات المعروفة؛ نجاح تجميع التطبيقين يحتاج تحقق Gradle النهائي لدى المنسق.

### النطاق والنتائج
- مراجعة جميع ملفات Kotlin وGradle في `apps/marketer` و`apps/orders-delivery` (104 ملفات).
- تأكيد `@HiltAndroidApp` في كلا Application، و`@AndroidEntryPoint` في كلا MainActivity، واستخدام `hiltViewModel()` في التنقل والشاشات.
- تأكيد `@HiltViewModel` و`@Inject constructor` في جميع ViewModels الفعلية؛ `BaseViewModel` مجردة ولا تحتاج إليهما. وحدات DI تستخدم `@Module` و`@InstallIn(SingletonComponent::class)` وتوفر قواعد البيانات وDAOs والمستودعات.
- توحيد AGP 8.6.1، Kotlin 1.9.22، Compose Compiler 1.5.8، Java/Kotlin JVM 17، Hilt 2.50 وRoom 2.6.1. مطلوب Gradle 8.7 وJDK 17.
- إضافة kapt وMaterial 3 وruntime-livedata؛ نقل تعريف نسخ الإضافات إلى Gradle الجذري وإزالة تعارض مستودعات المشروع مع `FAIL_ON_PROJECT_REPOS`.
- إصلاح استيرادات Compose (الأيقونات، Modifier، Color، FontWeight، TextStyle، LazyColumn وFlow.first)، وواجهات Card/SuggestionChip، وKeyboardType/PasswordVisualTransformation و`popUpTo`.
- استبدال `collectAsState` غير الصحيح على LiveData بـ`observeAsState`؛ إصلاح استخدام MaterialTheme بدل LocalColorScheme غير الموجود.
- إصلاح قائمة المنتجات: `items` على مستوى LazyListScope، والنقر باستخدام Modifier بدل معامل ListItem غير الموجود.
- إصلاح استدعاءات ProductRepository وUserRepository وGovernorateRepository لدوال DAO الفعلية.
- إزالة استيراد `androidx.room.Specification` غير الموجود، وتصحيح `register(user)` لاستخدام كائن User الممرر بدل متغير `password` ودالة `hash()` غير المعرّفين. يجب على جهة الاستدعاء تمرير passwordHash صحيح؛ لم تتم إضافة نظام مصادقة جديد.
- تأكيد @Entity و@PrimaryKey لكل النماذج؛ تصحيح أسماء أعمدة indices وchildColumns إلى أسماء ColumnInfo، وربط إسقاط StockSummary بأسماء أعمدة SQL.
- استخدام COALESCE في المجاميع المالية التي تعيد Double لتجنب NULL على الجداول الفارغة.
- إصلاح موارد تمنع البناء: مراجع theme إلى style، ونقل adaptive/vector icons إلى مجلداتها الصحيحة، وحذف placeholder من values وإضافة أيقونات fallback للتطبيق الرئيسي.

### التحقق المنفذ
- `python -m unittest discover -s tests -v`: نجحت اختبارات Hilt وعقود Repository/DAO وRoom/SQL. الاستعلامات تُفحص بـSQLite EXPLAIN على جداول مستخرجة من ColumnInfo؛ ليس اختبارًا لمحرك Room أو سلوك التطبيق الكامل.
- تحليل 104 ملفات `.kt` و`.kts` بواسطة Tree-sitter Kotlin: لا أخطاء صياغة. هذا لا يفحص أنواع Kotlin أو APIs المكتبات.
- فحص XML و`git diff --check` ضمن التحقق النهائي.
- لا تتوفر Java/Android SDK محليًا، والاتصال بخوادم اعتماديات Android مقيد؛ **لم أؤكد نجاح assembleDebug للتطبيقين**. البناء النهائي ورفع APK لدى الوكيل 0.

### تسليم للمنسق
- لا تعديلات جديدة على workflow أو scripts في مهمة المراجعة الحالية. تعديلات CI السابقة موجودة في تاريخ الفرع من التكليف السابق.
- الرجاء بناء `:app:assembleDebug` من مجلد كل تطبيق على حدة، وليس من جذر المستودع.
- ملاحظات الأمان والوظائف المتبقية موثقة في `TEAM_COLLABORATION.md` ولا ينبغي اعتبار اجتياز البناء دليل جاهزية إنتاجية.

---

### تحديث الوكيل 1 للمنسق — إعادة فحص الفرع المطلوب

**المرجع المفحوص:** `arena/6b69a15d-tammtool` عند `e0cdea0947a553918d75726986d6b8e06a46c99a` (2026-11-06).

**النتيجة المهمة:** إصلاحات الوكيل 1 لم تُدمج بعد في الفرع المفحوص؛ ما زالت ملفات Gradle هناك تحتوي العوائق التالية في التطبيقين، لذلك تكرار البناء دون دمج الإصلاحات سيعيد الفشل:

| العائق | التصحيح المطلوب |
|---|---|
| `tasks.register("clean", Delete)` صيغة Groovy داخل Kotlin DSL | `tasks.register<Delete>("clean") { delete(layout.buildDirectory) }` |
| Kotlin `1.9.20` مع Compose Compiler `1.5.8` | Compiler 1.5.8 يتطلب Kotlin 1.9.22؛ تحديث Kotlin Android وkapt وserialization جميعًا إلى 1.9.22 |
| استخدام `kapt(...)` دون تطبيق إضافة kapt | تطبيق `org.jetbrains.kotlin.kapt` بنفس إصدار Kotlin |
| Java تستهدف 1.8 بينما Kotlin تستهدف 17 | توحيد sourceCompatibility وtargetCompatibility وjvmTarget على 17 |
| `allprojects.repositories` مع `FAIL_ON_PROJECT_REPOS` في settings | حذف مستودعات allprojects والاعتماد على settings |
| Hilt موجود في buildscript ثم يطلب مجددًا برقم إصدار داخل app | تعريف نسخ الإضافات مركزيًا في plugins الجذري بـapply false وتطبيقها بلا نسخ داخل app |
| `compileSdk=35` مع AGP 8.2.0 القديم | المجموعة المقترحة والمطبقة في فرعي: AGP 8.6.1 وGradle 8.7 وJDK 17 |
| الشاشات تستورد material3 بينما الاعتماديات تحتوي material فقط | إضافة `androidx.compose.material3:material3:1.2.1`؛ وتطبيق إصلاحات APIs والاستيرادات المصدرية |

**أسباب فشل ثبتت بالفعل من تشغيلات سابقة على فرعي** (ليست تخمينًا ولا تأكيدًا لسبب أحدث تشغيل للمنسق):
- التشغيل `42263460678`: رسالة `Classifier 'Delete' does not have a companion object` في Gradle الجذري؛ عولجت في `044eab8`.
- التشغيل `42263693959`: `plugin is already on the classpath with an unknown version`؛ عولجت بنقل نسخ الإضافات إلى plugins الجذري في `cf7e5cd`.
- التشغيل `42263987317`: `res/values/ic_launcher_web.png.placeholder: The file name must end with .xml`؛ عولج في `6d308f6` لتطبيق marketer، وفي `20f89b8` للتطبيق الرئيسي.
- أمكن قراءة رسائل الأخطاء عبر Checks annotations رغم تعذر تنزيل logs؛ مثال للمنسق: `gh api repos/22kdx/TAMMTOOL/check-runs/128049132848/annotations --jq '.[].message'`. إذا لم توجد annotations في تشغيل آخر، فهذا لا يعني أن البناء نجح.

**التسليم:** النسخ المصححة للتطبيقين واختبارات المصدر متاحة على `arena/ff5110e8-tammtool` في الالتزام `20f89b8` وأسلافه. هذا الالتزام وحده لا يحتوي كل إصلاحات marketer السابقة، لذلك لا يكفي cherry-pick له منفردًا. يرجى دمج/مقارنة ملفات `apps/marketer` و`apps/orders-delivery` من ذلك المرجع، مع الإبقاء على workflow الخاص بالمنسق. لا أعدل فرع المنسق أو CI أو السكريبتات في هذا التكليف.

**التحقق:** المراجعة المصدرية مكتملة؛ اختبار التجميع الكامل للتطبيقين ما زال مطلوبًا من الوكيل 0. لا يوجد ادعاء بأن APK النهائي ناجح أو أن التطبيقين مكتملان وظيفيًا.

---

## الوكيل 2 — الأدوات والسكريبتات

**الحالة:** قيد الانتظار ⏳

**المهام:**
| المهمة | الحالة | الملاحظات |
|--------|--------|-----------|
| تحسين build-apk.sh | pending ⏳ | |
| تحسين apk-test.sh | pending ⏳ | |
| تحسين android-sdk-setup.sh | pending ⏳ | |
| اختبار محلي | pending ⏳ | |

**آخر تحديث:** لم يبدأ بعد

---

## الوكيل 3 — التوثيق والتقارير

**الحالة:** قيد الانتظار ⏳

**المهام:**
| المهمة | الحالة | الملاحظات |
|--------|--------|-----------|
| توثيق حالة CI | pending ⏳ | |
| تقرير الأخطاء الشامل | pending ⏳ | |
| ملفات النشر لـ Play Store | pending ⏳ | |

**آخر تحديث:** لم يبدأ بعد

---

## ملاحظات المنسق (الوكيل 0)

- بناء CI يفشل في خطوة `gradle :app:assembleDebug`
- لا نستطيع قراءة سجلات خطأ البناء عبر API (قيود SSL في بيئة المحجوزة)
- يتم كتابة سجلات البناء إلى `ci-build.log` ودفعها إلى الفرع
- الملف `push-test.txt` تأكد أن `git push` يعمل بشكل صحيح من CI

**آخر تاريخ تحديث:** 2026-11-06
