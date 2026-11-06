# إضافات Fastlane (Fastlane Plugins & Actions)

Fastlane هي أداة أتمتة مفتوحة المصدر لبناء وتوقيع ونشر تطبيقات الجوال (iOS و Android). هذه الصفحة توثق الإضافات (plugins) والأجراءات (actions) المستخدمة لتطبيقات Android APK/AAB.

## ما هو Fastlane؟

Fastlane يُ automate المهام المتكررة في دورة حياة التطبيق:
- بناء ملفات APK و AAB عبر Gradle
- توقيع الملفات باستخدام keystore
- رفع النسخ إلى Google Play Console
- توزيع نسخ تجريبية عبر Firebase App Distribution
- إرسال إشعارات إلى فرق التطوير (Slack, Email, ...)

## التثبيت

```bash
# تثبيت Fastlane عبر RubyGems
sudo gem install fastlane

# أو عبر Homebrew (macOS)
brew install fastlane

# تهيئة Fastlane في المشروع
fastlane init
```

بعد التهيئة، سيتم إنشاء ملف `Fastfile` في مجلد `fastlane/`.

## 1. إجراءات Fastlane الأساسية (Built-in Actions)

| الإجراء (action) | الغرض | مثال الاستخدام |
|----------------|-------|--------------|
| `gradle` | تشغيل مهام Gradle (assembleRelease, bundleRelease, ...) | `gradle(task: "assemble", build_type: "Release")` |
| `signing` | توقيع ملف APK/AAB باستخدام keystore | `signing(apk_path: "...", signing_key: "...", key_id: "...", key_password: "...")` |
| `zipalign` | محاذاة ملف APK لتحسين الأداء | `zipalign(apk_path: "...")` |
| `apksigner` | توقيع APK باستخدام أداة apksigner | `apksigner(apk_path: "...", ks_path: "...", ks_alias: "...")` |
| `google_play` | رفع التطبيق إلى Google Play Console | `google_play(track: "internal", aab: "...")` |
| `firebase_app_distribution` | توزيع نسخ تجريبية عبر Firebase | `firebase_app_distribution(app: "...", groups: "testers")` |
| `supply` | رفع لقطات الشاشة والبيانات الوصفية إلى Google Play | `supply(apk: "...", track: "internal")` |
| `screengrab` | التقاط لقطات شاشة تلقائية للاختبارات | `screengrab` |
| `slack` | إرسال إشعارات إلى قناة Slack | `slack(message: "تم بناء الإصدار بنجاح!")` |
| `email` | إرسال بريد إلكتروني بإ_summary البناء | `email(subject: "Build Status", body: "...", to: "team@example.com")` |

## 2. إضافات Fastlane إضافية (Plugins)

| الإضافة | الغرض | 명령 التثبيت |
|--------|-------|-------------|
| `fastlane-plugin-gradle` | تحسين تكامل Gradle مع Fastlane | `fastlane add_plugin gradle` |
| `fastlane-plugin-firebase_app_distribution` | توزيع على Firebase App Distribution | `fastlane add_plugin firebase_app_distribution` |
| `fastlane-plugin-google_play_api` | التكامل مع Google Play Developer API | `fastlane add_plugin google_play_api` |
| `fastlane-plugin-version_android` | إدارة إصدار التطبيق (versionCode, versionName) تلقائياً | `fastlane add_plugin version_android` |
| `fastlane-plugin-changelog` | توليد سجل التغييرات (changelog) من Git commits | `fastlane add_plugin changelog` |
| `fastlane-plugin-slack` | إرسال إشعارات إلى Slack | `fastlane add_plugin slack` |
| `fastlane-plugin-hipchat` | إرسال إشعارات إلى HipChat/Slack | `fastlane add_plugin hipchat` |
| `fastlane-plugin-email` | إرسال إشعارات عبر البريد الإلكتروني | `fastlane add_plugin email` |
| `fastlane-plugin-build_number` | إدارة أرقام البناء تلقائياً | `fastlane add_plugin build_number` |

## 3. مثال على ملف Fastfile شامل

