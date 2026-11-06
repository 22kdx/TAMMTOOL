# إضافات Visual Studio Code (VS Code Extensions)

هذه الصفحة توثق جميع الإضافات والكماليات لمحرر Visual Studio Code التي تُستخدم في تطوير تطبيقات Android APK، سواء لتعديل الشيفرة، تشغيل Gradle، أو التصحيح عبر ADB.

## كيفية التثبيت

1. افتح VS Code
2. اذهب إلى علامة تبويب **Extensions** (الرمز المكون من أربع مربعات في الشريط الجانبي، أو اضغط `Ctrl+Shift+X`)
3. ابحث عن اسم الإضافة في شريط البحث
4. انقر **Install**

## 1. إضافات Java و Kotlin (الم Sprachen الأساسية)

| الإضافة | معرف الإضافة (Extension ID) | الغرض |
|--------|---------------------------|-------|
| Extension Pack for Java | `vscjava.vscode-java-pack` | حزمة شاملة لتطوير Java في VS Code |
| Kotlin Language | `mathiasfrohlich.kotlin` | دعم لغة Kotlin (صياغة، تمييز، إكمال تلقائي) |
| Kotlin | `fwcd.kotlin` | بديل آخر لدعم Kotlin مع دعم IntelliJ-like |
| Java Debugger | `vscjava.vscode-java-debug` | تصحيح شيفرة Java/Kotlin |
| Java Test Runner | `vscjava.vscode-java-test` | تشغيل اختبارات JUnit من داخل VS Code |
| Maven for Java | `vscjava.vscode-maven` | إدارة مشاريع Maven |
| Gradle for Java | `vscjava.vscode-gradle` | تشغيل مهام Gradle من داخل VS Code |

## 2. إضافات Android speziيَّة

| الإضافة | معرف الإضافة | الغرض |
|--------|-------------|-------|
| Android | `android.android` | أدوات مساعدة لمشاريع Android (ADB، بناء، تشغيل) |
| Android Studio Keymap | `ms-android.android-studio` | 적용 اختصارات Android Studio في VS Code |
| ADB | `melvyn-dominguez.adb` | أوامر ADB من لوحة الأوامر (Command Palette) |
| Android Resource Cleaner | `ricardodeaz.android-resource-cleaner` | تنظيف الموارد غير المستخدمة في مشروع Android |

## 3. إضافات تنسيق الشيفرة والجودة (Formatting & Linting)

| الإضافة | معرف الإضافة | الغرض |
|--------|-------------|-------|
| Prettier | `esbenp.prettier` | تنسيق شيفرة Kotlin/Java/XML/JSON |
| EditorConfig | `editorconfig.editorconfig` | تطبيق إعدادات التنسيق من ملف `.editorconfig` |
| ESLint | `dbaeumer.vscode-eslint` | فحص شيفرة JavaScript/TypeScript (إذا كان المشروع يحتوي على ويب فيو) |
| SonarLint | `sonarsource.sonarlint-vscode` | اكتشاف العيوب والثغرات في الشيفرة في الوقت الحقيقي |
| Better Comments | `aaron-bond.better-comments` | تمييز التعليقات (TODO, FIX, WARNING, !, ?) بألوان مختلفة |

## 4. إضافات قواعد البيانات و API

| الإضافة | معرف الإضافة | الغرض |
|--------|-------------|-------|
| REST Client | `humao.rest-client` | إرسال طلبات HTTP وعرض الاستجابات من داخل VS Code |
| Thunder Client | `rangav.vscode-thunder-client` | بديل خفيف لـ Postman لاختبار واجهات API |
| JSON | `vscode.json` | دعم ملفات JSON مع التحقق من الصحة |
| XML | `redhat.vscode-xml` | دعم ملفات XML (ملفات Android Manifest, Layouts) |
| Database Client | `mtxr.sqltools` | الاتصال بقواعد بيانات SQLite و Room للاستعراض والتعديل |

## 5. إضافات التصميم وواجهات المستخدم (UI/UX)

