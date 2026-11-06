# TAMMTOOL

مجموعة شاملة من البرامج والأنظمة والإضافات (Plugins) المستخدمة في **بناء تطبيقات APK احترافية** لنظام Android.

## الغرض من المستودع

يهدف هذا المستودع إلى توثيق وتنظيم كل ما تحتاجه لعملية تطوير وبناء وتوقيع ونشر تطبيقات Android على شكل ملفات APK جاهزة للإنتاج، بدءًا من أدوات التطوير (IDE) وصولًا إلى أنظمة البناء (Build Systems) والإضافات (Plugins) وملفات scripts المساعدة.

## هيكل المستودع

```
TAMMTOOL/
├── README.md                 # هذا الملف - دليل البداية والنظرة العامة
├── programs/                 # البرامج والأدوات المطلوبة (IDE, JDK, SDK, ADB, ...)
│   └── README.md
├── systems/                  # أنظمة البناء والتشغيل والاختبار والنشر (CI/CD, Gradle, ...)
│   └── README.md
├── plugins/                  # الإضافات (Gradle, Android Studio, VS Code, Fastlane, ...)
│   └── README.md (+ 10 فئات فرعية)
├── docs/                     # توثيق ودوائر العمل (Workflows)
│   ├── workflow-build-apk.md
│   ├── workflow-sign-apk.md
│   └── workflow-publish-play-store.md
├── scripts/                  # سكريبتات مساعدة للبناء والتوقيع والفحص
│   ├── build-apk.sh
│   ├── sign-apk.sh
│   └── check-env.sh
├── templates/                # قوالب أولية لمشاريع Android
│   └── basic-app/
├── examples/                 # تطبيقات تجريبية للتجربة والتعلم
│   └── hello-world/
├── apps/                     # تطبيقات كاملة مبنية على هذا الإطار
│   └── orders-delivery/      # تطبيق إدارة الطلبات والمناديب (كامل)
│       ├── README.md         # توثيق التطبيق وخريطة العملية
│       └── app/              # كود تطبيق Android كامل (Kotlin + Compose + Hilt + Room)
└── .gitignore
```

## كيفية الاستخدام

1. راجع ملف `programs/README.md` لتثبيت البرامج الأساسية (Android Studio, JDK, Android SDK, ADB).
2. راجع ملف `systems/README.md` لاختيار نظام البناء والاختبار والنشر المناسب.
3. راجع ملف `plugins/README.md` لتفعيل الإضافات التي تسرع التطوير والجودة.
4. اتبع دوائر العمل في مجلد `docs/` لبناء APK، توقيعه، ونشره على متجر Google Play.
5. استخدم سكريبتات مجلد `scripts/` لأتمتة المهام المتكررة.
6. ابدأ من القالب في `templates/basic-app/` أو راجع الأمثلة في `examples/`.

## المتطلبات الأساسية

- نظام تشغيل: Windows 10/11، macOS، أو Linux (يُفضل Linux للمビルات الخفيفة).
- Java Development Kit (JDK) الإصدار 17 أو أحدث.
- Android Studio أحدث إصدار (يحتوي على Android SDK و Android Emulator و ADB).
- اتصال بالإنترنت لتحميل التبعيات (Dependencies) من Maven Central و Google Maven.
- حساب مطوّر على Google Play للنشر الرسمي (اختياري للاختبار المحلي).

## ملاحظة قانونية

تُستخدم الأدوات والمكتبات المذكورة وفق تراخيصها الأصلية. تأكد من مراجعة ترخيص كل أداة قبل استخدامها في مشاريع تجارية.

---

مستودع TAMMTOOL — جمع البرامج والأنظمة والإضافات لبناء تطبيقات APK احترافية.