```ruby
# fastlane/Fastfile

default_platform(:android)

platform :android do
  desc "بناء نسخة debug للتطوير"
  lane :debug do
    gradle(
      task: "assemble",
      build_type: "Debug"
    )
  end

  desc "بناء نسخة release وتوقيعها"
  lane :release do
    gradle(
      task: "assemble",
      build_type: "Release"
    )
    
    apksigner(
      apk_path: "app/build/outputs/apk/release/app-release-unsigned.apk",
      ks_path: ENV["KEYSTORE_PATH"],
      ks_key_alias: ENV["KEY_ALIAS"],
      ks_pass: ENV["KEYSTORE_PASSWORD"],
      key_pass: ENV["KEY_PASSWORD"]
    )
    
    zipalign(
      apk_path: "app/build/outputs/apk/release/app-release.apk"
    )
    
    slack(
      message: "✅ تم بناء وتوقيع إصدار Release بنجاح!"
    )
  end

  desc "نشر على Google Play Console (التجريب الداخلي)"
  lane :internal do
    gradle(
      task: "bundle",
      build_type: "Release"
    )
    
    upload_to_play_store(
      track: "internal",
      aab: "app/build/outputs/bundle/release/app-release.aab",
      json_key: "play-console-service-account.json"
    )
    
    slack(
      message: "🚀 تم نشر الإصدار على Google Play Internal Testing!"
    )
  end

  desc "توزيع نسخة تجريبية عبر Firebase App Distribution"
  lane :beta do
    gradle(
      task: "assemble",
      build_type: "Release"
    )
    
    firebase_app_distribution(
      app: ENV["FIREBASE_APP_ID"],
      apk_path: "app/build/outputs/apk/release/app-release.apk",
      groups: "testers",
      release_notes: "إصدار تجريبي جديد - اختبروا التطبيق وأبلغونا بأي مشاكل"
    )
    
    slack(
      message: "📦 تم توزيع النسخة التجريبية عبر Firebase App Distribution!"
    )
  end

  desc "تحديث رقم الإصدار تلقائياً"
  lane :bump do
    version_android(
      gradle_file: "app/build.gradle.kts"
    )
  end

  desc "توليد سجل التغييرات من Git"
  lane :changelog do
    changelog_from_git_commits(
      count: 10,
      pretty: "- %s",
      date_format: "short"
    )
  end
end
```

## 4. متغيرات البيئة المطلوبة (Environment Variables)

أنشئ ملف `.env` في جذر المشروع (لا ترفعه إلى Git):

```env
KEYSTORE_PATH=keystore/release-keystore.jks
KEYSTORE_PASSWORD=your_keystore_password
KEY_ALIAS=release-key
KEY_PASSWORD=your_key_password
FIREBASE_APP_ID=1:123456789:android:abcdef
FIREBASE_TOKEN=your_firebase_cli_token
SLACK_URL=https://hooks.slack.com/services/...
```

في CI/CD (مثل GitHub Actions)، أضف هذه المتغيرات عبر **Repository Secrets**.

## 5. أوامر Fastlane الشائعة

```bash
# عرض جميع المسارات (lanes) المتاحة
fastlane lanes

# بناء نسخة Debug
fastlane debug

# بناء وتوقيع نسخة Release
fastlane release

# نشر على Google Play Intern
fastlane internal

# توزيع تجريبي عبر Firebase
fastlane beta

# تحديث رقم الإصدار
fastlane bump
```

## 6. التكامل مع GitHub Actions

مثال ملف `.github/workflows/android-ci.yml`:

```yaml
name: Android CI/CD

on:
  push:
    tags: ["v*"]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: 17
          distribution: temurin
      - name: Install Android SDK
        uses: android-actions/setup-android@v3
      - name: Build Release APK
        env:
          KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
          KEY_ALIAS: ${{ secrets.KEY_ALIAS }}
          KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}
        run: |
          bundle exec fastlane release
      - name: Upload to Firebase
        env:
          FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN }}
        run: |
          bundle exec fastlane beta
```

## 7. مزايا استخدام Fastlane

| الميزة | الفائدة |
|--------|--------|
| أتمتة كاملة | بناء → توقيع → نشر دون تدخل يدوي |
| تقليل الأخطاء البشرية | نفس الخطوات تُنفذ في كل مرة |
| توفر الوقت | لا حاجة لتوقيع ورفع الملفات يدوياً |
| تكامل مع CI/CD | يعمل مع GitHub Actions, GitLab CI, Bitrise, ... |
| إشعارات فورية | إبلاغ الفريق عند نجاح أو فشل البناء |

## 8. تحذيرات أمنية

- لا ترفع ملف `keystore.jks` أو كلمات المرور إلى مستودع Git.
- استخدم متغيرات البيئة أو Secrets في CI/CD.
- احفظ نسخة احتياطية من keystore في مكان آمن.
- راجع أذونات حساب خدمة Google Play Console (service account) بشكل دوري.

---

بعد مراجعة هذا الملف، يمكنك الانتقال إلى [أدوات سطر الأوامر](../cli/README.md) للعمل من terminal مباشرة، أو [مكتبات Android](../libraries/README.md) لإضافة التبعيات للتطبيق.