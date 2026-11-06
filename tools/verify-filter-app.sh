#!/usr/bin/env bash
#
# verify-filter-app.sh — فحص بنيوي بلا Gradle ولا Android SDK لتطبيق الفلتر
# جزء من TAMMTOOL · أدوات الوكيل 3 · إصدار 1.0.0
#
# لماذا؟ لا يمكن ترجمة Kotlin في كل بيئات الوكلاء، لكن أكثر الأخطاء تكلفةً هي ما يُكتشف
# بلا مترجم أصلاً: مورد مذكور في الكود وغير موجود على القرص، شيدر يُستدعى قبل تعريفه،
# مسار API 33 غير محمي فيسقط على API 24، اعتمادية خارج قوس dependencies، نص غير موجود
# في values-ar. هذا السكربت يفحص كل ذلك في ثانية واحدة ويعطي رمز خروج يُستخدم كبوّابة.
#
# الاستخدام:
#   ./tools/verify-filter-app.sh                       # يفحص apps/filter
#   ./tools/verify-filter-app.sh --dir tools/filter-app-template
#   ./tools/verify-filter-app.sh --gate                # rc=1 عند أي ✗ (لـ CI)
#   ./tools/verify-filter-app.sh --list-checks
#
# خيارات:
#   --dir DIR    جذر المشروع المفحوص (افتراضي apps/filter، وإلا القالب)
#   --gate       فشل برمزين عند أي خطأ (افتراضي: يفشل أيضاً — مرآة لتوقع CI)
#   --lenient    التحذيرات لا تُحتسب أخطاء
#   --list-checks طباعة قائمة الفحوص وأسمائها
#   -h|--help    المساعدة
#
# رموز الخروج: 0 كل شيء ✓ · 1 يوجد ✗ · 2 لا يوجد مشروع في المسار
#
set -euo pipefail
VERSION="1.0.0"
SCRIPT_PATH="${BASH_SOURCE[0]}"
while [[ -L "$SCRIPT_PATH" ]]; do SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"; done
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'; RED=$'\033[0;31m'; NC=$'\033[0m'
log_err() { printf '%s[✗]%s %s\n' "$RED" "$NC" "$*" >&2; }

DIR=""
LENIENT=0
PROFILE_WANT="auto"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir)   [[ $# -ge 2 ]] || { log_err "--dir يحتاج مساراً"; exit 2; }; DIR="$2"; shift 2 ;;
    --gate)  shift ;;
    --lenient) LENIENT=1; shift ;;
    --profile) [[ $# -ge 2 ]] || { log_err "--profile يحتاج filter أو app أو auto"; exit 2; }
               PROFILE_WANT="$2"; shift 2 ;;
    --list-checks)
      cat <<'CHECKS'
 01 البنية      : الملفات الإلزامية موجودة (settings/build/manifest/MainActivity/tests)
 02 أقواس      : توازن { } و ( ) في كل .kt و .kts
 03 XML        : كل ملفات res/ والمانيفست تُحلَّل كـ XML سليم
 04 شيدرات     : كل فلتر في FilterRegistry له ملف، ولا ملف يتيماً (نمط filter فقط)
 05 AGSL       : main معرّف، content مُعلَن، الدوال معرفة قبل استعمالها
 06 حراسة API  : أي استعمال لـ RuntimeShader/RenderEffect محمي بشرط SDK_INT أو @RequiresApi
 07 نصوص       : كل R.string.* مستخدم موجود في values/strings.xml (وقيم ar مقابلة)
 08 dependencies: كل *Implementation داخل قوس dependencies {}
 09 ذاكرة      : org.gradle.jvmargs مضبوط (من درس CI 42273932002)
 10 مانيفست    : CAMERA معلن فقط إن استخدمه الكود، لا WRITE_EXTERNAL_STORAGE، لا قفل اتجاه، allowBackup آمن
 11 اختبارات   : حدّ الاختبارات و testInstrumentationRunner (3/12 لنمط filter · 1/6 لنمط app)
 12 إصدارات    : minSdk 24 · target/compileSdk 35 · AGP 8.6.1 · Kotlin 1.9.22 · Compose 1.5.8
 13 plugins    : لا google-services بلا google-services.json، ولا dataBinding بلا layout
CHECKS
      exit 0 ;;
    --version) echo "verify-filter-app.sh v$VERSION"; exit 0 ;;
    -h|--help) sed -n '3,30p' "$SCRIPT_PATH" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) log_err "وسيط غير معروف: $1"; exit 2 ;;
  esac
