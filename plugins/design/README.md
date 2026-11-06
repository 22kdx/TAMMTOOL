# التصميم وواجهات المستخدم (Design & UI/UX)

هذه الصفحة توثق جميع الأدوات والمكتبات والملحقات المستخدمة في تصميم وتطوير واجهات مستخدم احترافية لتطبيقات Android APK.

## 1. مكتبات واجهة المستخدم (UI Libraries)

| المكتبة | الغرض | معرف الإضافة |
|--------|-------|-------------|
| Material Components | مكونات Material Design الرسمية (أزرار، بطاقات، حقول نص، قوائم، ...) | `com.google.android.material:material:1.11.0` |
| ConstraintLayout | تخطيط مرن وقوي لواجهات المستخدم المعقدة | `androidx.constraintlayout:constraintlayout:2.1.4` |
| Jetpack Compose | بناء واجهات المستخدم بشكل 선언ي (Declarative) باستخدام Kotlin | `androidx.compose.ui:ui:1.6.4` |
| Compose Material | مكونات Material Design لـ Jetpack Compose | `androidx.compose.material:material:1.6.4` |
| Compose Foundation | أساسيات تخطيط Compose (الأحجام، التباعد، ...) | `androidx.compose.foundation:foundation:1.6.4` |
| Compose UI Toolkit | أدوات إضافية لواجهة Compose | `androidx.compose.ui:ui-tooling:1.6.4` |
| RecyclerView | عرض قوائم طويلة من البيانات بكفاءة | `androidx.recyclerview:recyclerview:1.3.2` |
| CardView | بطاقات عرض للمحتوى مع ظلال وأطراف مستديرة | `androidx.cardview:cardview:1.0.0` |
| SwipeRefreshLayout | التمرير لإعادة التحميل (Pull to Refresh) | `androidx.swiperefreshlayout:swiperefreshlayout:1.1.0` |
| NestedScrollView | تخطيطات تمرير متداخلة | `androidx.core:core:1.12.0` |
| ViewPager2 | التمرير بين الصفحات (sliding pages) | `androidx.viewpager2:viewpager2:1.0.0` |
| DrawerLayout | قائمة التنقل الجانبية (Navigation Drawer) | `androidx.drawerlayout:drawerlayout:1.2.0` |
| BottomNavigation | شريط تنقل سفلي | `com.google.android.material:material:1.11.0` |
| Navigation Component | التنقل بين الشاشات بأمان | `androidx.navigation:navigation-fragment-ktx:2.7.5` |
| MotionLayout | رسم حركة وانتقالات سلسة بين حالات الواجهة | `androidx.constraintlayout:constraintlayout:2.1.4` |

## 2. إدارة الثيمات والألوان (Theming & Colors)

| الأداة | الغرض |
|--------|-------|
| Material Theme Builder | بناء وتخصيص ثيمات Material Design (ألوان،طوط،أشكال) | https://material-foundation.github.io/material-theme-builder/ |
| Material Theme Editor (إضافة Android Studio) | تعديل وتخصيص سمات Material Design من داخل IDE |
| Color Picker | اختيار الألوان من الشاشة أو من أكواد Hex وتحويلها إلى ألوان Android |
| Palette API | استخراج الألوان البارزة من الصور لاستخدامها في واجهة المستخدم | `androidx.palette:palette-ktx:1.0.0` |
| Dynamic Color (Material You) | ألوان متغيرة بناءً على خلفية الجهاز (Android 12+) | مدمج في Material Components |

### مثال ملف `themes.xml`

```xml
<resources xmlns:tools="http://schemas.android.com/tools">
    <!-- Основной thème -->
    <style name="Theme.TammToolApp" parent="Theme.MaterialComponents.DayNight.DarkActionBar">
        <item name="colorPrimary">@color/colorPrimary</item>
        <item name="colorPrimaryDark">@color/colorPrimaryDark</item>
        <item name="colorAccent">@color/colorAccent</item>
        <item name="colorOnPrimary">@color/white</item>
        <item name="colorSurface">@color/surface</item>
        <item name="colorOnSurface">@color/on_surface</item>
        <item name="android:windowBackground">@color/window_background</item>
        <item name="fontFamily">@font/roboto</item>
    </style>

    <!-- ثيم بدون شريط إجراء (Fullscreen) -->
    <style name="Theme.TammToolApp.NoActionBar">
        <item name="windowActionBar">false</item>
        <item name="windowNoTitle">true</item>
    </style>

    <!-- ثيم للشاشة الرئيسية (Splash Screen) -->
    <style name="Theme.TammToolApp.Splash" parent="Theme.SplashScreen">
        <item name="windowSplashScreenBackground">@color/colorPrimary</item>
        <item name="windowSplashScreenAnimatedIcon">@drawable/ic_splash</item>
        <item name="postSplashScreenTheme">@style/Theme.TammToolApp</item>
    </style>
</resources>
```

