# ضمان الجودة والاختبار (Testing & Quality Assurance)

هذه الصفحة توثق جميع أدوات وأساليب الاختبار وضمان الجودة المستخدمة في تطبيقات Android APK الاحترافية قبل النشر.

## 1. أنواع الاختبارات

| النوع | الغرض | الأدوات |
|-------|-------|--------|
| اختبارات الوحدات (Unit Tests) | اختبار الدوال والصفوف بشكل منفصل عن واجهة المستخدم | JUnit, Mockito, MockK, Robolectric |
| اختبارات التكامل (Integration Tests) | اختبار تفاعل المكونات مع بعضها | JUnit, Hilt Test, Testcontainers |
| اختبارات واجهة المستخدم (UI Tests) | اختبار التفاعل مع الشاشات والأزرار والنصوص | Espresso, UI Automator, Compose Test |
| اختبارات النهاية إلى النهاية (E2E) | اختبار سير العمل الكامل من البداية للنهاية | Espresso, Detox, Appium |
| اختبارات الأداء (Performance Tests) | قياس وقت الاستجابة واستهلاك الموارد | Android Studio Profiler, Macrobenchmark |
| اختبارات الأمان (Security Tests) | فحص الثغرات والتسريبات | OWASP ZAP, MobSF, APKLeaks |
| اختبارات التوافق (Compatibility Tests) | اختبار التطبيق على إصدارات Android مختلفة وأحجام شاشات مختلفة | Firebase Test Lab, Genymotion, AVD |

## 2. اختبارات الوحدات (Unit Tests)

### المكتبات

| المكتبة | الغرض | معرف الإضافة |
|--------|-------|-------------|
| JUnit 4 | إطار اختبار الوحدات القياسي | `junit:junit:4.13.2` |
| JUnit 5 (Jupiter) | إطار اختبار حديث | `org.junit.jupiter:junit-jupiter:5.10.0` |
| Kotlin Test | اختبار لكotlin | `org.jetbrains.kotlin:kotlin-test:1.9.20` |
| Mockito | إنشاء كائنات محاكاة (Mock Objects) | `org.mockito:mockito-core:5.11.0` |
| MockK | إنشاء كائنات محاكاة لـ Kotlin | `io.mockk:mockk:1.13.9` |
| Robolectric | تشغيل اختبارات Android على JVM بدون محاكي | `org.robolectric:robolectric:4.10.1` |
| AssertJ | تأكيدات (Assertions) غنية | `org.assertj:assertj-core:3.24.2` |
| Truth | تأكيدات بسيطة وقابلة للقراءة | `com.google.truth:truth:1.1.5` |

### مثال اختبار وحدة

```kotlin
import com.tammtool.app.repository.UserRepository
import io.mockk.every
import io.mockk.mockk
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertEquals

class UserViewModelTest {

    @Test
    fun `يجب أن يعرض اسم المستخدم عند تحميل البيانات بنجاح`() {
        // Given
        val repository = mockk<UserRepository>()
        every { repository.getUserName() } returns "أحمد"
        val viewModel = UserViewModel(repository)

        // When
        viewModel.loadUser()

        // Then
        assertEquals("أحمد", viewModel.userName)
    }
}
```

### أمر التشغيل

```bash
./gradlew test
```

## 3. اختبارات واجهة المستخدم (UI Tests)

### المكتبات

| المكتبة | الغرض | معرف الإضافة |
|--------|-------|-------------|
| Espresso | اختبار واجهة المستخدم لتطبيقات View | `androidx.test.espresso:espresso-core:3.5.1` |
| UI Automator | اختبار واجهة المستخدم عبر التطبيقات | `androidx.test.uiautomator:uiautomator:2.3.0` |
| Compose Test | اختبار تطبيقات Jetpack Compose | `androidx.compose.ui:ui-test-junit4:1.6.4` |
| Android Test Orchestrator | تشغيل كل اختبار في عملية منفصلة | `androidx.test:orchestrator:1.4.2` |

### مثال اختبار Espresso

