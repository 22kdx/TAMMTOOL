# تطبيق إدارة الطلبات والمناديب (Orders & Delivery Management App)

تطبيق أندرويد احترافي لإدارة طلبات العملاء، المناديب، المخزون، والعمولات، مبني وفقًا لـ **خريطة عملية التطبيق (Process Plan)** المرفقة.

## نظرة عامة على التطبيق

يهدف التطبيق إلى إدارة دورة حياة الطلب بالكامل من إنشاء الطلب إلى التسليم والتسوية المالية، مع دعم أدوار متعددة وصلاحيات دقيقة لكل مستخدم.

## الأدوار والصلاحيات (بناءً على خريطة العملية)

| الدور | الصلاحيات |
|-------|-----------|
| **مدير النظام** | كامل الوصول لكل البيانات، الإعدادات، الصلاحيات، المخزون، الحسابات المالية، التقارير، سجل التدقيق |
| **الإدارة** | جميع الطلبات، الأداء، العمولات، التقارير المالية، إدارة صلاحيات المستخدمين وحذف البيانات |
| **مسؤول الطلبات** | جميع الطلبات عبر المحافظات، بيانات المناديب والمسوقين، العمولات، الموافقات (إلغاء/تعديل سعر/كمية)، موافقة إنهاء العهدة |
| **المسوق** | طلباته فقط، عمولته وكشف حسابه، تنبيهات طلباته |
| **مندوب محافظة** | يحمل مخزونًا مخصومًا من المخزون الرئيسي، يبيع ويسلم، يُخصم من مخزونه عند التسليم، طلبات مسندة إليه فقط |
| **مندوب توصيل** | عهدة مؤقتة، توصيل فقط، يسجل عليه مبلغ الطلب وعمولته كما للمندوب، إذا أُلغي الطلب يبقى المنتج في سجله حتى إخلاء العهدة |
| **العميل** | حالة طلبه فقط، موعد التسليم، إمكانية تأكيد/تعديل محدودة، لا بيانات داخلية أو مالية |

## دورة حياة الطلب (حالات الطلب)

```
معلق ← قيد التواصل ← تم اعتماد المندوب للطلب ← انتظار موافقة على سعر أو كمية ←
   ↳ تم التسليم ← مكتمل وتسوية مالية
   ↳ مؤجل / ملغي
```

كل تغيير حالة يجب أن يُسجل معه: من غيّرها، وقت التغيير، والسبب/ملاحظة.

## الميزات الأساسية (المطبقة في النسخة الأولى)

1. **سجل تدقيق (Audit Log)** لكل تغيير (حالة / سعر / عمولة) ومن قام به ومتى
2. **إشعارات ثلاثية القنوات**: داخل التطبيق + واتساب + SMS لكل الأطراف المعنية
3. **إغلاق يومي وكشف تحصيل لكل مندوب** (عهدة + نقد + طلبات)
4. **نسخة احتياطية دورية** مع إمكانية الاسترجاع
5. **مرتجعات واستبدال** مع تأثيرها على المخزون والعمولات
6. **إدارة الهدايا كمخزون مستقل** مع حد أدنى
7. **إدارة الشكاوى والمتابعة**
8. **تعدد الفروع/المستودعات**
9. **تصدير فواتير Excel/PDF**

## الميزات المتوقعة (مراحل لاحقة)

تقييم المندوب، رابط تتبع للعميل، حد ائتماني، أسعار مختلفة للمحافظات وكوبونات، تطبيق أوفلاين، صلاحيات خاصة وموافقات متعددة المستويات، سجل المكالمات، نظام GPS، خريطة، رمز QR/باركود، حالية/مؤجل/مستقبل.

## структура المشروع (النظام التقني)

