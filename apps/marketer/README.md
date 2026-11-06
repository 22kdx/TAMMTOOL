# تطبيق المسوق (Marketer App)

تطبيق أندرويد منفصل ومخصص حصرياً لدور **المسوق** في نظام إدارة الطلبات والمناديب. هذا التطبيق مبني على نفس إطار TAMMTOOL ولكن مع واجهات مبسطة تلبي احتياجات المسوق فقط.

## نظرة عامة على التطبيق

تطبيق المسوق يسمح للمسوق بإدارة عملياته اليومية بشكل مستقل، بما في ذلك:
- إنشاء طلبات جديدة للعملاء
- عرض طلباته وحالاتها
- مراقبة عمولاته والمستحق والمدفوع
- مراجعة الإشعارات والتنبيهات
- إدارة ملفه الشخصي وبياناته

## الأدوار المدعومة

هذا التطبيق مخصص حصرياً لدور **المسوق (Marketer)** فقط.

## الميزات الأساسية

| الميزة | الوصف |
|--------|-------|
| **تسجيل الدخول** | دخول المسوق برقم الهاتف وكلمة المرور |
| **لوحة التحكم** | بطاقات إجراءات سريعة للوصول لكل وظائف التطبيق |
| **طلباتي** | عرض جميع طلبات المسوق مع حالاتها وعمولتها |
| **طلب جديد** | إنشاء طلب عميل جديد بجميع البيانات المطلوبة |
| **تفاصيل الطلب** | عرض تفاصيل طلب محدد مع جميع بياناته |
| **عمولاتي** | عرض ملخص العمولات (المستحق، المدفوع) وسجل العمولات |
| **إشعاراتي** | مراجعة الإشعارات والتنبيهات المرسلة للمسوق |
| **ملفي الشخصي** | عرض بيانات المسوق ورصيده وسقف دينه ونسبة عمولته |

## دورة حياة الطلب في تطبيق المسوق

```
معلق ← قيد التواصل ← تم اعتماد المندوب ← انتظار موافقة على سعر/كمية ←
   ↳ تم التسليم ← مكتمل
   ↳ مؤجل / ملغي
```

## البيانات التي يمكن للمسوق إدخاليها عند إنشاء طلب

- اسم العميل
- رقم هاتف العميل
- المحافظة
- العنوان التفصيلي أو رابط الموقع
- رابط الموقع (اختياري)
- المنتج
- الكمية
- الهدية (اختياري)
- كمية الهدية
- السعر المتفق عليه
- تاريخ ووقت التسليم المطلوب

## структура المشروع