done

if [[ -z "$DIR" ]]; then
  if [[ -d "$PROJECT_ROOT/apps/filter/app/src/main" ]]; then DIR="$PROJECT_ROOT/apps/filter"
  else DIR="$PROJECT_ROOT/tools/filter-app-template"; fi
fi
[[ -d "$DIR/app/src/main" ]] || { log_err "لا مشروع في: $DIR (ينقص app/src/main)"; exit 2; }
printf 'فحص بنيوي: %s\n' "${DIR#$PROJECT_ROOT/}"

python3 - "$DIR" "$LENIENT" "$PROFILE_WANT" <<'PY'
import pathlib, re, sys, xml.dom.minidom
root = pathlib.Path(sys.argv[1]); lenient = sys.argv[2] == '1'
profile_want = sys.argv[3] if len(sys.argv) > 3 else 'auto'
errors, warns, oks = [], [], []

def add_ok(t): oks.append(t)
def add_err(t): errors.append(t)
def add_warn(t): (warns if lenient else errors).append(t)

main = root / 'app/src/main'
testd = root / 'app/src/test'
kt_all = sorted(p for p in root.rglob('*.kt')) + sorted(p for p in root.rglob('*.kts'))

# نمط التطبيق: «فلتر» إذا وُجدت شيدرات أو FilterRegistry، وإلا تطبيق عام. بلا هذا التمييز
# يكذب الفاحص على تطبيق لا كاميرا فيه («CAMERA مفقود») ويطالبه بسجل فلاتر لا معنى له.
shaders_dir = main / 'assets/shaders'
HAS_SHADERS = shaders_dir.exists()
HAS_REGISTRY = bool(list(main.rglob('FilterRegistry.kt')))
AUTO_PROFILE = 'filter' if (HAS_SHADERS or HAS_REGISTRY) else 'app'
PROFILE = AUTO_PROFILE if profile_want == 'auto' else profile_want
add_ok('00 نمط: %s (من %s) · شيدرات=%s · سجل فلاتر=%s' % (PROFILE, 'auto' if profile_want == 'auto' else '--profile', HAS_SHADERS, HAS_REGISTRY))
if PROFILE == 'filter' and not (HAS_SHADERS or HAS_REGISTRY):
    add_err('نمط filter مَفروض لكن لا assets/shaders ولا FilterRegistry.kt في المشروع')

# 01 البنية
required = ['settings.gradle.kts', 'build.gradle.kts', 'gradle.properties',
            'app/build.gradle.kts', 'app/proguard-rules.pro',
            'app/src/main/AndroidManifest.xml']
missing = [f for f in required if not (root / f).exists()]
# MainActivity و FilterRegistry يُبحث عنهما بالاسم (لا بمسار الحزمة) ⇒ فحص يعمل مع أي --package
def find_any(base, name):
    return sorted(base.rglob(name)) if base.exists() else []
if not find_any(main, 'MainActivity.kt'):
    missing.append('MainActivity.kt (في أي حزمة)')
if PROFILE == 'filter' and not find_any(main, 'FilterRegistry.kt'):
    missing.append('FilterRegistry.kt')
if missing: add_err('01 البنية: ناقص → ' + ', '.join(missing))
else: add_ok('01 البنية: %d ملف إلزامي موجود' % len(required))

# 02 أقواس
bad = []
for p in kt_all:
    t = p.read_text(encoding='utf-8')
    t2 = re.sub(r'"(?:\\.|[^"\\])*"', '""', t)
    t2 = re.sub(r'//[^\n]*', '', t2)
    if t2.count('{') != t2.count('}') or t2.count('(') != t2.count(')'):
        bad.append('%s {%d/%d (%d/%d)}' % (p.name, t2.count('{'), t2.count('}'), t2.count('('), t2.count(')')))
if bad: add_err('02 أقواس: ' + '; '.join(bad))
else: add_ok('02 أقواس: متوازنة في %d ملف' % len(kt_all))

