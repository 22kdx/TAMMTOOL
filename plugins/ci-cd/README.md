# أنظمة التكامل والنشر المستمر (CI/CD Systems)

هذه الصفحة توثق جميع أنظمة وأدوات CI/CD المستخدمة في بناء واختبار وتوقيع ونشر تطبيقات Android APK/AAB بشكل تلقائي.

## 1. GitHub Actions (موصى به للمستودعات على GitHub)

### مزايا
- مجاني للمستودعات العامة
- تكامل مباشر مع مستودعات GitHub
- دعم قياسي لـ Android و Gradle و Java
- يمكن استخدام Secrets لإدارة كلمات المرور والملفات الحساسة

### مثال ملف سير العمل (`.github/workflows/build-apk.yml`)

```yaml
name: Build Release APK

on:
  push:
    branches: ["main", "develop"]
  pull_request:
    branches: ["main"]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Clone repository
        uses: actions/checkout@v4

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: 17
          distribution: temurin

      - name: Cache Gradle packages
        uses: actions/cache@v4
        with:
          path: |
            ~/.gradle/caches
            ~/.gradle/wrapper
          key: ${{ runner.os }}-gradle-${{ hashFiles('**/*.gradle*', '**/gradle-wrapper.properties') }}
          restore-keys: |
            ${{ runner.os }}-gradle-

      - name: Setup Android SDK
        uses: android-actions/setup-android@v3

      - name: Grant execute permission for gradlew
        run: chmod +x gradlew

      - name: Build Debug APK
        run: ./gradlew assembleDebug

      - name: Run Unit Tests
        run: ./gradlew test

      - name: Run Lint
        run: ./gradlew lint

      - name: Upload APK artifact
        uses: actions/upload-artifact@v4
        if: github.ref == 'refs/heads/main'
        with:
          name: debug-apk
          path: app/build/outputs/apk/debug/app-debug.apk
          retention-days: 30
```

### مثال نشر على Google Play (`release.yml`)

```yaml
name: Publish to Google Play

on:
  push:
    tags: ["v*"]

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          java-version: 17
          distribution: temurin
      - uses: android-actions/setup-android@v3
      - name: Build Release AAB
        env:
          KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
          KEY_ALIAS: ${{ secrets.KEY_ALIAS }}
          KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}
        run: ./gradlew bundleRelease
      - name: Upload to Play Console
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJson: ${{ secrets.PLAY_CONSOLE_JSON }}
          packageName: com.tammtool.app
          releaseFiles: app/build/outputs/bundle/release/app-release.aab
          track: internal
          status: completed
```

## 2. GitLab CI/CD

### مزايا
- مجاني للمستودعات العامة والخاصة على GitLab.com
- دعم مدمج مع Docker و Kubernetes
- يمكن استضافة GA runners ذاتياً

### مثال ملف `.gitlab-ci.yml`

```yaml
stages:
  - build
  - test
  - deploy

variables:
  ANDROID_HOME: "/usr/lib/android-sdk"
  GRADLE_USER_HOME: "$CI_PROJECT_DIR/.gradle"

build_debug:
  stage: build
  image: openjdk:17-jdk
  before_script:
    - apt-get update && apt-get install -y android-sdk-platform-tools
    - chmod +x gradlew
  script:
    - ./gradlew assembleDebug
  artifacts:
    paths:
      - app/build/outputs/apk/debug/app-debug.apk
    expire_in: 1 week

test:
  stage: test
  image: openjdk:17-jdk
  before_script:
    - chmod +x gradlew
  script:
    - ./gradlew test

deploy_play_store:
  stage: deploy
  image: openjdk:17-jdk
  before_script:
    - chmod +x gradlew
  script:
    - ./gradlew bundleRelease
  artifacts:
    paths:
      - app/build/outputs/bundle/release/app-release.aab
  only:
    - tags
```

## 3. Bitrise (سحابي، متخصص في تطبيقات الجوال)

### مزايا
- واجهة مرئية لبناء خطوات (workflows) بدون كود
- دعم مدمج لـ Android و iOS و Flutter و React Native
- تكامل مع GitHub, GitLab, Bitbucket

### خطوات نموذجية في Bitrise
1. Git Clone Repository
2. Android Build (Gradle assembleRelease)
3. Android Sign (توقيع APK)
4. Google Play Deploy (رفع إلى Play Console)
5. Slack Notification (إشعار الفريق)

## 4. Codemagic (سحابي)

### مزايا
- دعم قوي لـ Flutter و Android و iOS
- واجهة مرئية أو إعداد عبر ملف `codemagic.yaml`
- بناء على أجهزة macOS حقيقية لـ iOS (إذا لزم الأمر)

### مثال `codemagic.yaml`

```yaml
workflows:
  android-workflow:
    name: Android Workflow
    max_build_duration: 60
    environment:
      vars:
        KEYSTORE_PASSWORD: $KEYSTORE_PASSWORD
        KEY_ALIAS: $KEY_ALIAS
        KEY_PASSWORD: $KEY_PASSWORD
    triggering:
      events:
        - push
      branch_patterns:
        - pattern: main
          include: true
          source: branch
    scripts:
      - name: Set up keystore
        script: |
          echo "$KEYSTORE_BASE64" | base64 --decode > keystore/release-keystore.jks
      - name: Build APK
        script: |
          cd $FCI_BUILD_DIR
          ./gradlew assembleRelease
    artifacts:
      - app/build/outputs/apk/release/*.apk
      - app/build/outputs/apk/release/*.aab
    publishing:
      google_play:
        credentials: $GCLOUD_SERVICE_ACCOUNT_CREDENTIALS
        track: internal
```

## 5. Jenkins (استضافة ذاتية)