```kotlin
import androidx.test.espresso.Espresso.onView
import androidx.test.espresso.action.ViewActions.click
import androidx.test.espresso.assertion.ViewAssertions.matches
import androidx.test.espresso.matcher.ViewMatchers.withId
import androidx.test.espresso.matcher.ViewMatchers.withText
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class MainActivityTest {

    @Test
    fun يجب_أن_يظهر_نص_مرحبا_عند_فتح_الشاشة() {
        onView(withId(R.id.textView))
            .check(matches(withText("مرحباً بالعالم")))
    }

    @Test
    fun عند_النقر_على_الزر_يجب_أن_يتغير_النص() {
        onView(withId(R.id.button_submit)).perform(click())
        onView(withId(R.id.textView))
            .check(matches(withText("تم الإرسال")))
    }
}
```

### أمر التشغيل

```bash
# على جهاز أو محاكي متصل
./gradlew connectedAndroidTest

# أو باستخدام Firebase Test Lab لأجهزة حقيقية
./gradlew firebaseTestLab
```

## 4. اختبارات Jetpack Compose

### مثال

```kotlin
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import org.junit.Rule
import org.junit.Test

class GreetingTest {

    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun يجب_أن_يعرض_النص_الصحيح() {
        composeTestRule.setContent {
            Greeting(name = "أحمد")
        }
        composeTestRule.onNodeWithText("مرحباً، أحمد!").assertExists()
    }
}
```

## 5. تحليل الشيفرة الثابتة (Static Analysis)

| الأداة | الغرض | معرف الإضافة |
|--------|-------|-------------|
| Detekt | تحليل ثابت لشيفرة Kotlin واكتشاف العيوب | `io.gitlab.arturbosch.detekt:detekt-core:1.23.0` |
| Ktlint | تنسيق وفحص نمط شيفرة Kotlin | `com.pinterest:ktlint:0.50.0` |
| Spotless | تنسيق شامل للشيفرة (Kotlin, Java, XML) | `com.diffplug.spotless` |
| Android Lint | فحص أخطاء Android (مدمج في AGP) | مدمج |
| SpotBugs | اكتشاف الأخطاء في شيفرة Java | `com.github.spotbugs:spotbugs-gradle-plugin:5.x` |
| SonarQube | تحليل جودة الشيفرة والأمان والثغرات | https://sonarqube.org |

### مثال تفعيل Detekt في Gradle

```kotlin
plugins {
    id("io.gitlab.arturbosch.detekt") version "1.23.0"
}

detekt {
    config = files("detekt-config.yml")
    buildUponDefaultConfig = true
    reports {
        html {
            enabled = true
            destination = file("build/reports/detekt.html")
        }
        xml {
            enabled = true
            destination = file("build/reports/detekt.xml")
        }
    }
}

tasks.named("detekt") {
    dependsOn("compileDebugKotlin")
}
```

### أوامر التشغيل

```bash
./gradlew detekt       # تشغيل تحليل Detekt
./gradlew ktlintCheck  # فحص تنسيق Ktlint
./gradlew ktlintFormat # تطبيق تنسيق Ktlint تلقائيًا
./gradlew lint         # فحص أخطاء Android Lint
./gradlew spotlessCheck # فحص التنسيق عبر Spotless
./gradlew spotlessApply # تطبيق التنسيق تلقائيًا
```

## 6. اختبارات الأداء (Performance Tests)

| الأداة | الغرض |
|--------|-------|
| Macrobenchmark | قياس وقت بدء التطبيق وتأطير الإطارات (frame timing) |
| Microbenchmark | قياس أداء دوال محددة في الشيفرة |
| Android Studio Profiler | مراقبة استهلاك CPU، الذاكرة، الشبكة، البطارية في الوقت الفعلي |
| Firebase Performance | مراقبة الأداء في الإنتاج (راجع ملف analytics) |

### مثال Macrobenchmark

```kotlin
class StartupBenchmark {

    @get:Rule
    val benchmarkRule = MacrobenchmarkRule()

    @Test
    fun startup() = benchmarkRule.measureRepeated(
        packageName = "com.tammtool.app",
        metrics = listOf(StartupTimingMetric()),
        iterations = 5
    ) {
        pressHome()
        startActivityAndWait()
    }
}
```

