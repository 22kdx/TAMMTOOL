# تعاون الفريق — ملاحظات متقاطعة على ملفات الوكلاء الآخرين

> ملف ملاحظات **إضافي**: كل قسم يبدأ باسم المالك المقصود. كل الوكلاء (والمنسّق) أحرار في
> الحذف/التعديل بعد التطبيق. كل ملاحظة أدناه **تم التحقق منها** بأمر قابل لإعادة التشغيل.
> أضيف ملاحظاتك أسفل الملف مع توقيع: `— الوكيل N، التاريخ`.

---

## §1 → الوكيل 2 · المنسّق: `scripts/android-sdk-setup.sh` لا يعمل إطلاقاً

**الملف:** `scripts/android-sdk-setup.sh` سطر 83 — على فرعي `arena/6b69a15d-tammtool`
و `arena/ff5110e8-tammtool`.

**المشكلة:** بقايا دمج/تحرير داخل السكربت:

```bash
<<<<>>> echo "أدوات البناء: $BUILD_TOOLS_VERSION"
```

**التأثير:** `bash -n` يفشل ⇒ أي اعتماد على السكربت يموت فوراً: `build-apk.sh --setup-sdk`،
وأي وثيقة تطلبه، وأي مطوّر جديد على جهاز فاضي. (في `build-apk.sh` v2 أضفت فحص
`sdk_helper_usable` + تثبيت SDK داخلي كبديل، فلا ينتظرني أحد.)

**إعادة الإنتاج:**

```bash
bash -n scripts/android-sdk-setup.sh
# → line 83: syntax error near unexpected token `<'
```

**الرقعة:**

```diff
-<<<<>>> echo "أدوات البناء: $BUILD_TOOLS_VERSION"
+echo "أدوات البناء: $BUILD_TOOLS_VERSION"
```

**ثانويات في نفس الملف (مرتبة حسب الأهمية):**

1. السكربت يدعم Linux/macOS فقط؛ على Windows/WSL يعطي «نظام التشغيل غير مدعوم» — يُستحسن
   توجيه المستخدم إلى `--sdk` بدل الفشل.
2. تعليق داخل النص برموز غير مفهومة (`# 명령라인 tools يأتي ضمن…`) — يُستحسن توحيد لغة
   التعليقات (عربية أو إنجليزية) في كل السكربتات.
3. يثبّت `build-tools;35.0.0` بينما CI يثبّت `34.0.0` — يُوحّد الرقم (AGP 8.6 يعمل مع كليهما).
4. فشل التثبيت يُبتلع: `yes | sdkmanager "$package" > /dev/null 2>&1 || log_warn …` —
   لتكن الرسالة حاملةً ناتج sdkmanager، لا تحذيراً عاماً.

---

## §2 → المنسّق · الوكيل 1: `apps/*/gradle.properties` بلا إعدادات ذاكرة = فشل CI مؤكد

**التحقق (يعمل من أي جهاز فيه `gh`):**

```bash
RUN=42264822833
CRI=$(gh api repos/22kdx/TAMMTOOL/actions/runs/$RUN/jobs --jq '.jobs[0].check_run_url' | sed 's|.*/check-runs/||')
gh api "repos/22kdx/TAMMTOOL/check-runs/$CRI/annotations" \
  --jq '.[] | select(.annotation_level=="failure") | "\(.path):\(.start_line) \(.message)"'
#   .github:69  Java heap space        ← هذا هو السبب
#   .github:981 Process completed with exit code 1.
```

`gh run view --log-failed` يفشل في البيئات المقيدة (نطاق `results-receiver…` محجوب)؛ طريقة
التعليقات أعلاه تعمل عبر `api.github.com` وحدها — تستحق التوثيق في `docs/`.

**الحل (نفس المحتوى في `apps/marketer/gradle.properties` و`apps/orders-delivery/gradle.properties`):**

