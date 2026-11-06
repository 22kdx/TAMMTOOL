# إضافات Android Studio / IntelliJ IDEA (Android Studio Plugins)

هذه الصفحة توثق جميع الإضافات والكماليات التي تُثبت في بيئة التطوير Android Studio (أو IntelliJ IDEA) لتسريع تطوير تطبيقات APK وتحسين جودتها.

## كيفية التثبيت

في Android Studio:
1. اذهب إلى `File → Settings → Plugins` (أو `Android Studio → Settings → Plugins` على macOS)
2. اختر علامة تبويب **Marketplace**
3. ابحث عن اسم الإضافة
4. انقر **Install** ثم أعد تشغيل Android Studio

أو قم بتثبيت الإضافات من خلال ملف إعدادات IDE إذا كان متاحاً.

## 1. إضافات لغات البرمجة (Language Plugins)

| الإضافة | الغرض | الحالة |
|--------|-------|--------|
| Kotlin | دعم لغة Kotlin (بناء، تصحيح، إكمال تلقائي) | مدمج افتراضياً |
| Java | دعم لغة Java (مدمج) | مدمج |
| C/C++ | دعم تطوير الشيفرة الأصلية (NDK, CMake) | مدمج / قابل للتثبيت |
| Flutter | تطوير تطبيقات Flutter (إذا تم استخدامه مع Android) | बाहरी |
| Dart | لغة Dart (للدمج مع Flutter) | बाहरी |
| Python / Scala / Groovy | للغات إضافية في IntelliJ | اختياري |

## 2. إضافات Firebase و Google

| الإضافة | الغرض |
|--------|-------|
| Firebase Assistant | ربط المشروع بمشروع Firebase، إضافة الخدمات (تحليلات، Crashlytics، مصادقة، ...) من داخل IDE |
| Google Play Instant | تطوير تطبيقات فورية (Instant Apps) على Google Play |
| Google Play Services | أدوات مساعدة لخدمات جوجل 플레이 |

## 3. إضافات الإنتاجية والتنقل (Productivity & Navigation)

| الإضافة | الغرض |
|--------|-------|
| CodeGlance | عرض خريطة مصغرة للشيفرة في الشريط الأيمن لتسهيل التنقل |
| Key Promoter X | تعلم اختصارات لوحة المفاتيح واقتراح اختصارات بدلاً من استخدام الماوس |
| Android WiFi ADB | ربط جهاز Android عبر WiFi بدلاً من كابل USB للتصحيح والنشر |
| ADB Wifi | بديل لـ Android WiFi ADB للاتصال اللاسلكي |
| Code With Me | البرمجة التعاونية عن بُعد مع فريق التطوير (IntelliJ) |
| Presentation Assistant | عرض اختصارات لوحة المفاتيح أثناء العروض التقديمية |

## 4. إضافات توليد الشيفرة والقوالب (Code Generation & Templates)

| الإضافة | الغرض |
|--------|-------|
| JSON to Kotlin Class | تحويل استجابات JSON إلى كلاسات Kotlin Data Classes تلقائياً |
| JSON to Java Class | تحويل JSON إلى كلاسات Java |
| GsonFormat | توليد كلاسات من JSON لاستخدامها مع مكتبة Gson |
| RoboPOJO Generator | توليد كلاسات بيانات (POJO) من JSON مع دعم Gson/Moshi |
| Parcelable Generator | توليد أكواد Parcelable لكائنات البيانات تلقائياً |
| Lombok | تقليص الشيفرة المتكررة في Java (getters, setters, constructors) |
| Imort Kotlin Class | استيراد فئات Kotlin بسهولة من مكتبات خارجية |

## 5. إضافات الجودة والتحليل (Code Quality & Analysis)

| الإضافة | الغرض |
|--------|-------|
| SonarLint | اكتشاف العيوب والثغرات ورائحة الشيفرة (code smells) في الوقت الحقيقي |
| CheckStyle-IDEA | فحص شيفرة Java وفقاً لمعايير Checkstyle |
| FindBugs-IDEA | اكتشاف الأخطاء المحتملة في شيفرة Java |
| Structure101 | تحليل بنية المشروع والتبعيات المعقدة |
| Dependency Analysis | تحليل التبعيات (dependencies) وتحديد التبعيات غير المستخدمة |
| SequenceDiagram | تحويل استدعاءات الدوال إلى مخططات تسلسل (Sequence Diagrams) للتوثيق |

## 6. إضافات التصميم وواجهة المستخدم (UI/UX Design)