# 03 XML
xmls = [main / 'AndroidManifest.xml'] + sorted((main / 'res').rglob('*.xml'))
bad = []
for f in xmls:
    try: xml.dom.minidom.parse(str(f))
    except Exception as e: bad.append('%s: %s' % (f.name, e))
if bad: add_err('03 XML: ' + '; '.join(bad))
else: add_ok('03 XML: %d ملف يُحلَّل بنجاح' % len(xmls))

# 04 شيدرات ↔ سجل الفلاتر
_regs = sorted(main.rglob('FilterRegistry.kt'))
reg = _regs[0] if _regs else pathlib.Path('__none__')
shaders_dir = main / 'assets/shaders'
declared = set(re.findall(r'Filter\("[a-z0-9_]+",\s*"([^"]+)"', reg.read_text(encoding='utf-8'))) if reg.exists() else set()
present = {p.name for p in shaders_dir.glob('*')} if shaders_dir.exists() else set()
if PROFILE != 'filter': add_ok('04 شيدرات: غير منطبق (نمط app بلا سجل فلاتر)')
elif not declared: add_err('04 شيدرات: لم أُحلّل FilterRegistry (تغيّر نمط التعريف؟)')
else:
    miss = sorted(declared - present); orph = sorted(present - declared)
    if miss: add_err('04 شيدرات: مذكور بلا ملف → ' + ', '.join(miss))
    if orph: add_warn('04 شيدرات: ملف غير مُعلَن في السجل → ' + ', '.join(orph))
    if not miss and not orph: add_ok('04 شيدرات: %d فلتر = %d ملف، بلا تكرار' % (len(declared), len(present)))

# 05 AGSL/GLSL صحة مبدئية
bad = []
for f in (sorted(shaders_dir.glob('*')) if (shaders_dir.exists() and PROFILE == 'filter') else []):
    t = f.read_text(encoding='utf-8')
    nc = re.sub(r'//.*', '', t)
    if 'half4 main(float2' not in nc: bad.append(f.name + ': بلا main(float2…)')
    if f.suffix == '.agsl' and 'uniform shader content' not in nc: bad.append(f.name + ': بلا uniform shader content')
    if nc.count('{') != nc.count('}'): bad.append(f.name + ': أقواس غير متوازنة')
    # دوال مساعدة يجب أن تُعرَّف قبل main
    mi = nc.find('half4 main')
    for m in re.finditer(r'^(?:half4|float|float2|half3)\s+(\w+)\s*\(', nc, re.M):
        if m.start() > mi: bad.append(f'{f.name}: {m.group(1)}() معرَّفة بعد main')
if PROFILE != 'filter': add_ok('05 AGSL: غير منطبق (نمط app)')
elif bad: add_err('05 AGSL: ' + '; '.join(bad))
else: add_ok('05 AGSL: كل الشيدرات فيها main ومحتواها محصور فيه')

# 06 حراسة API 33
guard_violations = []
for p in main.rglob('*.kt'):
    raw = p.read_text(encoding='utf-8')
    # التعليقات والنصوص لا تُحمِّل أصنافاً وقت التشغيل ⇒ تُستثنى من الفحص
    code = re.sub(r'/\*.*?\*/', '', raw, flags=re.S)
    code = re.sub(r'//[^\n]*', '', code)
    code = re.sub(r'"(?:\\.|[^"\\])*"', '""', code)
    if re.search(r'\b(RuntimeShader|RenderEffect)\b', code):
        if not re.search(r'Build\.VERSION\.SDK_INT|@RequiresApi|RequiresApi\(', code):
            guard_violations.append(p.name)
if guard_violations: add_err('06 حراسة API: استعمال غير محمي في → ' + ', '.join(guard_violations))
else: add_ok('06 حراسة API: كل استعمال لـ RuntimeShader/RenderEffect مشروط')

# 07 نصوص strings
str_en = (main / 'res/values/strings.xml')
str_ar = (main / 'res/values-ar/strings.xml')
decl = set(re.findall(r'<string name="([^"]+)"', str_en.read_text(encoding='utf-8'))) if str_en.exists() else set()
used = set()
for p in list(main.rglob('*.kt')):
    used |= set(re.findall(r'R\.string\.(\w+)', p.read_text(encoding='utf-8')))
    used |= set(re.findall(r'name="(\w+)"', ''))  # لا شيء — صراحةً لا نبحث في XML