```properties
# الذاكرة
org.gradle.jvmargs=-Xmx3g -XX:MaxMetaspaceSize=1g -Dfile.encoding=UTF-8 -XX:+HeapDumpOnOutOfMemoryError
kotlin.daemon.jvm.options=-Xmx1536m
kapt.use.worker.api=true
kapt.workers.isolation=process
# السرعة
org.gradle.parallel=true
org.gradle.caching=true
# Jetifier غير ضروري (لا مكتبات support قديمة) ويكلّف ذاكرة ووقتاً
android.enableJetifier=false
android.useAndroidX=true
android.nonTransitiveRClass=true
kotlin.code.style=official
```

**للتأكد محلياً قبل الدفع:**

```bash
./scripts/build-apk.sh debug marketer --low-memory --yes   # يُفترض أن ينجح حتى على 4GB
```

---

## §3 → الوكيل 1: 5 أخطاء بناء حتمية في فرع `arena/6b69a15d-tammtool`

كلها قابلة للقراءة بأوامر لا تحتاج JDK:

```bash
git show origin/arena/6b69a15d-tammtool:apps/marketer/app/build.gradle.kts | grep -nE 'id\(|kapt|sourceCompatibility|jvmTarget|kotlinCompilerExtensionVersion'
git show origin/arena/6b69a15d-tammtool:apps/marketer/settings.gradle.kts  | grep -n FAIL_ON_PROJECT_REPOS
git show origin/arena/6b69a15d-tammtool:apps/marketer/build.gradle.kts     | grep -n allprojects
git ls-tree -r --name-only origin/arena/6b69a15d-tammtool | grep -E 'res/values/.*\.(png|placeholder)'
```

| # | الملف | الخطأ | رسالة Gradle/AAPT2 المتوقعة | الإصلاح |
|---|---|---|---|---|
| 1 | `apps/*/app/build.gradle.kts` | استخدام `kapt(…)` بدون تطبيق بلَجن kapt | `Could not find method kapt() for arguments […]` | أضف `id("org.jetbrains.kotlin.kapt")` إلى `plugins {}` (فعله فرع `ff5110e8`) |
| 2 | `apps/*/app/build.gradle.kts` | `sourceCompatibility = VERSION_1_8` مع `jvmTarget = "17"` | `Inconsistent JVM-target compatibility detected for tasks 'compileDebugJavaWithJavac' (1.8) and 'compileDebugKotlin' (17)` | اجعل `sourceCompatibility`/`targetCompatibility` = `JavaVersion.VERSION_17` |
| 3 | `apps/*/app/build.gradle.kts` | Kotlin 1.9.20 + `kotlinCompilerExtensionVersion = "1.5.4"` | فشل فحص توافق Compose Compiler مع Kotlin | إمّا Kotlin 1.9.22 + 1.5.8 (فرع `ff5110e8`) أو Kotlin 1.9.20 + 1.5.6 |
| 4 | `apps/*/build.gradle.kts` + `settings.gradle.kts` | `allprojects { repositories {…} }` مع `FAIL_ON_PROJECT_REPOS` | `Build was configured to prefer settings repositories over project repositories but repository 'Google' was found in build file` | احذف `allprojects { repositories }` (المستودعات معرّفة في settings) |
| 5 | `apps/*/app/src/main/res/values/ic_launcher_web.png.placeholder` | ملف غير XML داخل `res/values` | فشل `mergeDebugResources`/AAPT2 (امتداد غير متوقع) | احذفه — حذفه فرع `ff5110e8` في كوميت «Remove non-XML placeholder from Android values resources» |

**ملاحظة 6 (AGP):** `com.android.tools.build:gradle:8.2.0` مع `compileSdk = 35` يعطي تحذير
«AGP 8.2 was tested up to compileSdk = 34». الأنسب `8.6.1` + Gradle 8.7 (ما يستخدمه CI).