| الإضافة | الغرض |
|--------|-------|
| Android Material Design Icon Generator | توليد أيقونات Material Design لمختلف دقعات الشاشة |
| Android Drawable Importer | استيراد وتحويل الصور إلى صيغ Drawable متعددة الدقة (ldpi, mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi) |
| SVG to VectorDrawable | تحويل ملفات SVG إلى VectorDrawable للاستخدام في Android |
| Layout Validator | التحقق من تخطيط الشاشات على أحجام شاشات متعددة في وقت واحد |
| Color Picker | اختيار الألوان من الشاشة أو من أكواد Hex وتحويلها إلى ألوان Android |
| Material Theme Editor | تعديل وتخصيص سمات Material Design للتطبيق |
| UI Preview | معاينة تخطيطات XML في الوقت الفعلي دون الحاجة لتشغيل المحاكي |

## 7. إضافات قواعد البيانات والـ API (Database & API)

| الإضافة | الغرض |
|--------|-------|
| Database Navigator | استعراض وتعديل قواعد بيانات SQLite و Room مباشرة من داخل IDE |
| JSON Viewer | عرض وتصحيح ملفات JSON |
| Postman | اختبار واجهات برمجة التطبيقات (API) من داخل IDE (إذا كانت متاحة كإضافة) |
| Rest Client | إرسال طلبات HTTP وعرض الاستجابات من داخل IDE |
| GraphQL | دعم استعلامات GraphQL وتوليد كلاسات Kotlin/Java منها |

## 8. إضافات التحكم في الإصدار والتعاون (Version Control & Collaboration)

| الإضافة | الغرض |
|--------|-------|
| GitLab / GitHub Integration | التكامل مع مستودعات GitHub/GitLab لعرض الطلبات (Pull Requests) والمشاكل (Issues) من داخل IDE |
| Pull Request Helper | إدارة طلبات السحب (Pull Requests) ومراجعة الشيفرة |
| Code With Me | البرمجة التعاونية عن بُعد |
| Eclipse Code Formatter | تطبيق تشكيلات الشيفرة من Eclipse على مشروع Android |

## 9. إضافات التصحيح والاختبار (Debugging & Testing)

| الإضافة | الغرض |
|--------|-------|
| Android Debug Bridge (ADB) | أدوات تصحيح مدمجة للاتصال بالأجهزة والمحاكيات |
| LeakCanary | اكتشاف تسرب الذاكرة (memory leaks) في التطبيقات |
| Stetho | أدوات تصحيح من Chrome DevTools للتطبيقات (قاعدة بيانات، network, shared preferences) |
| HTTP Inspector | فحص طلبات HTTP الصادرة والواردة من التطبيق أثناء التصحيح |
| Android View Client | استعراض عناصر واجهة المستخدم (View Hierarchy) في وقت التشغيل |

## 10. إضافات النشر والتوزيع (Publishing)

| الإضافة | الغرض |
|--------|-------|
| Google Play Publisher | النشر المباشر على Google Play Console من داخل IDE (إذا كانت مدعومة) |
| Firebase Plugin | ربط المشروع بـ Firebase وإدارة الإصدارات |

## 11. قائمة إضافية موصى بها للتطوير الاحترافي

للبدء السريع في تطوير تطبيقات APK احترافية، نوصي بتثبيت هذه الإضافات على الأقل:

1. **Kotlin** (مدمج)
2. **Firebase Assistant** — لربط الخدمات بسهولة
3. **JSON to Kotlin Class** — لتوليد كلاسات البيانات من واجهات API
4. **Android WiFi ADB** — للتصحيح اللاسلكي المريح
5. **CodeGlance** — للتنقل السريع في الشيفرة الطويلة
6. **Key Promoter X** — لتعلم اختصارات لوحة المفاتيح وتسريع العمل
7. **SonarLint** — لاكتشاف العيوب والثغرات في الوقت الحقيقي
8. **Material Design Icon Generator** — لتوليد الأيقونات حسب دقعات الشاشة
9. **SVG to VectorDrawable** — لاستخدام الأيقونات المتجهة (vectors) في التطبيق
10. **Database Navigator** — لإدارة قواعد بيانات Room/SQLite من داخل IDE

## 12. نصائح لإدارة الإضافات

- لا تثبت إضافات غير ضرورية كي لا تبطئ Android Studio.
- قم بتحديث الإضافات بانتظام عبر `Settings → Plugins → Updates`.
- إذا كانت الإضافة تسبب تعطل IDE، قم بإلغاء تفعيلها مؤقتاً من خلال `Settings → Plugins → Installed`.
- يمكن تصدير إعدادات الإضافات عبر `File → Manage IDE Settings → Export Settings` لمشاركتها مع الفريق.

---

بعد مراجعة هذا الملف، يمكنك الانتقال إلى [إضافات Visual Studio Code](../vscode/README.md) إذا كنت تستخدم المحرر الخفيف، أو [أدوات سطر الأوامر](../cli/README.md) لأتمتة المهام من terminal.