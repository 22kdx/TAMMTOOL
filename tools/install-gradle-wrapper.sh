#!/usr/bin/env bash
#
# install-gradle-wrapper.sh — يزرع Gradle Wrapper في أي مشروع من النسخة المُخزَّنة في المستودع
# جزء من TAMMTOOL · أدوات الوكيل 3 · إصدار 1.0.0
#
# لماذا؟ لا يوجد gradle-wrapper.jar مرفوع في المستودع (الفجوة A3 في GAP_TO_APK.md)، و
# services.gradle.org محجوب في بعض البيئات، أما github.com/api.github.com فمتاح. لذلك نحتفظ
# بنسخة حقيقية من الـ wrapper (من وسم gradle/gradle@v8.7.0) داخل tools/vendor/، وهذا السكربت
# ينسخها إلى المشروع ويولّد gradle-wrapper.properties للنسخة المطلوبة.
#
# الاستخدام:
#   ./tools/install-gradle-wrapper.sh --into apps/filter            # مشروع واحد
#   ./tools/install-gradle-wrapper.sh --apps                        # كل مشاريع Gradle المكتشفة
#   ./tools/install-gradle-wrapper.sh --all                         # apps + examples + templates
#   ./tools/install-gradle-wrapper.sh --version 8.7 --into apps/marketer
#   ./tools/install-gradle-wrapper.sh --fetch 8.14.6                # يجلب وسم Gradle من GitHub API
#   ./tools/install-gradle-wrapper.sh --verify                      # فحص sha256 للمخزّن
#   ./tools/install-gradle-wrapper.sh --dry-run --apps
#
# خيارات:
#   --into DIR      مجلد المشروع (يحتوي settings.gradle*)
#   --apps          كل مشروع تحت apps/ فيه settings.gradle*
#   --all           كل مشروع تحت apps/ examples/ templates/ projects/
#   --version VER   نسخة التوزيع التي تشير إليها properties (افتراضي 8.7)
#   --force         يكتب فوق wrapper موجود
#   --fetch VER     تنزيل ملفات الـ wrapper من وسم gradle/gradle عبر gh api (يتطلب شبكة)
#   --verify        التحقق من sha256 مقابل manifest.json ثم الخروج
#   --print-env     طباعة المسارات والنسخ ثم الخروج
#   --dry-run       طباعة ما سيُفعَل بلا تنفيذ
#   -h | --help     المساعدة
#
# رموز الخروج: 0 نجاح · 1 خطأ استخدام/تحقق · 2 فشل الشبكة/gh
#
set -euo pipefail

VERSION="1.0.0"
SCRIPT_PATH="${BASH_SOURCE[0]}"
while [[ -L "$SCRIPT_PATH" ]]; do SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"; done
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

VENDOR_ROOT="$SCRIPT_DIR/vendor/gradle-wrapper"
GRADLE_DIST_VERSION="8.7"
TARGET=""
MODE="single"
FORCE=0
DRY=0
FETCH_TAG=""
DO_VERIFY=0
DO_PRINT_ENV=0

GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'; RED=$'\033[0;31m'; NC=$'\033[0m'
log_info()  { printf '%s[i]%s %s\n' "$YELLOW" "$NC" "$*"; }
log_ok()    { printf '%s[✓]%s %s\n' "$GREEN" "$NC" "$*"; }
log_err()   { printf '%s[✗]%s %s\n' "$RED" "$NC" "$*" >&2; }

usage() { sed -n '3,40p' "$SCRIPT_PATH" | sed 's/^# \{0,1\}//'; }

sha256_of() {
  local f="$1"
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$f" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then shasum -a 256 "$f" | awk '{print $1}'
  else python3 -c 'import hashlib,sys;print(hashlib.sha256(open(sys.argv[1],"rb").read()).hexdigest())' "$f"
  fi
}

discover_projects() {
  local root dir
  for root in $1; do
    [[ -d "$PROJECT_ROOT/$root" ]] || continue
    for dir in "$PROJECT_ROOT/$root"/*/; do
      [[ -f "${dir}settings.gradle" || -f "${dir}settings.gradle.kts" ]] && printf '%s\n' "${dir%/}"
    done
  done
  return 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --into)     [[ $# -ge 2 ]] || { log_err "--into يحتاج مساراً"; exit 1; }; TARGET="$2"; shift 2 ;;
    --apps)     MODE="apps"; shift ;;
    --all)      MODE="all"; shift ;;
    --version)  [[ $# -ge 2 ]] || { log_err "--version يحتاج نسخة"; exit 1; }; GRADLE_DIST_VERSION="$2"; shift 2 ;;
    --fetch)    [[ $# -ge 2 ]] || { log_err "--fetch يحتاج وسم (مثل 8.14.6)"; exit 1; }; FETCH_TAG="$2"; shift 2 ;;
    --force)    FORCE=1; shift ;;
    --verify)   DO_VERIFY=1; shift ;;
    --print-env) DO_PRINT_ENV=1; shift ;;
    --dry-run)  DRY=1; shift ;;
    -h|--help)  usage; exit 0 ;;
    --version-only) echo "install-gradle-wrapper.sh v$VERSION"; exit 0 ;;
    *) log_err "وسيط غير معروف: $1  (جرّب --help)"; exit 1 ;;
  esac
done

if [[ $DO_PRINT_ENV -eq 1 ]]; then
  echo "VENDOR_ROOT=$VENDOR_ROOT"
  echo "GRADLE_DIST_VERSION=$GRADLE_DIST_VERSION"
  echo "PROJECT_ROOT=$PROJECT_ROOT"
  for v in "$VENDOR_ROOT"/*/; do [[ -f "${v}gradlew" ]] && echo "vendored=$(basename "$v")"; done
  exit 0
fi

# ── التحقق من المخزون ────────────────────────────────────────────────────────
verify_vendor() {
  local vdir="$1" manifest="$vdir/manifest.json" rc=0 f
  [[ -f "$manifest" ]] || { log_err "لا manifest.json في $vdir"; return 1; }
  for f in gradlew gradlew.bat gradle/wrapper/gradle-wrapper.jar gradle/wrapper/gradle-wrapper.properties; do
    [[ -f "$vdir/$f" ]] || { log_err "مفقود: $f"; rc=1; continue; }
  done
  python3 - "$manifest" "$vdir" <<'PY' || rc=1
import hashlib, json, pathlib, sys
man = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding='utf-8'))
root = pathlib.Path(sys.argv[2])
bad = []
for rel, info in man.get('files', {}).items():
    p = root / rel
    if not p.exists():
        bad.append(f'{rel}: مفقود'); continue
    data = p.read_bytes()
    want = info.get('sha256', '')
    if rel.endswith('gradle-wrapper.properties'):
        continue   # أُعيد توليدها للنسخة الرسمية، فالحشو مختلف عمداً
    got = hashlib.sha256(data).hexdigest()
    if want and got != want:
        bad.append(f'{rel}: sha256 غير مطابق')
    if rel.endswith('.jar') and data[:2] != b'PK':
        bad.append(f'{rel}: ليس ملف ZIP صالحاً')
if bad:
    print('\n'.join('  ✗ ' + b for b in bad)); sys.exit(1)
print('  ✓ كل ملفات الـ vendor مطابقة للـ manifest')
PY
  return $rc
}

if [[ $DO_VERIFY -eq 1 ]]; then
  overall=0
  for vdir in "$VENDOR_ROOT"/*/; do
    [[ -d "$vdir" ]] || continue
    printf '%s\n' "── $(basename "$vdir")"
    verify_vendor "${vdir%/}" || overall=1
  done
  exit $overall
fi

# ── الجلب من GitHub API (لنسخة غير مخزّنة) ────────────────────────────────────
if [[ -n "$FETCH_TAG" ]]; then
  tag="$FETCH_TAG"; [[ "$tag" == v* ]] || tag="v$tag"
  out="$VENDOR_ROOT/${FETCH_TAG}"
  log_info "جلب ملفات الـ wrapper من gradle/gradle@$tag عبر gh api"
  if ! command -v gh >/dev/null 2>&1; then log_err "gh غير مثبت — لا يمكن --fetch"; exit 2; fi
  mkdir -p "$out/gradle/wrapper"
  for f in gradlew gradlew.bat gradle/wrapper/gradle-wrapper.jar gradle/wrapper/gradle-wrapper.properties; do
    if [[ $DRY -eq 1 ]]; then echo "[dry-run] gh api repos/gradle/gradle/contents/$f?ref=$tag → $out/$f"; continue; fi
    if ! gh api "repos/gradle/gradle/contents/$f?ref=$tag" --jq .content 2>/dev/null | base64 -d >"$out/$f"; then
      log_err "فشل جلب $f من $tag"; rm -rf "$out"; exit 2
    fi
  done
  if [[ $DRY -eq 0 ]]; then
    chmod +x "$out/gradlew" 2>/dev/null || true
    python3 - "$out" "$tag" <<'PY'
import hashlib, json, pathlib, sys
out, tag = pathlib.Path(sys.argv[1]), sys.argv[2]
files = ['gradlew', 'gradlew.bat', 'gradle/wrapper/gradle-wrapper.jar', 'gradle/wrapper/gradle-wrapper.properties']
meta = {}
for rel in files:
    b = (out / rel).read_bytes()
    meta[rel] = {'bytes': len(b), 'sha256': hashlib.sha256(b).hexdigest()}
(out / 'manifest.json').write_text(json.dumps(
    {'source': 'github.com/gradle/gradle', 'tag': tag, 'files': meta}, ensure_ascii=False, indent=2) + '\n',
    encoding='utf-8')
print('  ✓ manifest.json مكتوب')
PY
    log_ok "جُهّز المخزون: $out"
  fi
  exit 0
fi

# ── اختيار المشروع الهدف ──────────────────────────────────────────────────────
targets=()
case "$MODE" in
  single)
    [[ -n "$TARGET" ]] || { log_err "حدّد --into DIR أو --apps أو --all (جرّب --help)"; exit 1; }
    targets+=("$TARGET") ;;
  apps)  while IFS= read -r d; do targets+=("$d"); done < <(discover_projects "apps") ;;
  all)   while IFS= read -r d; do targets+=("$d"); done < <(discover_projects "apps examples templates projects") ;;
esac
[[ ${#targets[@]} -gt 0 ]] || { log_err "لم يُعثر على مشروع Gradle (settings.gradle*)"; exit 1; }

# ── إيجاد نسخة مخزّنة (أقرب نسخة ≤ المطلوبة؛ وإلا نولّد من 8.7.0) ───────────────
pick_vendor() {
  local best="" v
  for v in "$VENDOR_ROOT"/*/; do
    [[ -f "${v}gradle/wrapper/gradle-wrapper.jar" ]] || continue
    best="${v%/}"
  done
  printf '%s' "$best"
}
VENDOR_DIR="$(pick_vendor)"
[[ -n "$VENDOR_DIR" ]] || { log_err "لا يوجد مخزون تحت $VENDOR_ROOT — نفّذ: $0 --fetch 8.7.0"; exit 1; }
log_info "المخزون: ${VENDOR_DIR#$PROJECT_ROOT/} · نسخة التوزيع المستهدفة: $GRADLE_DIST_VERSION"

