# حالة الوكلاء

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
