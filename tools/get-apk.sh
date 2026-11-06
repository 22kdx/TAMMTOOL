#!/usr/bin/env bash
#
# get-apk.sh — تنزيل آخر APK مبنيّ في GitHub Actions وفحصه قبل أن تلمس هاتفك.
#
# لماذا يوجد؟ لأن بناء APK حقيقي يتطلب JDK + Android SDK + Maven Central؛ لا شيء من هذا في
# sandbox الوكيل (dl.google.com وrepo1.maven.org محجوبان، والنتيجة 000 من curl). لذلك المكان
# الوحيد الذي *ينتج* ملفاً هو الـ runner، وهذا السكربت هو جسر الاسترجاع: يختار التشغيل، ينزّل
# الـ artifact، ثم يتحقق محلياً أن الملف APK فعلاً لا صفرٌ ولا placeholder — لأن هذه المرحلة
# هي التي كذبت مرتين في هذا المستودع («خطوة خضراء» بلا منتج، و«wrapper موجود» وهو خارج git).
#
# الاستخدام:
#   tools/get-apk.sh                              # آخر تشغيل ناجح لتطبيق marketer
#   tools/get-apk.sh --app orders-delivery        # تطبيق آخر في نفس التشغيل
#   tools/get-apk.sh --run 42288470775 --app marketer
#   tools/get-apk.sh --list                       # ما المتاح (لا تنزيل)
#   tools/get-apk.sh --from apk/marketer-debug-apk.zip   # فكّ ضغط + فحص ملف محلي (يعمل بلا شبكة)
#
# رموز الخروج: 0 ✓ · 1 فشل تحقق من APK · 2 وسيط رديء · 3 gh/شبكة غير متاحة
set -uo pipefail
VERSION="1.0.0"
C_RED=$'\033[0;31m'; C_GRN=$'\033[0;32m'; C_BLU=$'\033[0;34m'; C_YLW=$'\033[1;33m'; C_NC=$'\033[0m'
log()  { printf '%s[•]%s %s\n' "$C_BLU" "$C_NC" "$*"; }
ok()   { printf '%s[✓]%s %s\n' "$C_GRN" "$C_NC" "$*"; }
warn() { printf '%s[!]%s %s\n' "$C_YLW" "$C_NC" "$*"; }
err()  { printf '%s[✗]%s %s\n' "$C_RED" "$C_NC" "$*" >&2; }

