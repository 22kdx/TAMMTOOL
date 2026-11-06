#!/usr/bin/env bash
#
# install-toolchain.sh — مديِر أدوات البناء والاختبار المذكورة في tools/tools.lock
# جزء من TAMMTOOL · أدوات الوكيل 3 · إصدار 1.0.0
#
# يقرأ tools/tools.lock (ملف القفل الوحيد) ويقوم نيابة عن الوكيل بما لا يُفعل يدوياً كل مرة:
#   --list        جدول كل البنود (النوع/النسخة/الترخيص/الغرض/حالة التحقق)
#   --check       ما المتوفر على هذا الجهاز وما الناقص (بلا تنزيل)
#   --install N   يحلّل أصل الإصدار من GitHub Releases ويزرعه في $TAMM_TOOLCHAIN_DIR
#                 (--install all كل الأدوات، أو قائمة مفصولة بفواصل)
#   --emit-deps   يطبع كتلة dependencies { … } جاهزة للّصق في build.gradle.kts
#   --emit-ci     يطبع خطوات GitHub Actions المقفلة في الملف
#   --emit-env    سطور PATH/JAVA_HOME صالحة لـ eval
#   --verify      يعيد فحص الأحجام/البصم للمنزَّل (إن كان manifest موجوداً)
#
# الاستخدام:
#   ./tools/install-toolchain.sh --check
#   ./tools/install-toolchain.sh --install ktlint,shellcheck --dry-run
#   ./tools/install-toolchain.sh --emit-deps camera,compose,tests
#   ./tools/install-toolchain.sh --install all
#
# متغيرات البيئة:
#   TAMM_TOOLCHAIN_DIR   مجلد التثبيت (افتراضي: $HOME/.cache/tamm-toolchain)
#   TAMM_TOOLCHAIN_LOCK  مسار ملف القفل (افتراضي: tools/tools.lock)
#   TAMM_OS / TAMM_ARCH  تجاوز كشف المنصة (linux|macos / x86_64|aarch64)
#   NO_COLOR             بلا ألوان
#
# رموز الخروج: 0 نجاح · 1 خطأ استخدام/فحص · 2 شبكة/gh غير متاحة (الأمر اليدوي يُطبع)
#
set -euo pipefail

VERSION="1.0.0"
SCRIPT_PATH="${BASH_SOURCE[0]}"
while [[ -L "$SCRIPT_PATH" ]]; do SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"; done
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

LOCK_FILE="${TAMM_TOOLCHAIN_LOCK:-$PROJECT_ROOT/tools/tools.lock}"
CACHE_DIR="${TAMM_TOOLCHAIN_DIR:-$HOME/.cache/tamm-toolchain}"

ACTION="check"
SELECT=""
DRY=0
FORCE=0
DEPS_GROUPS=""

case "$(uname -s)" in
  Linux)  OS="linux";  ARCH2="x86_64" ;;
  Darwin) OS="macos";  ARCH2="aarch64" ;;
  *)      OS="linux";  ARCH2="x86_64" ;;
esac
ARCH="${TAMM_ARCH:-$ARCH2}"
OS="${TAMM_OS:-$OS}"
# scrcpy/shellcheck يستخدمان aarch64/x86_64 لنفس اسم المنصة، و macOS يسمّيها darwin في shellcheck
SHELL_OS="$OS"; [[ "$OS" == "macos" ]] && SHELL_OS="darwin"

GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'; RED=$'\033[0;31m'; DIM=$'\033[2m'; NC=$'\033[0m'
[[ -t 1 || -z "${NO_COLOR:-}" ]] || { GREEN=""; YELLOW=""; RED=""; DIM=""; NC=""; }
log_info() { printf '%s[i]%s %s\n' "$YELLOW" "$NC" "$*"; }
log_ok()   { printf '%s[✓]%s %s\n' "$GREEN" "$NC" "$*"; }
log_err()  { printf '%s[✗]%s %s\n' "$RED" "$NC" "$*" >&2; }

usage() { sed -n '3,32p' "$SCRIPT_PATH" | sed 's/^# \{0,1\}//'; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --list)      ACTION="list"; shift ;;
    --check)     ACTION="check"; shift ;;
    --install)   ACTION="install"; [[ $# -ge 2 ]] || { log_err "--install يحتاج اسماً أو all"; exit 1; }; SELECT="$2"; shift 2 ;;
    --emit-deps) ACTION="emit-deps"; [[ $# -ge 2 ]] || { log_err "--emit-deps يحتاج مجموعات (camera,compose,tests,all)"; exit 1; }; DEPS_GROUPS="$2"; shift 2 ;;
    --emit-ci)   ACTION="emit-ci"; shift ;;
    --emit-env)  ACTION="emit-env"; shift ;;
    --verify)    ACTION="verify"; shift ;;
    --dir)       [[ $# -ge 2 ]] || { log_err "--dir يحتاج مساراً"; exit 1; }; CACHE_DIR="$2"; shift 2 ;;
    --os)        [[ $# -ge 2 ]] || { log_err "--os يحتاج linux أو macos"; exit 1; }; OS="$2"; [[ "$OS" == "macos" ]] && SHELL_OS="darwin" || SHELL_OS="$OS"; shift 2 ;;
    --arch)      [[ $# -ge 2 ]] || { log_err "--arch يحتاج x86_64 أو aarch64"; exit 1; }; ARCH="$2"; shift 2 ;;
    --dry-run)   DRY=1; shift ;;
    --force)     FORCE=1; shift ;;
    -h|--help)   usage; exit 0 ;;
    --vcs-version|--toolchain-version) echo "install-toolchain.sh v$VERSION"; exit 0 ;;
    *) log_err "وسيط غير معروف: $1  (جرّب --help)"; exit 1 ;;
  esac
done
[[ -f "$LOCK_FILE" ]] || { log_err "لا ملف قفل: $LOCK_FILE"; exit 1; }

# ── محلّل القفل: كل بند إلى TSV (اسم|kind|repo|tag|asset|bin|license|verified|purpose|usage|notes)
parse_lock() {
  python3 - "$LOCK_FILE" <<'PY'
import configparser, sys
c = configparser.RawConfigParser(strict=False)
c.read(sys.argv[1], encoding='utf-8')
for s in c.sections():
    d = dict(c[s])
    name = s.split(':', 1)[1]
    row = [name, d.get('kind', '?'), d.get('repo', ''), d.get('tag', ''), d.get('asset', ''),
           d.get('bin', ''), d.get('license', ''), d.get('verified', ''), d.get('purpose', ''),
           d.get('usage', ''), d.get('notes', ''), d.get('coordinate', ''), d.get('extract', ''),
           d.get('group', '')]
    print('\t'.join(f.replace('\t', ' ').replace('\n', ' ') for f in row))
PY
}

ROWS="$(parse_lock)"

get() { printf '%s\n' "$ROWS" | awk -F'\t' -v k="$1" -v c="$2" 'BEGIN{
  idx["kind"]=2; idx["repo"]=3; idx["tag"]=4; idx["asset"]=5; idx["bin"]=6;
  idx["license"]=7; idx["verified"]=8; idx["purpose"]=9; idx["usage"]=10; idx["notes"]=11;
  idx["coordinate"]=12; idx["extract"]=13
} $1==k {print $idx[c]; exit}'; }

expand_asset() {
  local a="$1" ver="$2"
  a="${a//\{ver\}/$ver}"; a="${a//\{os\}/$OS}"; a="${a//\{arch\}/$ARCH}"; a="${a//\{arch2\}/$ARCH}"
  # shellcheck يستخدم اسم منصة مختلفاً (darwin) وحده
  [[ "$3" == "shellcheck" ]] && a="${a//\{os\}/$SHELL_OS}"
  printf '%s' "$a"
}