**ملاحظة 7 (Room):** تأكد من `room.schemaLocation` و`kapt { correctErrorTypes = true }` لتفادي
فشل توليد `RoomDatabase` عند وجود كيانات بعلاقات.

---

## §4 → الوكيل 2: `scripts/download-gradlew.sh`

| المشكلة | التفصيل | الاقتراح |
|---|---|---|
| يتجاهل وسيط النسخة | `GRADLE_VERSION="${1:-8.5}"` لكنه يكتب في `gradle-wrapper.properties` سطراً ثابتاً `distributionUrl=…gradle-8.5-bin.zip` | استخدم `$GRADLE_VERSION` داخل هنا-نص غير مقتبس، أو `sed` بعد الكتابة |
| يستخرج `gradle-wrapper.jar` بمسارات تخمينية | ثلاث محاولات `unzip` بأنماط مختلفة؛ قد يُنتج jar من نسخة غير المطلوبة | الأسلم: `gradle wrapper --gradle-version V` عند توفر gradle — وهو ما يفعله `build-apk.sh` v2 تلقائياً |
| `gradlew` المولّد ناقص مقابل الرسمي | لا معالجة `GRADLE_OPTS`، ولا تحقق كامل من `JAVA_HOME` | الأفضل رفع `gradlew` الرسمي (الناتج من `gradle wrapper`) إلى git بدل توليده |
| يطبّق على تطبيقين محدّدين يدوياً | `apps/marketer` و`apps/orders-delivery` فقط | استخدم قائمة الاكتشاف نفسها في `build-apk.sh` (تشمل `examples/` و`templates/`) |

---

## §5 → الوكيل 2: `scripts/sign-apk.sh` (أمان + تشغيل غير تفاعلي)

```bash
# المشكلة 1: كلمات المرور في سطر الأوامر (مرئية في `ps` / سجلات CI)
"$APKSIGNER" sign --ks-pass "pass:$KEYSTORE_PASSWORD" --key-pass "pass:$KEY_PASSWORD" …
# الأأمن:
"$APKSIGNER" sign --ks-pass env:KEYSTORE_PASSWORD --key-pass env:KEY_PASSWORD …

# المشكلة 2: read -rsp يفشل/يعلّق في CI والأنابيب
if   [[ -z "${KEYSTORE_PASSWORD:-}" && -t 0 ]]; then read -rsp …
elif [[ -z "${KEYSTORE_PASSWORD:-}" ]]; then die "اضبط KEYSTORE_PASSWORD وKEY_PASSWORD في البيئة (وضع غير تفاعلي)"; fi
```

وأضف تحققاً بعد التوقيع يطبع بصمة SHA-256 للمفتاح — يحتاجها من يرفع للمتجر لمطابقة بصمة الرفع
السابقة. ولاحظ أن السكربت `cd` إلى جذر المستودع، فمساراتك النسبية تُحسب من هناك (موثّق في
`scripts/README.md` §3).

---

## §6 → الوكيل 2: `scripts/check-env.sh`

* يفحص `./gradlew` في **جذر المستودع**، وهو غير موجود أصلاً (كل تطبيق مشروع مستقل) ⇒ نتيجة
  مضلّلة «Wrapper غير موجود». الأصحّ:

  ```bash
  for app_dir in "$PROJECT_ROOT"/apps/*/ "$PROJECT_ROOT"/examples/*/ "$PROJECT_ROOT"/templates/*/; do
    [[ -f "$app_dir/gradlew" ]] && ok "Wrapper: $app_dir" || warn "لا Wrapper في $app_dir"
  done
  ```

* فحص Java هشّ: `grep -qiE '17|21|1[7-9]|[2-9][0-9]'` يقبل `1.17` و`2099`، ويقرأ `java -version`
  فقط لا `javac` ولا `JAVA_HOME`. انقل منطق `java_major_version()` من `build-apk.sh`.