## 7. اختبار على أجهزة حقيقية (Real Device Testing)

| الخدمة | الغرض | التكلفة |
|--------|-------|--------|
| Firebase Test Lab | اختبار على dozens من الأجهزة الحقيقية والمحاكية في سحابة Google | مجاني ضمن حدود يومية، ثم مدفوع |
| Genymotion Cloud | محاكيات سريعة للسحابة | مجاني جزئيًا، ثم مدفوع |
| AWS Device Farm | اختبار على أجهزة حقيقية في سحابة أمازون | مدفوع |
| BrowserStack | اختبار على أجهزة حقيقية ومتصفحات | مدفوع |
| محلي | استخدام أجهزة Android حقيقية متصلة عبر USB | مجاني |

### مثال Firebase Test Lab

```bash
gcloud firebase test android run \
  --type instrumentation \
  --app app/build/outputs/apk/debug/app-debug.apk \
  --test app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk \
  --device model=shamu,version=28,locale=en,orientation=portrait \
  --device model=bullhead,version=29,locale=en,orientation=landscape
```

## 8. مثال إعداد كامل للاختبار في `build.gradle.kts`

```kotlin
android {
    // ...
    testOptions {
        unitTests {
            includeAndroidResources = true
        }
    }
}

dependencies {
    // اختبارات الوحدات
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.mockito:mockito-core:5.11.0")
    testImplementation("io.mockk:mockk:1.13.9")
    testImplementation("org.robolectric:robolectric:4.10.1")
    testImplementation("org.assertj:assertj-core:3.24.2")
    
    // اختبارات واجهة المستخدم
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
    androidTestImplementation("androidx.test.uiautomator:uiautomator:2.3.0")
    androidTestImplementation("androidx.compose.ui:ui-test-junit4:1.6.4")
    
    // اختبار Compose
    debugImplementation("androidx.compose.ui:ui-test-manifest:1.6.4")
}
```

## 9. قائمة مراجعة الجودة قبل النشر (QA Checklist)

- [ ] جميع اختبارات الوحدات ناجحة (`./gradlew test`)
- [ ] جميع اختبارات واجهة المستخدم ناجحة على جهاز أو محاكي (`./gradlew connectedAndroidTest`)
- # تم تشغيل تحليل Detekt دون أخطاء حرجة (`./gradlew detekt`)
- # تم تطبيق تنسيق Ktlint (`./gradlew ktlintCheck`)
- # تم تشغيل Android Lint دون أخطاء (`./gradlew lint`)
- # تم اختبار التطبيق على الأقل على جهاز حقيقي واحد
- # تم اختبار التطبيق على إصدارات Android مختلفة (مثل API 24 و API 35)
- # تم اختبار التطبيق على أحجام شاشات مختلفة (هاتف، جهاز لوحي، جهاز قابل للطي)
- # تم اختبار التطبيق في وضع عدم الاتصال (Offline Mode)
- # تم اختبار التطبيق مع تغيير اتجاه الشاشة (دوران)
- # تم اختبار Memory Leaks باستخدام Android Studio Profiler
- # تم اختبار استهلاك البطارية
- # تم مراجعة تقارير Crashlytics في الإصدارات التجريبية
- # تم تحديث رقم الإصدار (versionCode و versionName)

## 10. أوامر الاختبار المجمعة

```bash
# تشغيل جميع الاختبارات والتحليلات
./gradlew test detekt ktlintCheck lint

# بناء وتثبيت وتشغيل اختبارات واجهة المستخدم
./gradlew assembleDebug installDebug connectedAndroidTest

# تحليل الجودة وإنشاء تقرير
./gradlew detekt --reports html,xml
```

---

بعد مراجعة هذا الملف، يمكنك الانتقال إلى [التصميم وواجهات المستخدم](../design/README.md) لتحسين تجربة المستخدم، أو [أنظمة CI/CD](../ci-cd/README.md) لإعداد خطوط البناء والنشر التلقائي.