```
apps/orders-delivery/
├── build.gradle.kts                 # إعدادات المشروع (Gradle)
├── settings.gradle.kts              # تعريف الوحدات
├── gradle.properties                # خصائصgradle
├── app/
│   ├── build.gradle.kts             # إعدادات التطبيق والتبعيات
│   ├── proguard-rules.pro           # قواعد تصغير الشيفرة
│   ├── src/main/
│   │   ├── AndroidManifest.xml      # بيان التطبيق والأذونات
│   │   ├── java/com/tammtool/ordersapp/
│   │   │   ├── di/                  # حقن التبعيات (Hilt)
│   │   │   │   ├── OrdersApp.kt     # فئة التطبيق الرئيسية
│   │   │   │   ├── DatabaseModule.kt
│   │   │   │   └── RepositoryModule.kt
│   │   │   ├── data/
│   │   │   │   ├── local/           # طبقة البيانات المحلية (Room)
│   │   │   │   │   ├── AppDatabase.kt
│   │   │   │   │   ├── *Dao.kt      # واجهات الوصول للبيانات
│   │   │   │   │   └── ...
│   │   │   │   ├── model/           # نماذج البيانات (Entities)
│   │   │   │   │   ├── User.kt, Order.kt, Product.kt, ...
│   │   │   │   │   ├── InventoryMovement.kt, Mission.kt, Commission.kt
│   │   │   │   │   ├── FinancialTransaction.kt, AuditLog.kt, Notification.kt
│   │   │   │   │   ├── Governorate.kt, Branch.kt
│   │   │   │   └── repository/      # مستودعات البيانات
│   │   │   │       ├── UserRepository.kt, OrderRepository.kt, ...
│   │   │   ├── ui/
│   │   │   │   ├── MainActivity.kt  # النشاط الرئيسي
│   │   │   │   ├── nav/             # التنقل (Navigation)
│   │   │   │   │   └── AppNavGraph.kt
│   │   │   │   ├── screens/         # شاشات التطبيق
│   │   │   │   │   ├── LoginScreen.kt
│   │   │   │   │   ├── DashboardScreen.kt
│   │   │   │   │   ├── OrderListScreen.kt
│   │   │   │   │   ├── CreateOrderScreen.kt
│   │   │   │   │   ├── OrderDetailScreen.kt
│   │   │   │   │   ├── UserManagementScreen.kt
│   │   │   │   │   ├── ProductManagementScreen.kt
│   │   │   │   │   ├── InventoryScreen.kt
│   │   │   │   │   ├── MissionScreen.kt
│   │   │   │   │   ├── CommissionScreen.kt
│   │   │   │   │   ├── FinancialScreen.kt
│   │   │   │   │   ├── NotificationScreen.kt
│   │   │   │   │   └── ProfileScreen.kt
│   │   │   │   ├── theme/           # الثيم والتصميم (Material 3)
│   │   │   │   │   └── Theme.kt
│   │   │   │   └── viewmodel/       # نماذج العرض (ViewModels)
│   │   │   │       ├── AuthViewModel.kt, OrderViewModel.kt, ...
│   │   │   │       └── ...
│   │   │   └── res/                 # الموارد (نصوص، ألوان، ثيم، أيقونات)
│   │   │       ├── values/strings.xml
│   │   │       ├── values-ar/strings.xml (دعم اللغة العربية RTL)
│   │   │       ├── values/colors.xml
│   │   │       ├── values/themes.xml
│   │   │       ├── drawable/
│   │   │       └── mipmap-*/
│   └── ...
```

## التقنيات المستخدمة

- **اللغة:** Kotlin 1.9.20
- **واجهة المستخدم:** Jetpack Compose + Material 3
- **حقن التبعيات:** Hilt 2.50
- **قاعدة البيانات:** Room 2.6.1 (محلية)
- **المكونات:** AndroidX Core, AppCompat, Material, Navigation Compose, Lifecycle, Coroutines
- **التSerialization:** kotlinx-serialization-json
- **تحميل الصور:** Coil
- **السجلات:** Timber
- **نظام التشغيل الأدنى:** Android API 24 (Android 7.0)
- **نظام التشغيل المستهدف:** Android API 35

## كيفية بناء تطبيق APK

### المتطلبات الأساسية
1. Java Development Kit (JDK) 17 أو أحدث
2. Android Studio (أحدث إصدار)
3. Android SDK Platform-Tools و Build-Tools
4. متغير البيئة `ANDROID_HOME` مضبط

### خطوات البناء

```bash
# 1. الانتقال إلى مجلد التطبيق
cd apps/orders-delivery

# 2. فحص البيئة (إذا كانت أدوات TAMMTOOL مثبتة)
bash ../../scripts/check-env.sh

# 3. مزامنة المشروع مع Gradle (في Android Studio: Sync Now)
./gradlew androidDependencies

# 4. بناء نسخة تصحيح (Debug APK)
./gradlew assembleDebug

# 5. بناء نسخة إصدار (Release APK) - يتطلب توقيع
./gradlew assembleRelease

# 6. بناء حزمة Android App Bundle (AAB) للنشر على Google Play
./gradlew bundleRelease
```

### مسارات الملفات الناتجة

| نوع البناء | المسار |
|-----------|--------|
| Debug APK | `app/build/outputs/apk/debug/app-debug.apk` |
| Release APK (unsigned) | `app/build/outputs/apk/release/app-release-unsigned.apk` |
| Release APK (signed) | `app/build/outputs/apk/release/app-release.apk` |
| Android App Bundle (AAB) | `app/build/outputs/bundle/release/app-release.aab` |

### توقيع APK

راجع دليل التوقيع في: `../../docs/workflow-sign-apk.md`

```bash
bash ../../scripts/sign-apk.sh \
  app/build/outputs/apk/release/app-release-unsigned.apk \
  ../../keystore/release-keystore.jks \
  release-key \
  app/build/outputs/apk/release/app-release.apk
```

## خريطة العملية المرجعية

جميع المنطق التجاري في هذا التطبيق مبني وفقًا لـ `خريطة_عملية_التطبيق.pdf` المرفقة، والتي تشمل:
- دورة حياة الطلب وحالاته
- فروع التواصل مع العملاء (5 فروع)
- التسوية المالية وحساب العمولات
- قواعد الصلاحيات والرؤية لكل دور
- سجل التدقيق والإشعارات

## النشر على متجر Google Play

راجع دليل النشر في: `../../docs/workflow-publish-play-store.md`

## ملاحظات أمنية

- لا ترفع ملف keystore أو كلمات المرور إلى مستودع Git
- استخدم متغيرات البيئة لأسرار البناء (CI/CD Secrets)
- تم تطبيق تصغير الشيفرة (Minify) في نسخة الإصدار عبر ProGuard/R8
- جميع التغييرات على البيانات تسجل في سجل التدقيق (Audit Log)

---

تطبيق إدارة الطلبات والمناديب — جزء من مستودع TAMMTOOL لبناء تطبيقات APK احترافية.