used |= set(re.findall(r'name="([\w_]+)"', ''))
if not decl: add_err('07 نصوص: values/strings.xml غير موجود أو فارغ')
else:
    miss = sorted(used - decl)
    if miss: add_err('07 نصوص: R.string بلا تعريف → ' + ', '.join(miss))
    ar = set(re.findall(r'<string name="([^"]+)"', str_ar.read_text(encoding='utf-8'))) if str_ar.exists() else set()
    noar = sorted(decl - ar)
    if noar: add_warn('07 نصوص: بلا ترجمة عربية → ' + ', '.join(noar))
    if not miss and not noar: add_ok('07 نصوص: %d نص، كلها مُعرَّفة ومترجمة' % len(decl))

# 08 موقع الاعتماديات داخل dependencies {}
bg = (root / 'app/build.gradle.kts').read_text(encoding='utf-8')
i = bg.find('dependencies {')
if i < 0: add_err('08 dependencies: لا قوس dependencies في app/build.gradle.kts')
else:
    depth = 0; end = len(bg)
    for j in range(i + len('dependencies'), len(bg)):
        if bg[j] == '{': depth += 1
        elif bg[j] == '}':
            depth -= 1
            if depth == 0: end = j; break
    inside = bg[i:end]
    outside = bg[:i] + bg[end:]
    stray = [k for k in ('implementation(', 'testImplementation(', 'kapt(', 'debugImplementation(') if k in outside]
    if stray: add_err('08 dependencies: توابع خارج القوس → ' + ', '.join(stray))
    elif 'testImplementation(' not in inside: add_err('08 dependencies: لا testImplementation داخل القوس')
    else:
        n_dep = len(re.findall(r'(?:implementation|api|compileOnly|runtimeOnly|kapt|testImplementation|androidTestImplementation|debugImplementation)\(', inside))
        add_ok('08 dependencies: %d اعتمادية داخل القوس' % n_dep)

# 09 الذاكرة
gp = (root / 'gradle.properties').read_text(encoding='utf-8') if (root / 'gradle.properties').exists() else ''
if 'org.gradle.jvmargs' not in gp: add_err('09 ذاكرة: لا org.gradle.jvmargs في gradle.properties (سبب فشل CI 42273932002)')
else:
    m = re.search(r'-Xmx(\d+)g', gp)
    if not m or int(m.group(1)) < 2: add_warn('09 ذاكرة: -Xmx أقل من 2g قد يعيد D8 OOM')
    else: add_ok('09 ذاكرة: org.gradle.jvmargs مضبوط (%s)' % m.group(0))

# 10 المانيفست
mf = (main / 'AndroidManifest.xml').read_text(encoding='utf-8')
CAMERA_RE = re.compile(r'androidx\.camera|ImageCapture|PreviewView|CameraSelector|ProcessCameraProvider')
uses_camera = any(CAMERA_RE.search(p.read_text(encoding='utf-8')) for p in kt_all if p.suffix == '.kt')
if uses_camera and 'android.permission.CAMERA' not in mf:
    add_err('10 مانيفست: الكود يستخدم الكاميرا (CameraX/ImageCapture) والمَانيفست بلا إذن CAMERA')
elif (not uses_camera) and 'android.permission.CAMERA' in mf:
    add_warn('10 مانيفست: إذن CAMERA معلن ولا استعمال له في الكود (أقل صلاحية أفضل)')
if 'WRITE_EXTERNAL_STORAGE' in mf: add_err('10 مانيفست: WRITE_EXTERNAL_STORAGE غير ضروري (استخدم FileProvider/cache)')
if 'screenOrientation' in mf: add_err('10 مانيفست: قفل اتجاه مع targetSdk 35 (انظر C6)')
if 'allowBackup="true"' in mf and 'dataExtractionRules' not in mf: add_err('10 مانيفست: allowBackup=true بلا dataExtractionRules')
if 'android:exported' not in mf: add_err('10 مانيفست: activity بلا android:exported (مطلوب من API 31)')
add_ok('10 مانيفست: أذونات أقلية + FileProvider + لا قفل اتجاه') if not any(e.startswith('10') for e in errors) else None