APP="marketer"; RUN=""; OUTDIR="apk"; LIST=0; FROM=""; BRANCH="arena/68a3e358-tammtool"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --app)    [[ $# -ge 2 ]] || { err "--app يحتاج اسماً"; exit 2; }; APP="$2"; shift 2 ;;
    --run)    [[ $# -ge 2 ]] || { err "--run يحتاج رقم تشغيل"; exit 2; }; RUN="$2"; shift 2 ;;
    --branch) [[ $# -ge 2 ]] || { err "--branch يحتاج فرعاً"; exit 2; }; BRANCH="$2"; shift 2 ;;
    --out)    [[ $# -ge 2 ]] || { err "--out يحتاج مساراً"; exit 2; }; OUTDIR="$2"; shift 2 ;;
    --from)   [[ $# -ge 2 ]] || { err "--from يحتاج مسار zip/apk"; exit 2; }; FROM="$2"; shift 2 ;;
    --list)   LIST=1; shift ;;
    --version) echo "get-apk.sh v$VERSION"; exit 0 ;;
    -h|--help) sed -n '3,22p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) err "وسيط غير معروف: $1 (جرّب --help)"; exit 2 ;;
  esac
done

REPO="$(git remote get-url origin 2>/dev/null | sed -E 's#.*[:/]([^/]+/[^/.]+)(\.git)?$#\1#')"
[[ -n "$REPO" ]] || { err "لا يمكن تحديد owner/repo من remote origin"; exit 2; }
NAME="$APP-debug-apk"

# ── فحص APK محلياً: لا نكتفي بحجم الملف؛ نريد zip صالحاً + AXML + dex + توقيع ──
verify_apk() {  # verify_apk <path-to-apk>
  python3 - "$1" <<'PY'
import sys, zipfile, struct, hashlib, pathlib
p = pathlib.Path(sys.argv[1])
if not p.exists(): print('مفقود'); sys.exit(1)
size = p.stat().st_size
try:
    z = zipfile.ZipFile(p)
except Exception as e:
    print('ليس ZIP: %s' % e); sys.exit(1)
names = z.namelist()
need = {'AndroidManifest.xml': 'مانيفست ثنائي', 'resources.arsc': 'جدول الموارد'}
have_dex = [n for n in names if n.endswith('.dex')]
bad = [f'{k} ({v}) مفقود' for k, v in need.items() if k not in names]
if not have_dex: bad.append('لا classes.dex ⇒ بلا كود')
if not any(n.startswith('META-INF/') for n in names): bad.append('META-INF مفقود ⇒ غير موقَّع')
magic = 0
if 'AndroidManifest.xml' in names:
    magic = struct.unpack('<I', z.read('AndroidManifest.xml')[:4])[0]
if magic != 0x00080003: bad.append('سحر AndroidManifest ليس AXML (0x%08x)' % magic)
print('الحجم: %s بايت · dex: %d · موارد res: %d · المجموع: %d ملف · sha256: %s…' % (
      size, len(have_dex), len([n for n in names if n.startswith('res/')]), len(names),
      hashlib.sha256(p.read_bytes()).hexdigest()[:16]))
if bad:
    print(' · '.join(bad)); sys.exit(1)
sys.exit(0)
PY
}

if [[ $LIST -eq 1 ]]; then
  log "البحث عن تشغيلات فرع $BRANCH في $REPO"
  gh run list --repo "$REPO" --branch "$BRANCH" --limit 8 \
    --json databaseId,headSha,status,conclusion,createdAt \
    --jq '.[]|"▶ \(.databaseId) · \(.headSha[0:7]) · \(.status)/\(.conclusion // "-") · \(.createdAt[5:16])"' || { err "gh غير متاح"; exit 3; }
  echo
  for r in $(gh run list --repo "$REPO" --branch "$BRANCH" --limit 8 --json databaseId --jq '.[].databaseId'); do
    n=$(gh api "repos/$REPO/actions/runs/$r/artifacts" --jq "[.artifacts[]|select(.name|endswith(\"-debug-apk\"))]|length" 2>/dev/null || echo 0)
    [[ "$n" != "0" && -n "$n" ]] && echo "   $r → $n APK artifact(s):" && \
      gh api "repos/$REPO/actions/runs/$r/artifacts" \
        --jq '.artifacts[]|select(.name|endswith("-debug-apk"))|"     • \(.name) · \(.size_in_bytes) بايت · expired=\(.expired)"' 2>/dev/null
  done
  exit 0
fi

mkdir -p "$OUTDIR"
if [[ -n "$FROM" ]]; then
  log "من ملف محلي: $FROM"
  src="$FROM"
  if [[ "$FROM" == *.zip ]]; then
    # ضِمنيا الأشكال كلها: (أ) zip يحوي app.apk — كما يرفعه بعض الأدوات، (ب) الـ zip نفسه هو الـ APK
    # (artifact من actions/upload-artifact لملف APK واحد يبقى أرشيفاً بصيغة zip لكن بمحتوى APK).
    tmp="$OUTDIR/$(basename "${FROM%.zip}")"; rm -rf "$tmp"; mkdir -p "$tmp"
    unzip -q -o "$FROM" -d "$tmp" || { err "فشل فك الضغط"; exit 1; }
    inner="$(find "$tmp" -name '*.apk' -type f | head -1)"
    if [[ -n "$inner" ]]; then
      mkdir -p "$OUTDIR"; cp -f "$inner" "$OUTDIR/$(basename "$inner")"; src="$OUTDIR/$(basename "$inner")"
      log "استُخرج من الأرشيف: $(basename "$src")"
    elif unzip -l "$FROM" 2>/dev/null | grep -q 'AndroidManifest.xml'; then
      mkdir -p "$OUTDIR"; cp -f "$FROM" "$OUTDIR/$NAME.apk"; src="$OUTDIR/$NAME.apk"
      log "الأرشيف هو الـ APK نفسه (فيه AndroidManifest.xml) ⇒ فُحص كما هو"
    else
      err "لا APK ولا AndroidManifest داخل $FROM — لا أتمرّن على ملف لا أفهمه"; exit 1
    fi
  fi
else
  command -v gh >/dev/null 2>&1 || { err "gh غير مثبت — لا يمكن التنزيل من Actions"; exit 3; }
  if [[ -z "$RUN" ]]; then
    log "أبحث عن آخر تشغيل فيه $NAME على $BRANCH…"
    RUN=$(gh run list --repo "$REPO" --branch "$BRANCH" --limit 12 --json databaseId,conclusion \
            --jq '.[]|select(.conclusion=="success" or .conclusion=="failure")|.databaseId' | while read -r r; do
              c=$(gh api "repos/$REPO/actions/runs/$r/artifacts" --jq "[.artifacts[]|select(.name==\"$NAME\")]|length" 2>/dev/null || echo 0)
              [[ "$c" != "0" ]] && { echo "$r"; break; }
            done)
    [[ -n "$RUN" ]] || { err "لم أجد تشغيلًا فيه $NAME على $BRANCH — جرّب --list أو --run <id>"; exit 1; }
  fi
  log "التشغيل $RUN · الـ artifact: $NAME"
  rm -rf "$OUTDIR/$NAME.zip" "$OUTDIR/${NAME%-apk}apk" 2>/dev/null
  gh run download "$RUN" --repo "$REPO" --name "$NAME" --dir "$OUTDIR/$NAME.tmp" || { err "فشل التنزيل (شبكة/صلاحية؟)"; exit 3; }
  mkdir -p "$OUTDIR"
  f=$(find "$OUTDIR/$NAME.tmp" -type f -name '*.apk' | head -1)
  [[ -n "$f" ]] || f=$(find "$OUTDIR/$NAME.tmp" -type f | head -1)
  [[ -n "$f" ]] || { err "الـ artifact فارغ — هذا فشل حقيقي وليس غياب تنزيل"; exit 1; }
  mv -f "$f" "$OUTDIR/$NAME.apk"; rm -rf "$OUTDIR/$NAME.tmp"
  src="$OUTDIR/$NAME.apk"
fi

log "نتحقق من الـ APK:"
if out="$(verify_apk "$src")"; then
  ok "$src"
  echo "   $out"
  printf '\n%sللتركيب على هاتف:%s   adb install -r "%s"\n' "$C_BLU" "$C_NC" "$src"
  printf '%sطريق بلا كابل:%s أرسل الملف للهاتف ثم افتحه، وفعّل «التثبيت من مصدر غير معروفة»\n' "$C_BLU" "$C_NC"
  printf '%sانتبه:%s هذا debug APK (مفتاح تصحيح). لا يُرفَع به إلى Google Play؛ للإصدار العام:\n' "$C_YLW" "$C_NC"
  printf '         ./scripts/sign-apk.sh --apk "%s" && راجع PLAY_STORE_RELEASE.md\n' "$src"
  [[ -n "$RUN" ]] && printf '%sمصدر الملف:%s https://github.com/%s/actions/runs/%s (تبويب Artifacts)\n' "$C_BLU" "$C_NC" "$REPO" "$RUN"
  exit 0
else
  rc=$?
  err "الملف ليس APK صالحاً — لا تثبّته على أي جهاز:"
  echo "   ${out:-}"
  exit 1
fi