### مزايا
- مجاني ومفتوح المصدر
- سيطرة كاملة على الخادم والبنية التحتية
- إضافات كثيرة (Android Emulator, Gradle, Git, ...)

### الإضافات المطلوبة في Jenkins
- Android Emulator Plugin
- Gradle Plugin
- Git Plugin
- Pipeline Plugin
- GitHub Integration Plugin

### مثال `Jenkinsfile`

```groovy
pipeline {
    agent any
    environment {
        ANDROID_HOME = '/opt/android-sdk'
        KEYSTORE_PASSWORD = credentials('keystore-password')
        KEY_ALIAS = credentials('key-alias')
        KEY_PASSWORD = credentials('key-password')
    }
    stages {
        stage('Checkout') {
            steps { checkout scm }
        }
        stage('Build') {
            steps {
                sh './gradlew assembleRelease'
            }
        }
        stage('Test') {
            steps {
                sh './gradlew test'
            }
        }
        stage('Sign') {
            steps {
                sh 'apksigner sign --ks keystore/release-keystore.jks --ks-key-alias release-key --ks-pass pass:${KEYSTORE_PASSWORD} --key-pass pass:${KEY_PASSWORD} --out app-release.apk app/build/outputs/apk/release/app-release-unsigned.apk'
            }
        }
        stage('Deploy') {
            steps {
                sh 'fastlane supply --track internal'
            }
        }
    }
    post {
        always {
            archiveArtifacts artifacts: 'app/build/outputs/**/*.apk, app/build/outputs/**/*.aab'
        }
    }
}
```

## 6. CircleCI

### مزايا
- دعم مدمج لـ Docker و macOS
- إعداد عبر ملف `.circleci/config.yml`
- تكامل مع GitHub و Bitbucket

### مثال `.circleci/config.yml`

```yaml
version: 2.1
jobs:
  build:
    docker:
      - image: cimg/openjdk:17.0
    working_directory: ~/tammtool
    steps:
      - checkout
      - restore_cache:
          key: gradle-v1-{{ checksum "build.gradle.kts" }}
      - run:
          name: Build Debug APK
          command: ./gradlew assembleDebug
      - save_cache:
          key: gradle-v1-{{ checksum "build.gradle.kts" }}
          paths:
            - ~/.gradle
      - store_artifacts:
          path: app/build/outputs/apk/debug/app-debug.apk
          destination: debug-apk
workflows:
  version: 2
  build_and_test:
    jobs:
      - build
```

## 7. Azure DevOps

### مزايا
- تكامل مع Microsoft Azure
- دعم Windows و Linux و macOS agents
- لوحات تحكم وتقارير متقدمة

## 8. مقارنة بين أنظمة CI/CD

| النظام | الاستضافة | التكلفة | مخصص للجوال | واجهة مرئية | تكامل GitHub |
|--------|-----------|---------|--------------|-------------|--------------|
| GitHub Actions | سحابي / ذاتي | مجاني (عام) | متوسط | لا | ممتاز |
| GitLab CI/CD | سحابي / ذاتي | مجاني (عام) | متوسط | لا | متوسط |
| Bitrise | سحابي | مدفوع (نموذج مجاني محدود) | ممتاز | نعم | جيد |
| Codemagic | سحابي | مدفوع (نموذج مجاني محدود) | ممتاز | نعم | جيد |
| Jenkins | ذاتي | مجاني | متوسط | لا (بإضافات) | جيد |
| CircleCI | سحابي | نموذج مجاني محدود | متوسط | لا | جيد |
| Azure DevOps | سحابي | نموذج مجاني محدود | متوسط | لا | متوسط |

## 9. أفضل الممارسات لـ CI/CD لتطبيقات Android

1. **تخزين التبعيات (Caching):** احفظ مجلد `~/.gradle` بين البناءات لتسريع البناء.
2. **فصل المهام:** قسّم خط الأنابيب إلى مراحل (build, test, sign, deploy).
3. **إدارة الأسرار (Secrets):** لا تضع كلمات المرور أو ملفات keystore في الكود، استخدم Secrets في النظام.
4. **إطلاق نسخ تجريبية أولًا:** نشر على Internal Testing قبل Production.
5. **إشعارات الفريق:** أرسل إشعارات إلى Slack أو Email عند نجاح أو فشل البناء.
6. **تحليل الجودة:** شغّل Detekt و Ktlint و Lint في مرحلة الاختبار.
7. **الأرشفة:** احفظ ملفات APK/AAB كمنتجات (artifacts) للتحميل لاحقًا.

## 10. مثال متكامل: GitHub Actions + Fastlane + Google Play

```yaml
name: Android CI/CD with Fastlane

on:
  push:
    tags: ["v*"]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-ruby@v1
        with:
          ruby-version: '3.2'
      - name: Install Fastlane
        run: gem install fastlane
      - uses: actions/setup-java@v4
        with:
          java-version: 17
          distribution: temurin
      - uses: android-actions/setup-android@v3
      - name: Decode Keystore
        env:
          KEYSTORE_BASE64: ${{ secrets.KEYSTORE_BASE64 }}
        run: |
          echo "$KEYSTORE_BASE64" | base64 --decode > keystore/release-keystore.jks
      - name: Build, Sign, and Deploy
        env:
          KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
          KEY_ALIAS: ${{ secrets.KEY_ALIAS }}
          KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}
          FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN }}
          PLAY_CONSOLE_JSON: ${{ secrets.PLAY_CONSOLE_JSON }}
        run: |
          bundle exec fastlane release
          bundle exec fastlane internal
```

---

بعد مراجعة هذا الملف، يمكنك الانتقال إلى [التحليلات وCrash Reporting](../analytics/README.md) لمراقبة التطبيق في الإنتاج، أو [الأمان والحماية](../security/README.md) لحماية الشيفرة والبيانات.