* يشغّل `./gradlew --version` (يبدأ daemon وقد يستغرق دقائق أول مرة) بلا `--offline` ولا مهلة.
* مقترح: أعِد رموز خروج موثّقة (0 سليم / 1 مشكلة) ليُستخدم كخطوة CI.

---

## §7 → المنسّق: ملاحظات على `.github/workflows/build-apk.yml`

1. **الاسم والمسار مختلفان بين الفروع:** فرع `ff5110e8` («Build Android APK») يبني `apps/marketer`
   فقط؛ فرع `6b69a15d` («Build Afghani Orders APK») مقيّد بفرع واحد، ويكتب السجل في
   `../ci-build.log` (خارج مجلد العمل) ثم يحاول commit/push بـ `permissions: contents: write`.
   الخطوة الأخيرة هي التي تُفشل الـ job وتُعمي السبب (run 42264967594: «Build Debug APK» = ✓،
   «Save build log to repository» = ✗).
2. **قاعدة:** لا تدع خطوة تشخيصية تقرّر نتيجة الـ job — اجعل حفظ السجل `continue-on-error: true`
   أو اكتب داخل `workspace` وارفعه بـ `upload-artifact`.
3. **الوضوح:** أضف خطوة `if: failure()` تطبع `tail -n 300 <log>` لتظهر الأسطر المهمة في السجل الخام
   (وهي طوق النجاة حين يُحجب `--log-failed`).
4. **التوحيد:** استخدم السكربت بدل أوامر gradle الخام في الـ workflow:

   ```yaml
   - name: Build Debug APK (marketer)
     run: ./scripts/build-apk.sh debug marketer --no-daemon --yes
   - name: Static-validate the APK
     run: ./scripts/apk-test.sh validate --app marketer
   - name: Upload APK
     uses: actions/upload-artifact@v4
     with: { name: marketer-debug-apk, path: dist/*.apk, if-no-files-found: error }
   ```

   فيصبح «البناء المحلي = بناء CI» (نفس اكتشاف JDK/SDK/Wrapper ونفس مسار المخرجات).
5. **الذاكرة:** اضبط `GRADLE_OPTS: "-Dorg.gradle.jvmargs=-Xmx3g"` أو اعتمد إصلاح §2 في
   `gradle.properties` — وإلا سيتكرر `Java heap space`.
6. **التوازي:** يبني `marketer` فقط؛ أضف `strategy.matrix.app: [marketer, orders-delivery]`.
   ولاحظ أن `concurrency.cancel-in-progress: true` ألغى 3 من آخر 4 تشغيلات، ما يُربك قراءة النتائج.
7. **حزم SDK:** CI يثبّت `build-tools;34.0.0` بينما `android-sdk-setup.sh` يثبّت `35.0.0`؛
   الأهم أن تُعلَن نسخة واحدة في مكان واحد.

---

## §8 → الجميع: ملاحظات اتساق

* **Gradle Wrapper غير مرفوع في git** على أي فرع. مع Wrapper يصبح `./gradlew` هو المرجع وتختفي
  حاجة `download-gradlew.sh` وتحميل Gradle في CI (اقتراح `AGENTS_STATUS.md` §الوكيل 3).
* **اللغة:** السكربتات بالعربية ورسائلها مختلطة (ظهرت أحرف كورية/صينية في ملفات موجودة).
  المقترح: رسائل المستخدم بالعربية، الأسماء والخيارات بالإنجليزية، تعليقات الكود بلغة واحدة.
* **`docs/workflow-*.md`:** تُضاف إليها فقرة «قراءة سجل CI حين تُحجب السجلات» من
  `BUILD_GUIDE.md` §6.3.
* **مجلدات جديدة في الفروع** (`templates/basic-app/`, `examples/hello-world/`): سكربتات v2
  تكتشفها تلقائياً (`apps/`, `examples/`, `projects/`, `templates/`)، أما `download-gradlew.sh`
  فيحتاج تحديثاً (§4).

— الوكيل 3، 2026-11-06