# ── --list ──────────────────────────────────────────────────────────────────
if [[ "$ACTION" == "list" ]]; then
  printf '%s%-26s %-10s %-26s %-14s %-34s%s\n' "$DIM" "البند" "النوع" "الريبو/الإحداثي" "النسخة" "الترخيص" "$NC"
  printf '%s\n' "$ROWS" | awk -F'\t' -v D="$DIM" '{
    coord = ($12 != "" ? $12 : $3); ver = ($4 == "latest" ? "latest" : $4)
    printf "%-26s %-10s %-26s %-14s %-34s\n", $1, $2, substr(coord,1,26), substr(ver,1,14), substr($7,1,34)
  }'
  echo
  printf 'الأغراض: ./tools/install-toolchain.sh --check · --install all · --emit-deps all\n'
  exit 0
fi

# ── --check : ما المتوفر؟ ─────────────────────────────────────────────────────
if [[ "$ACTION" == "check" ]]; then
  have=0; miss=0
  while IFS=$'\t' read -r name kind repo tag asset bin lic ver purpose u n coord extract group; do
    [[ "$kind" == "tool" ]] || continue
    shown=""
    if [[ -n "$bin" && -x "$CACHE_DIR/$name/bin/$bin" ]]; then
      shown="$CACHE_DIR/$name/bin/$bin"
    elif command -v "$bin" >/dev/null 2>&1; then
      shown="$(command -v "$bin")"
    fi
    if [[ -n "$shown" ]]; then
      printf '%s ✓ %-12s %s\n' "$GREEN" "$name" "$shown"; have=$((have + 1))
    else
      printf '%s· %s %-12s غير مثبت — نزّله: ./tools/install-toolchain.sh --install %s%s\n' \
        "$YELLOW" "$NC" "$name" "$name" "$NC"; miss=$((miss + 1))
    fi
  done <<<"$ROWS"
  echo
  printf 'متوفر: %s · ناقص: %s · القفل: %s · مجلد الأدوات: %s\n' "$have" "$miss" "${LOCK_FILE#$PROJECT_ROOT/}" "$CACHE_DIR"
  exit 0
fi

# ── --emit-deps : كتلة Gradle جاهزة ──────────────────────────────────────────
if [[ "$ACTION" == "emit-deps" ]]; then
  case "$DEPS_GROUPS" in
    all) filter=".*" ;;
    *)   filter="^($(printf '%s' "$DEPS_GROUPS" | tr ',' '|'))" ;;
  esac
  echo "    // ── مولّد من tools/tools.lock — لا تحرّره يدوياً في موضعين"
  printf '%s\n' "$ROWS" | awk -F'\t' -v f="$filter" -v os_="$OS" '
    $2 == "gradle-dep" && ($1 ~ f || $14 ~ f) {
      cfg = "implementation"
      if ($1 ~ /robolectric|roborazzi|paparazzi/) cfg = "testImplementation"
      if ($1 == "junit" || $1 == "coroutines-test") cfg = "testImplementation"
      printf "    %s(\"%s\")%s\n", cfg, $12, ($8 == "needs-online" ? "   // ⚠ تحقق من النشر قبل الاعتماد" : "")
    }'
  printf '%s\n' "$ROWS" | awk -F'\t' -v f="$filter" '
    $2 == "gradle-dep" && ($1 ~ f || $14 ~ f) && ($1 ~ /leakcanary/) { printf "    debugImplementation(\"%s\")\n", $12 }'
  exit 0
fi

# ── --emit-ci : خطوات Actions ────────────────────────────────────────────────
if [[ "$ACTION" == "emit-ci" ]]; then
  printf '%s\n' "$ROWS" | awk -F'\t' '$2=="ci-action" {printf "      - uses: %s   # %s\n", $12, $9}'
  exit 0
fi

# ── --emit-env : مصادر PATH للأدوات المزروعة ─────────────────────────────────
if [[ "$ACTION" == "emit-env" ]]; then
  echo "export TAMM_TOOLCHAIN_DIR=\"$CACHE_DIR\""
  echo "export PATH=\"$CACHE_DIR\"/ktlint/bin:$CACHE_DIR/shellcheck/bin:$CACHE_DIR/jadx/bin:$CACHE_DIR/scrcpy/bin:\$PATH"
  [[ -d "$CACHE_DIR/jdk17" ]] && echo "export JAVA_HOME=\"$CACHE_DIR/jdk17\"\n"
  echo "# jars (apktool/detekt) تُشغَّل بـ: java -jar \"\$TAMM_TOOLCHAIN_DIR\"/<name>/*.jar"
  exit 0
