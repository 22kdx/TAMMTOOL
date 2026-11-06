#!/usr/bin/env bash
#
# scaffold-filter-app.sh — ينشئ «تطبيق الفلتر» من القالب المخزّن في المستودع
# جزء من TAMMTOOL · أدوات الوكيل 3 · إصدار 1.0.0
#
# القالب (لا نسخة معدّلة منه بعد التوليد) في tools/filter-app-template — اقرأه كما هو:
# كل ملف فيه مكتوب ليُقرأ ويُراجَع، ومعه فحص بنيوي (tools/verify-filter-app.sh) لأن
# الترجمة غير متاحة في كل بيئات الوكلاء.
#
# الاستخدام:
#   ./tools/scaffold-filter-app.sh                      # → apps/filter
#   ./tools/scaffold-filter-app.sh --into apps/camera   # اسم/مسار آخر
#   ./tools/scaffold-filter-app.sh --package com.tamm.studio --label "تمّ ستوديو"
#   ./tools/scaffold-filter-app.sh --wrapper --verify   # + gradle wrapper + فحص بنيوي
#   ./tools/scaffold-filter-app.sh --print-manifest     # طباعة ما سيُنشأ بلا كتابة
#   ./tools/scaffold-filter-app.sh --dry-run
#
# خيارات:
#   --into DIR       مجلد الهدف (افتراضي apps/filter) — إن وُجد يلزم --replace
#   --package PKG    تغيير namespace/applicationId وحزم المجلدات (افتراضي com.tammtool.filterapp)
#   --label TEXT      نص app_name الإنجليزي (ar يبقى «تمّ فلتر» ما لم تُغيّره)
#   --wrapper        يستدعي install-gradle-wrapper.sh للهدف (يزرع gradlew/gradle-wrapper.jar)
#   --verify         يشغّل tools/verify-filter-app.sh --gate بعد التوليد
#   --force-apps-ci  يطبع ما يجب إضافته إلى matrix الـ workflow (لا يعدّل .github)
#   --dry-run        طباعة بلا كتابة
#   -h|--help        المساعدة
#
# رموز الخروج: 0 نجاح · 1 فشل فحص · 2 خطأ استخدام/هدف موجود
#
set -euo pipefail
VERSION="1.0.0"
SCRIPT_PATH="${BASH_SOURCE[0]}"
while [[ -L "$SCRIPT_PATH" ]]; do SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"; done
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE="$SCRIPT_DIR/filter-app-template"

GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'; RED=$'\033[0;31m'; NC=$'\033[0m'
log_info() { printf '%s[i]%s %s\n' "$YELLOW" "$NC" "$*"; }
log_ok()   { printf '%s[✓]%s %s\n' "$GREEN" "$NC" "$*"; }
log_err()  { printf '%s[✗]%s %s\n' "$RED" "$NC" "$*" >&2; }

INTO="$PROJECT_ROOT/apps/filter"
PKG="com.tammtool.filterapp"
LABEL=""
DO_WRAPPER=0
DO_VERIFY=0
DO_PRINT=0
DRY=0
REPLACE=0
CI_NOTE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --into)     [[ $# -ge 2 ]] || { log_err "--into يحتاج مساراً"; exit 2; }; INTO="$2"; shift 2 ;;
    --package)  [[ $# -ge 2 ]] || { log_err "--package يحتاج معرّفاً (com.x.y)"; exit 2; }; PKG="$2"; shift 2 ;;
    --label)    [[ $# -ge 2 ]] || { log_err "--label يحتاج نصاً"; exit 2; }; LABEL="$2"; shift 2 ;;
    --wrapper)  DO_WRAPPER=1; shift ;;
    --verify)   DO_VERIFY=1; shift ;;
    --replace)  REPLACE=1; shift ;;
    --print-manifest) DO_PRINT=1; shift ;;
    --force-apps-ci)  CI_NOTE=1; shift ;;
    --dry-run)  DRY=1; shift ;;
    --version)  echo "scaffold-filter-app.sh v$VERSION"; exit 0 ;;
    -h|--help)  sed -n '3,28p' "$SCRIPT_PATH" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) log_err "وسيط غير معروف: $1  (جرّب --help)"; exit 2 ;;
  esac
done