rc=0
for dir in "${targets[@]}"; do
  [[ -d "$dir" ]] || { log_err "المجلد غير موجود: $dir"; rc=1; continue; }
  wdir="$dir/gradle/wrapper"
  if [[ -f "$dir/gradlew" && $FORCE -eq 0 ]]; then
    log_ok "موجود مسبقاً (تخطّي): ${dir#$PROJECT_ROOT/} — استخدم --force للاستبدال"
    continue
  fi
  if [[ $DRY -eq 1 ]]; then
    echo "[dry-run] install wrapper → ${dir#$PROJECT_ROOT/}  (gradlew, gradlew.bat, gradle-wrapper.jar, properties=$GRADLE_DIST_VERSION)"
    continue
  fi
  mkdir -p "$wdir"
  cp "$VENDOR_DIR/gradle/wrapper/gradle-wrapper.jar" "$wdir/gradle-wrapper.jar"
  cp "$VENDOR_DIR/gradlew"     "$dir/gradlew"
  cp "$VENDOR_DIR/gradlew.bat" "$dir/gradlew.bat"
  chmod +x "$dir/gradlew"
  cat >"$wdir/gradle-wrapper.properties" <<EOF
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\\://services.gradle.org/distributions/gradle-${GRADLE_DIST_VERSION}-bin.zip
networkTimeout=10000
validateDistributionUrl=true
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF
  if [[ -f "$VENDOR_DIR/manifest.json" ]]; then
    cp "$VENDOR_DIR/manifest.json" "$wdir/gradle-wrapper-jar-manifest.json"
  fi
  log_ok "wrapper مهيّأ: ${dir#$PROJECT_ROOT/}  ($(wc -c <"$wdir/gradle-wrapper.jar") بايت jar)"
done

cat <<EOF

الخطوة التالية (اختياري) — إضافة الـ wrapper إلى git حتى لا يبنّي كل وكيل نسخته:
  git add -f ${targets[0]#$PROJECT_ROOT/}/gradlew ${targets[0]#$PROJECT_ROOT/}/gradle/wrapper/
ملاحظة: التوزيع نفسه يُنزَّل عند أول تشغيل من services.gradle.org؛ في بيئة بلا شبكة استخدم
  TAMM_GRADLE_BIN=gradle ./scripts/build-apk.sh debug <app> --yes   (لا يحتاج wrapper)
EOF
exit $rc