fi

# ── --verify / --install ─────────────────────────────────────────────────────
manifest_check() {
  local d="$1"
  [[ -f "$d/install-manifest.json" ]] || { echo "لا manifest"; return 1; }
  python3 - "$d" <<'PY'
import hashlib, json, pathlib, sys
d = pathlib.Path(sys.argv[1]); man = json.loads((d / 'install-manifest.json').read_text(encoding='utf-8'))
bad = []
for rel, info in man.get('files', {}).items():
    p = d / rel
    if not p.exists():
        bad.append(rel + ': مفقود'); continue
    want = info.get('sha256', '')
    if want and hashlib.sha256(p.read_bytes()).hexdigest() != want:
        bad.append(rel + ': بصمة غير مطابقة')
if bad:
    print('\n'.join('  ✗ ' + b for b in bad)); sys.exit(1)
print('  ✓ الملفات المنزَّلة مطابقة للـ manifest المحفوظ')
PY
}

if [[ "$ACTION" == "verify" ]]; then
  rc=0
  for d in "$CACHE_DIR"/*/; do
    [[ -d "$d" ]] || continue
    printf '── %s\n' "$(basename "${d%/}")"
    manifest_check "${d%/}" || rc=1
  done
  [[ $rc -eq 0 ]] && log_ok "التحقق اكتمل" || log_err "بعض البنود لا تتحقق"
  exit $rc
fi

# install
case "$SELECT" in
  all) names="$(printf '%s\n' "$ROWS" | awk -F'\t' '$2=="tool"{print $1}')" ;;
  *)   names="$(printf '%s' "$SELECT" | tr ',' '\n')" ;;
esac

if ! command -v gh >/dev/null 2>&1; then
  log_err "gh غير مثبت — لا يمكن حلّ الأصول من GitHub Releases"
  echo "البديل اليدوي لكل أداة: نزّل الأصل من صفحة الإصدار ثم:"
  printf '  TAMM_TOOLCHAIN_DIR=%s ./tools/install-toolchain.sh --check\n' "$CACHE_DIR"
  exit 2
fi

overall=0
while IFS= read -r name; do
  [[ -n "$name" ]] || continue
  kind="$(get "$name" kind)"
  [[ "$kind" == "tool" ]] || { log_err "$name ليس أداة (kind=$kind) — انظر --list"; overall=1; continue; }
  repo="$(get "$name" repo)"; tag="$(get "$name" tag)"; asset_pat="$(get "$name" asset)"
  bin="$(get "$name" bin)"; extract="$(get "$name" extract)"
  ver_num="${tag#v}"; [[ "$ver_num" == "latest" ]] && ver_num="latest"
  asset="$(expand_asset "$asset_pat" "$ver_num" "$name")"
  dest="$CACHE_DIR/$name"

  if [[ -d "$dest" && $FORCE -eq 0 && $DRY -eq 0 ]]; then
    log_ok "$name موجود في $dest (--force لإعادة التنزيل)"; continue
  fi
  if [[ "$name" == "gradle-wrapper" ]]; then
    echo "  gradle-wrapper لا يُنزَّل: ./tools/install-gradle-wrapper.sh --apps   (مخزّن في tools/vendor/)"
    continue
  fi
  if [[ "$name" == "android-sdk" ]]; then
    echo "  android-sdk يُثبَّت بسكريبت المستودع: ./scripts/android-sdk-setup.sh --sdk-dir DIR --accept-licenses"
    continue
  fi

  log_info "$name ← $repo @ ${tag} · الأصل المتوقع: $asset"
  ep="repos/$repo/releases/tags/$tag"
  [[ "$tag" == "latest" ]] && ep="repos/$repo/releases/latest"
  if ! json="$(gh api "$ep" 2>/dev/null)"; then
    log_err "تعذّر قراءة $ep (تحقق من الشبكة/الصلاحيات)"; overall=1; continue
  fi
  url="$(printf '%s' "$json" | python3 -c '
import json, re, sys, fnmatch
d = json.load(sys.stdin); pat = sys.argv[1]
names = [a["name"] for a in d.get("assets", [])]
pick = [n for n in names if fnmatch.fnmatch(n, pat)] or [n for n in names if pat and pat in n]
for n in pick:
    if n.endswith((".asc", ".sha256", ".sig")): continue
    a = [x for x in d["assets"] if x["name"] == n][0]
    print(a["browser_download_url"]); break
' "$asset" 2>/dev/null || true)"
  if [[ -z "$url" ]]; then
    log_err "لا أصل مطابق للنمط '$asset' على منصة '$OS/$ARCH' — الأصول: $(printf '%s' "$json" | python3 -c 'import json,sys;print(", ".join(a["name"] for a in json.load(sys.stdin).get("assets",[])[:6]))' 2>/dev/null)"
    overall=1; continue
  fi
  if [[ $DRY -eq 1 ]]; then
    echo "  [dry-run] curl -L --fail -o \"$CACHE_DIR/$name/$(basename "$url")\" \"$url\""
    echo "  [dry-run] ثم فكّ ($extract) ووضع الملف القابل للتنفيذ في $dest/bin/"
    continue
  fi
  mkdir -p "$dest"
  tmp="$dest/$(basename "$url")"
  log_info "تنزيل $(basename "$url")"
  if ! curl -L --fail --retry 3 --retry-delay 3 -o "$tmp" "$url"; then
    log_err "فشل التنزيل (شبكة محجوبة؟). الأمر اليدوي:
    curl -L --fail -o \"$tmp\" \"$url\"
    ثم أعد: ./tools/install-toolchain.sh --install $name"; overall=1; continue
  fi
  case "$extract" in
    tar) tar -xf "$tmp" -C "$dest" ;;
    zip) unzip -q -o "$tmp" -d "$dest" ;;
    jar|copy) mkdir -p "$dest/bin"; mv "$tmp" "$dest/bin/$(basename "$url")" ;;
    *) log_err "نمط فكّ غير معروف: $extract"; overall=1; continue ;;
  esac
  [[ "$extract" == "jar" || "$extract" == "copy" ]] || rm -f "$tmp"
  # نبحث عن الملف القابل للتنفيذ/الـ jar ونربطه في bin/
  found="$(find "$dest" -type f \( -name "${bin%%/}" -o -name '*.jar' \) 2>/dev/null | sort | head -1)"
  if [[ -n "$found" && "$found" != "$dest/bin/"* ]]; then
    mkdir -p "$dest/bin"; ln -sf "$found" "$dest/bin/$(basename "${bin:-tool}")" 2>/dev/null || true
  fi
  chmod +x "$dest"/bin/* 2>/dev/null || true
  python3 - "$dest" "$url" "$name" "$repo" "$tag" <<'PY'
import hashlib, json, pathlib, sys
dest = pathlib.Path(sys.argv[1]); url, name, repo, tag = sys.argv[2:6]
files = {}
for p in sorted(dest.rglob('*')):
    if p.is_file() and p.name != 'install-manifest.json' and p.stat().st_size < 400 * 1024 * 1024:
        files[str(p.relative_to(dest))] = {'bytes': p.stat().st_size, 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}
(dest / 'install-manifest.json').write_text(json.dumps(
    {'tool': str(name), 'repo': str(repo), 'tag': str(tag), 'url': str(url), 'files': files},
    ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print('  ✓ manifest محفوظ (%d ملف)' % len(files))
PY
  log_ok "$name جاهز في $dest"
done <<<"$names"

if [[ $overall -ne 0 ]]; then
  log_err "اكتمل مع أخطاء — راجع السطور الحمراء أعلاه"
  exit 1
fi
log_ok "كل المطلوب مُهيّأ · للحاقه بـ PATH:  eval \"\$($SCRIPT_PATH --emit-env)\""