| الإضافة | معرف الإضافة | الغرض |
|--------|-------------|-------|
| Material Icon Theme | `pkief.material-icon-theme` | أيقونات مميزة لأنواع الملفات في الشريط الجانبي |
| vscode-icons | `vscode-icons-team.vscode-icons` | أيقونات ملونة لملفات المشاريع |
| Bracket Pair Colorizer | `coenraads.bracket-pair-colorizer` | تمييز الأقواس المتطابقة بألوان مختلفة لتسهيل قراءة الشيفرة |
| Indent Rainbow | `oderwat.indent-rainbow` | تمييز المسافات البادئة (indentation) بألوان |

## 6. إضافات Git والتحكم في الإصدار (Git & Version Control)

| الإضافة | معرف الإضافة | الغرض |
|--------|-------------|-------|
| GitLens | `eamodio.gitlens` | عرض تاريخ الشيفرة ومن كتب كل سطر (Git blame) داخل المحرر |
| Git Graph | `mhutchie.git-graph` | عرض مخطط بياني لفروع والتاريخ في Git |
| GitHub Pull Requests | `github.vscode-pull-request-github` | إدارة طلبات السحب (Pull Requests) من داخل VS Code |
| GitHub Repositories | `github.vscode-github-repositories` | استكشاف مستودعات GitHub وتعديلها مباشرة |

## 7. إضافات النشر والنشر التلقائي (Deployment)

| الإضافة | معرف الإضافة | الغرض |
|--------|-------------|-------|
| Firebase Tools | `firebase.firebase-tools` | إدارة مشاريع Firebase من داخل VS Code |
| Google Cloud Code | `googlecloudtools.cloudcode` | نشر التطبيقات على Google Cloud و Play Console |
| Azure App Service | `ms-azuretools.vscode-azureappservice` | النشر على Microsoft Azure (اختياري) |

## 8. مثال على إعدادات VS Code لمشروع Android (`settings.json`)

يمكنك إنشاء ملف `.vscode/settings.json` في جذر المشروع:

```json
{
    "editor.formatOnSave": true,
    "editor.defaultFormatter": "esbenp.prettier",
    "editor.codeActionsOnSave": {
        "source.organizeImports": true
    },
    "files.associations": {
        "*.gradle.kts": "kotlin",
        "*.kts": "kotlin"
    },
    "java.configuration.updateBuildConfiguration": "automatic",
    "java.import.exclusions": [
        "**/.gradle/**",
        "**/build/**"
    ],
    "kotlin.compile.onSave": false,
    "[kotlin]": {
        "editor.defaultFormatter": "mathiasfrohlich.kotlin"
    }
}
```

## 9. أوامر لوحة الأوامر (Command Palette) المفيدة

بعد تثبيت إضافات Android و Gradle، يمكنك استخدام لوحة الأوامر (`Ctrl+Shift+P`):

- `Android: Run ADB Devices` — عرض الأجهزة المتصلة
- `Gradle: Refresh Gradle Projects` — إعادة مزامنة مشاريع Gradle
- `Gradle: Tasks` — عرض جميع مهام Gradle المتاحة
- `Java: Clean Java Language Server Workspace` — تنظيف مساحة عمل Java
- `REST Client: Send Request` — إرسال طلب HTTP من ملف `.http`

## 10. التوصية النهائية

إذا كنت تفضل بيئة تطوير خفيفة وسريعة، فإن VS Code مع الإضافات التالية يكفي لمشاريع Android متوسطة:

1. **Extension Pack for Java**
2. **Kotlin Language**
3. **Gradle for Java**
4. **Android**
5. **REST Client** أو **Thunder Client**
6. **Prettier** + **EditorConfig**
7. **SonarLint**
8. **GitLens**

للعمل على مشاريع Android كبيرة ومعقدة، يُفضل استخدام **Android Studio** لأنه يحتوي على أدوات مدمجة أكثر (Emulator, Layout Editor, Profiler, ...).

---

بعد مراجعة هذا الملف، يمكنك الانتقال إلى [إضافات Fastlane](../fasteane/README.md) لأتمتة البناء والنشر، أو [أدوات سطر الأوامر](../cli/README.md) للعمل من terminal.