## 3. الأيقونات والرسومات (Icons & Graphics)

| الأداة | الغرض |
|--------|-------|
| Material Design Icon Generator (إضافة Android Studio) | توليد أيقونات Material Design لمختلف دقعات الشاشة |
| Android Drawable Importer | استيراد وتحويل الصور إلى صيغ Drawable متعددة الدقة (ldpi, mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi) |
| SVG to VectorDrawable (إضافة Android Studio) | تحويل ملفات SVG إلى VectorDrawable للاستخدام في Android |
| Vector Asset Studio | أداة مدمجة في Android Studio لإنشاء أيقونات متجهة |
| Image Asset Studio | أداة مدمجة في Android Studio لإنشاء أيقونات التطبيق (Launcher Icons) |
| Lottie | عرض رسومات متحركة من ملفات JSON (After Effects) | `com.airbnb.android:lottie:6.2.0` |
| AnimatedVectorDrawable | أيقونات متجهة متحركة | مدمج في AndroidX |
| Shapeshifter | أداة تصميم أيقونات متحركة | https://shapeshifter.design |
| Coil | تحميل وعرض الصور بكفاءة في Compose و Views | `io.coil-kt:coil:2.5.0` |
| Glide | مكتبة تحميل الصور الكلاسيكية مع دعم GIF و WebP | `com.github.bumptech.glide:glide:4.16.0` |
| Picasso | مكتبة تحميل الصور الخفيفة | `com.squareup.picasso:picasso:2.71828` |

## 4. الخطوط والطباعة (Typography & Fonts)

| الأداة | الغرض |
|--------|-------|
| Google Fonts | خطوط مجانية مفتوحة المصدر للاستخدام في التطبيقات | https://fonts.google.com |
| Android Font Resource | تحميل الخطوط من ملفات TTF/OTF في مجلد `res/font/` | مدمج في AndroidX |
| Downloadable Fonts | تحميل الخطوط من Google Fonts تلقائيًا دون تضمينها في التطبيق | مدمج في AndroidX |
| Typekit / Adobe Fonts | خطوط احترافية مدفوعة | https://fonts.adobe.com |

### مثال استخدام خط مخصص

```xml
<!-- res/font/roboto_bold.xml -->
<?xml version="1.0" encoding="utf-8"?>
<font-family xmlns:app="http://schemas.android.com/apk/res-auto">
    <font app:fontStyle="normal" app:fontWeight="400" app:resEntry="@font/roboto_regular" />
    <font app:fontStyle="bold" app:fontWeight="700" app:resEntry="@font/roboto_bold" />
</font-family>
```

```kotlin
// في Kotlin
textView.typeface = ResourcesCompat.getFont(context, R.font.roboto_bold)
```

## 5. دعم اللغات وتخطيط RTL (Internationalization & RTL)

| الميزة | الوصف |
|--------|-------|
| دعم RTL (من اليمين إلى اليسار) | دعم اللغات العربية والعبرية وغيرها التي تُكتب من اليمين لليسار |
| ресурсы مترجمة | ملفات `strings.xml` لكل لغة في مجلدات `values-ar/`, `values-en/`, ... |
| تخطيطات مرنة | استخدام `start` و `end` بدلاً من `left` و `right` لدعم التوجيه التلقائي |

### مثال دعم RTL

```xml
<!-- res/layout/activity_main.xml -->
<TextView
    android:layout_width="wrap_content"
    android:layout_height="wrap_content"
    android:text="@string/hello_world"
    android:layout_marginStart="16dp"  <!-- 사용 start بدلاً من left -->
    android:layout_marginEnd="16dp"    <!-- 사용 end بدلاً من right -->
    android:textAlignment="viewStart" />
```

```xml
<!-- res/values-ar/strings.xml -->
<resources>
    <string name="app_name">تطبيق تمك توول</string>
    <string name="hello_world">مرحباً بالعالم</string>
</resources>

<!-- res/values-en/strings.xml -->
<resources>
    <string name="app_name">TammTool App</string>
    <string name="hello_world">Hello World</string>
</resources>
```