[[ -d "$TEMPLATE" ]] || { log_err "لا قالب: $TEMPLATE"; exit 2; }
[[ "$PKG" =~ ^[a-z][a-z0-9_]*(\.[a-z0-9_]+){1,}$ ]] || { log_err "--package غير صالح: $PKG (أحرف صغيرة، نقطتان على الأقل)"; exit 2; }
[[ -z "$LABEL" || ! "$LABEL" =~ [\"\\] ]] || { log_err "--label لا يقبل علامات تنصيص أو الشرطة المائلة"; exit 2; }

rel="${INTO#$PROJECT_ROOT/}"
mapfile -t FILES < <(cd "$TEMPLATE" && find . -type f | sed 's|^\./||' | sort)

if [[ $DO_PRINT -eq 1 ]]; then
  echo "القالب: ${TEMPLATE#$PROJECT_ROOT/}  ←  الهدف: $rel  (package: $PKG)"
  printf '  %s\n' "${FILES[@]}"
  echo "الإجمالي: ${#FILES[@]} ملفاً"
  exit 0
fi

if [[ -e "$INTO" && $REPLACE -eq 0 ]]; then
  log_err "الهدف موجود: $rel — استخدم --replace للاستبدال (أو احذفه). لن أكتب فوق شيفرة غيري بصمت."
  exit 2
fi

log_info "توليد ${#FILES[@]} ملفاً إلى $rel"
if [[ $DRY -eq 1 ]]; then
  printf '[dry-run] mkdir -p %s && cp القالب ثم استبدال الحزمة\n' "$rel"
  exit 0
fi

SRC_ROOT="$TEMPLATE" python3 - "$TEMPLATE" "$INTO" "$PKG" "$LABEL" <<'PY'
import pathlib, re, shutil, sys
args = sys.argv[1:]
tpl, out = pathlib.Path(args[0]), pathlib.Path(args[1])
pkg = args[2]
label = args[3] if len(args) > 3 and args[3] else "TAMM Filter"
out.mkdir(parents=True, exist_ok=True)
old_pkg = 'com.tammtool.filterapp'
old_path = old_pkg.replace('.', '/')
new_path = pkg.replace('.', '/')
moved = 0
for f in sorted(p for p in tpl.rglob('*') if p.is_file()):
    rel = f.relative_to(tpl)
    text = f.read_text(encoding='utf-8')
    rel_s = str(rel).replace(old_path, new_path)
    if old_pkg in text or (label != "TAMM Filter" and 'TAMM Filter' in text):
        text = text.replace(old_pkg, pkg)
        if label != "TAMM Filter":
            text = text.replace('>TAMM Filter<', '>%s<' % label)
    dest = out / rel_s
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(text, encoding='utf-8')
    moved += 1
gp = out / 'gradlew'
if gp.exists():
    gp.chmod(0o755)
print('  ✓ %d ملف كُتبت (الحزمة: %s)' % (moved, pkg))
PY

if [[ $DO_WRAPPER -eq 1 ]]; then
  "$SCRIPT_DIR/install-gradle-wrapper.sh" --into "$INTO" || log_info "تعذّر تركيب الـ wrapper — راجع tools/install-gradle-wrapper.sh --help"
fi

if [[ $DO_VERIFY -eq 1 ]]; then
  "$SCRIPT_DIR/verify-filter-app.sh" --dir "$INTO" --gate || { log_err "الفحص البنيوي فشل — أصلح قبل الطلب من CI"; exit 1; }
fi

cat <<EOF
$(printf '%s[✓]%s تطبيق الفلتر جاهز للمحاولة الأولى: %s\n' "$GREEN" "$NC" "$rel")

البناء (يحتاج JDK 17 + Android SDK؛ لا يحتاج wrapper بفضل TAMM_GRADLE_BIN):
  TAMM_GRADLE_BIN=gradle ./scripts/build-apk.sh debug filter --yes
  ./scripts/apk-test.sh validate --app filter
  ./scripts/build-apk.sh unit-test filter --yes

للاختبار على هاتف حقيقي (عرض + تسجيل للشاشة):
  ./scripts/apk-test.sh test --app filter --reinstall
  ./tools/install-toolchain.sh --install scrcpy && eval "\$(./tools/install-toolchain.sh --emit-env)" && scrcpy --record filter.mp4
EOF

if [[ $CI_NOTE -eq 1 ]]; then
  cat <<'NOTE'

ما على الوكيل 0 إضافته لبناء تطبيق الفلتر في CI (ملفه هو، لا ألمسه):
  strategy.matrix.app: [marketer, orders-delivery, filter]
ملاحظة: build-apk.sh يكتشف apps/* تلقائياً، وworkflow يحتاج الاسم في matrix فقط.
NOTE
fi