```
apps/marketer/
├── build.gradle.kts                 # إعدادات المشروع (Gradle)
├── settings.gradle.kts              # تعريف الوحدات
├── gradle.properties                # خصائص Gradle
├── app/
│   ├── build.gradle.kts             # إعدادات التطبيق والتبعيات
│   ├── proguard-rules.pro           # قواعد تصغير الشيفرة
│   ├── src/main/
│   │   ├── AndroidManifest.xml      # بيان التطبيق والأذونات
│   │   ├── java/com/tammtool/marketerapp/
│   │   │   ├── di/                  # حقن التبعيات (Hilt)
│   │   │   │   ├── MarketerApp.kt   # فئة التطبيق الرئيسية
│   │   │   │   ├── DatabaseModule.kt
│   │   │   │   └── RepositoryModule.kt
│   │   │   ├── data/
│   │   │   │   ├── local/           # طبقة البيانات المحلية (Room)
│   │   │   │   │   ├── AppDatabase.kt
│   │   │   │   │   ├── MarketerUserDao.kt
│   │   │   │   │   ├── MarketerOrderDao.kt
│   │   │   │   │   ├── MarketerCommissionDao.kt
│   │   │   │   │   ├── MarketerNotificationDao.kt
│   │   │   │   │   └── AuditLogDao.kt
│   │   │   │   ├── model/           # نماذج البيانات (Entities)
│   │   │   │   │   ├── MarketerUser.kt
│   │   │   │   │   ├── MarketerOrder.kt
│   │   │   │   │   ├── MarketerCommission.kt
│   │   │   │   │   ├── MarketerNotification.kt
│   │   │   │   │   └── AuditLog.kt
│   │   │   │   └── repository/      # مستودعات البيانات
│   │   │   │       ├── MarketerUserRepository.kt
│   │   │   │       ├── MarketerOrderRepository.kt
│   │   │   │       ├── MarketerCommissionRepository.kt
│   │   │   │       ├── MarketerNotificationRepository.kt
│   │   │   │       └── AuditRepository.kt
│   │   │   ├── ui/
│   │   │   │   ├── MainActivity.kt  # النشاط الرئيسي
│   │   │   │   ├── nav/             # التنقل (Navigation)
│   │   │   │   │   └── AppNavGraph.kt
│   │   │   │   ├── screens/         # شاشات التطبيق (8 شاشات)
│   │   │   │   │   ├── LoginScreen.kt
│   │   │   │   │   ├── DashboardScreen.kt
│   │   │   │   │   ├── MyOrdersScreen.kt
│   │   │   │   │   ├── CreateOrderScreen.kt
│   │   │   │   │   ├── OrderDetailScreen.kt
│   │   │   │   │   ├── MyCommissionsScreen.kt
│   │   │   │   │   ├── MyNotificationsScreen.kt
│   │   │   │   │   └── ProfileScreen.kt
│   │   │   │   ├── theme/           # الثيم والتصميم (Material 3)
│   │   │   │   │   └── Theme.kt
│   │   │   │   └── viewmodel/       # نماذج العرض (ViewModels)
│   │   │   │       ├── AuthViewModel.kt
│   │   │   │       ├── OrderViewModel.kt
│   │   │   │       ├── CommissionViewModel.kt
│   │   │   │       ├── NotificationViewModel.kt
│   │   │   │       └── UserViewModel.kt
│   │   │   └── res/                 # الموارد (نصوص، ألوان، ثيم، أيقونات)
│   │   │       ├── values/strings.xml
│   │   │       ├── values-ar/strings.xml (دعم اللغة العربية RTL)
│   │   │       ├── values/colors.xml
│   │   │       ├── values/themes.xml
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

## كيفية بناء تطبيق APK للمسوق

### المتطلبات الأساسية
1. Java Development Kit (JDK) 17 أو أحدث
2. Android Studio (أحدث إصدار)
3. Android SDK Platform-Tools و Build-Tools
4. متغير البيئة `ANDROID_HOME` مضبط

### خطوات البناء

```bash
# 1. الانتقال إلى مجلد تطبيق المسوق
cd apps/marketer

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

## الفرق بين تطبيق المسوق وتطبيق إدارة الطلبات والمناديب

| الميزة | تطبيق المسوق (منفصل) | تطبيق إدارة الطلبات والمناديب (الكامل) |
|--------|----------------------|--------------------------------------|
| الجمهور المستهدف | المسوق فقط | جميع الأدوار (مدير، إدارة، مسؤول طلبات، مسوق، مندوب، عميل) |
| عدد الشاشات | 8 شاشة | 14 شاشة |
| إدارة المستخدمين | غير متاح | متاح |
| إدارة المنتجات | غير متاح | متاح |
| إدارة المخزون | غير متاح | متاح |
| إدارة العهديات | غير متاح | متاح |
| المحفظات المالية | غير متاح | متاح |
| إنشاء طلبات | متاح | متاح |
| عرض طلباته | متاح | متاح |
| عرض عمولاته | متاح | متاح |
| عرض إشعاراته | متاح | متاح |
| ملفه الشخصي | متاح | متاح |

## النشر على متجر Google Play

راجع دليل النشر في: `../../docs/workflow-publish-play-store.md`

## ملاحظات أمنية

- لا ترفع ملف keystore أو كلمات المرور إلى مستودع Git
- استخدم متغيرات البيئة لأسرار البناء (CI/CD Secrets)
- تم تطبيق تصغير الشيفرة (Minify) في نسخة الإصدار عبر ProGuard/R8
- جميع التغييرات على البيانات تسجل في سجل التدقيق (Audit Log)

---

تطبيق المسوق — جزء من مستودع TAMMTOOL لبناء تطبيقات APK احترافية.