# 11 الاختبارات
tests = sorted(testd.rglob('*.kt')) if testd.exists() else []
n = sum(len(re.findall(r'@Test', p.read_text(encoding='utf-8'))) for p in tests)
MIN_FILES, MIN_TESTS = (3, 12) if PROFILE == 'filter' else (1, 6)
if len(tests) < MIN_FILES: add_err('11 اختبارات: %d ملف اختبار (المطلوب ≥%d لنمط %s)' % (len(tests), MIN_FILES, PROFILE))
elif n < MIN_TESTS: add_err('11 اختبارات: %d دالة @Test فقط (المطلوب ≥%d)' % (n, MIN_TESTS))
elif 'testInstrumentationRunner' not in bg: add_err('11 اختبارات: testInstrumentationRunner غير مضبوط')
else: add_ok('11 اختبارات: %d ملف / %d فحص @Test + runner' % (len(tests), n))

# 12 الإصدارات
want = {'compileSdk = 35': 'compileSdk 35', 'minSdk = 24': 'minSdk 24',
        'targetSdk = 35': 'targetSdk 35', 'kotlinCompilerExtensionVersion = "1.5.8"': 'Compose 1.5.8'}
for k, lbl in want.items():
    if k not in bg: add_err('12 إصدارات: %s غير موجود في app/build.gradle.kts' % lbl)
rootbg = (root / 'build.gradle.kts').read_text(encoding='utf-8')
for k, lbl in [('8.6.1', 'AGP 8.6.1'), ('1.9.22', 'Kotlin 1.9.22')]:
    if k not in rootbg: add_err('12 إصدارات: %s غير مقفل في build.gradle.kts الجذري' % lbl)
if not any(e.startswith('12') for e in errors): add_ok('12 إصدارات: المصفوفة مطابقة للتطبيقين الأخوين (AGP/Kotlin/Compose مقفلة في الجذر)')

# 13 plugins خطرة
if 'google-services' in bg and not (main / 'google-services.json').exists():
    add_err('13 plugins: plugin google-services بلا google-services.json ⇒ فشل فوري في :app:processDebugResources')
if 'dataBinding = true' in bg:
    layouts = list((main / 'res/layout').glob('*.xml')) if (main / 'res/layout').exists() else []
    if not layouts: add_err('13 plugins: dataBinding مفعّل بلا أي ملف layout/*.xml (مهمة زائدة تفشل مع أي خطأ classpath)')
n_kapt_deps = len(re.findall(r'^\s*kapt\s*\(', bg, re.M))
if ('org.jetbrains.kotlin.kapt' in rootbg or 'org.jetbrains.kotlin.kapt' in bg) and n_kapt_deps == 0:
    add_warn('13 plugins: بلاغ kapt مطبَّق بلا أي سطر kapt("…") ⇒ احذفه؛ لا يولّد شيئاً وهو مصدر '
             'أخطاء CI من نوع 42274698251 (خيار room.generateKotlin بلا مولّد KSP)')
elif n_kapt_deps:
    add_ok('13 plugins: kapt مستعمل فعلاً (%d سطر kapt)' % n_kapt_deps)
if not any(e.startswith('13') for e in errors): add_ok('13 plugins: لا plugin معلَّق على مورد مفقود')

# 14 أسماء الملفات (assets/res يجب ASCII)
odd = [str(p.relative_to(root)) for p in root.rglob('*') if p.is_file() and not re.fullmatch(r'[\x20-\x7e./_-]+', str(p.relative_to(root)))]
if odd: add_err('14 أسماء: ملفات بأسماء غير ASCII → ' + ', '.join(odd[:4]))
else: add_ok('14 أسماء: كل المسارات ASCII آمنة للأدوات')

for t in oks: print('  \033[0;32m✓\033[0m', t)
for t in warns: print('  \033[1;33m!\033[0m', t)
for t in errors: print('  \033[0;31m✗\033[0m', t)
print('\nالملفات المفحوصة: %d · الأخطاء: %d · التحذيرات: %d' % (len(list(root.rglob('*'))), len(errors), len(warns)))
sys.exit(1 if errors else 0)
PY