## 6. أدوات التصميم والنماذج الأولية (Design & Prototyping Tools)

| الأداة | الغرض | الموقع |
|--------|-------|-------|
| Figma | تصميم واجهات المستخدم والنماذج الأولية التفاعلية | https://figma.com |
| Adobe XD | تصميم وتجربة المستخدم | https://adobe.com/products/xd |
| Sketch | تصميم واجهات المستخدم (macOS فقط) | https://sketch.com |
| Adobe Illustrator | تصميم الأيقونات والرسومات المتجهة | https://adobe.com/products/illustrator |
| Penpot | بديل مفتوح المصدر لـ Figma | https://penpot.app |

## 7. أمثلة أكواد لواجهات مستخدم احترافية

### بطاقة Material Design مع صورة ونص

```xml
<com.google.android.material.card.MaterialCardView
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:layout_margin="16dp"
    app:cardCornerRadius="12dp"
    app:cardElevation="4dp"
    app:cardBackgroundColor="@color/card_background">

    <androidx.constraintlayout.widget.ConstraintLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:padding="16dp">

        <ImageView
            android:id="@+id/imageView"
            android:layout_width="80dp"
            android:layout_height="80dp"
            android:src="@drawable/ic_app"
            app:layout_constraintTop_toTopOf="parent"
            app:layout_constraintStart_toStartOf="parent" />

        <TextView
            android:id="@+id/titleTextView"
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:text="@string/card_title"
            android:textAppearance="?attr/textAppearanceHeadline6"
            android:layout_marginStart="16dp"
            app:layout_constraintTop_toTopOf="parent"
            app:layout_constraintStart_toEndOf="@id/imageView"
            app:layout_constraintEnd_toEndOf="parent" />

        <TextView
            android:id="@+id/descriptionTextView"
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:text="@string/card_description"
            android:textAppearance="?attr/textAppearanceBody1"
            android:layout_marginTop="8dp"
            app:layout_constraintTop_toBottomOf="@id/titleTextView"
            app:layout_constraintStart_toStartOf="@id/titleTextView"
            app:layout_constraintEnd_toEndOf="parent" />

    </androidx.constraintlayout.widget.ConstraintLayout>
</com.google.android.material.card.MaterialCardView>
```

### شاشة باستخدام Jetpack Compose

```kotlin
@Composable
fun GreetingScreen(name: String) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        Text(
            text = "مرحباً، $name",
            fontSize = 24.sp,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.primary
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        Button(
            onClick = { /* إجراء الضغط */ },
            colors = ButtonDefaults.buttonColors(
                containerColor = MaterialTheme.colorScheme.primary,
                contentColor = MaterialTheme.colorScheme.onPrimary
            )
        ) {
            Text(text = "ابدأ الآن")
        }
    }
}
```

## 8. قائمة مراجعة التصميم قبل النشر (Design Checklist)

- [ ] استخدام ثيم موحد لجميع شاشات التطبيق
- [ ] دعم الأبعاد المختلفة للشاشات (هاتف، جهاز لوحي، جهاز قابل للطي)
- [ ] دعم الوضع الليلي (Dark Mode) إذا كان مطلوبًا
- [ ] دعم اللغات المتعددة (بشكل خاص اللغة العربية مع RTL)
- [ ] أيقونات التطبيق مخصصة لجميع دقعات الشاشة (mipmap)
- [ ] شاشة splash screen احترافية
- [ ] الخطوط واضحة وسهلة القراءة
- [ ] الألوان تتناسب مع ذوي العجز البصري (تباين كافٍ)
- [ ] الأزرار والعناصر التفاعلية بحجم مناسب للمس ( حداقل 48dp × 48dp)
- [ ] استخدام Material Design Components لإعطاء مظهر احترافي
- [ ] اختبار الواجهة على أجهزة حقيقية بمقاسات شاشة مختلفة
- [ ] تحسين تحميل الصور باستخدام Coil أو Glide لتقليل استهلاك الذاكرة

---

بعد مراجعة هذا الملف، يمكنك الانتقال إلى [مكتبات Android و Jetpack](../libraries/README.md) لإضافة التبعيات للتطبيق، أو [الأمان والحماية](../security/README.md) لحماية الشيفرة والبيانات.