#!/usr/bin/env bash
#
# toolchain-smoke.sh — اختبارات سكربتات tools/ (بلا Android، بلا شبكة، بلا هاتف)
# تُشغَّل وحدها أو من scripts/tests/mock-smoke.sh (وبالتالي في CI كخطوة Self-test).
#
set -euo pipefail
SCRIPT_PATH="${BASH_SOURCE[0]}"
while [[ -L "$SCRIPT_PATH" ]]; do SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"; done
TOOLS_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"
ROOT="$(cd "$TOOLS_DIR/.." && pwd)"

PASS=0; FAIL=0
ok()   { printf '  \033[0;32m✓\033[0m %s\n' "$*"; PASS=$((PASS + 1)); }
no()   { printf '  \033[0;31m✗\033[0m %s\n' "$*"; FAIL=$((FAIL + 1)); }
t()    { local desc="$1"; shift; if "$@" >/dev/null 2>&1; then ok "$desc"; else no "$desc"; fi; }
tfail(){ local desc="$1"; shift; if "$@" >/dev/null 2>&1; then no "$desc (كان متوقعاً الفشل)"; else ok "$desc"; fi; }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/tamm-tools-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

echo "== أدوات الفلتر: صيغة السكربتات =="
for f in "$TOOLS_DIR"/*.sh "$TOOLS_DIR"/tests/*.sh; do
  t "bash -n $(basename "$f")" bash -n "$f"
done

echo "== tools.lock: قابل للتحليل ومتكامل الحقول =="
python3 - "$TOOLS_DIR/tools.lock" <<'PY' && ok "الحقل الإلزامي مكتمل" || no "tools.lock غير سليم"
import configparser, sys, re
c = configparser.RawConfigParser(strict=False); c.read(sys.argv[1], encoding='utf-8')
errs = []
if len(c.sections()) < 25: errs.append('عدد البنود %d أقل من 25' % len(c.sections()))
for s in c.sections():
    d = dict(c[s])
    for k in ('kind', 'purpose', 'verified'):
        if not d.get(k): errs.append('%s بلا %s' % (s, k))
    if d.get('kind') == 'gradle-dep':
        coord = d.get('coordinate', '')
        if not re.fullmatch(r'[\w.\-]+:[\w.\-]+:[\w.\-]+', coord): errs.append('%s: coordinate ليست g:a:v' % s)
    if d.get('kind') == 'tool' and not d.get('repo'): errs.append('%s (tool) بلا repo' % s)
    v = d.get('verified', '')
    if v not in ('github-api@2026-11-06', 'repo-fact', 'needs-online'): errs.append('%s: verified غير موضح (%s)' % (s, v))
    lic = d.get('license', '')
    if not lic: errs.append('%s بلا license' % s)
if errs:
    print('\n'.join('  ✗ ' + e for e in errs)); sys.exit(1)
print('  ✓ %d بنداً، كلها مكتملة الحقول والإحداثيات بصيغة g:a:v' % len(c.sections()))
PY

echo "== install-toolchain.sh =="
S="$TOOLS_DIR/install-toolchain.sh"
t "--list يعمل"            bash "$S" --list
t "--check يعمل"           bash "$S" --check
t "--emit-deps camera"     bash -c "bash '$S' --emit-deps camera | grep -q 'androidx.camera:camera-core'"
t "--emit-deps tests"      bash -c "bash '$S' --emit-deps tests | grep -q 'junit:junit'"
t "--emit-deps لا يُخرج Implementation خارج الكتلة" bash -c "! bash '$S' --emit-deps all | grep -q 'plugins {'"
t "--emit-ci يخرج emulator-runner" bash -c "bash '$S' --emit-ci | grep -q 'android-emulator-runner'"
t "--emit-env"             bash -c "bash '$S' --emit-env | grep -q TAMM_TOOLCHAIN_DIR"
t "--os/--arch يُقبلان"    bash "$S" --install ktlint --os macos --arch aarch64 --dry-run
t "وسيط مجهول يفشل"        bash -c "! bash '$S' --nope 2>/dev/null"

echo "== install-gradle-wrapper.sh =="
W="$TOOLS_DIR/install-gradle-wrapper.sh"
t "--verify على المخزون"   bash "$W" --verify
t "--dry-run --all"        bash "$W" --dry-run --all
t "يطبّع discover إلى 4 مشاريع فأكثر" bash -c "[ \$(bash '$W' --dry-run --all | grep -c 'dry-run\] install wrapper') -ge 4 ]"
mkdir -p "$TMP/proj" && printf 'rootProject.name = "x"\n' > "$TMP/proj/settings.gradle.kts"
t "يزرع في مشروع فارغ"     bash "$W" --into "$TMP/proj"
for f in gradlew gradle/wrapper/gradle-wrapper.jar gradle/wrapper/gradle-wrapper.properties; do
  [[ -f "$TMP/proj/$f" ]] && ok "منشأ: $f" || no "ناقص: $f"
done
t "gradlew قابل للتنفيذ"   test -x "$TMP/proj/gradlew"
t "properties يشير إلى 8.7-bin" grep -q 'gradle-8.7-bin.zip' "$TMP/proj/gradle/wrapper/gradle-wrapper.properties"
t "التخطّي عند وجوده (بلا --force)" bash "$W" --into "$TMP/proj"
t "--force يستبدل"         bash "$W" --into "$TMP/proj" --force
t "jar هو ZIP صحيح"        python3 -c "import zipfile,sys;sys.exit(0 if zipfile.is_zipfile('$TMP/proj/gradle/wrapper/gradle-wrapper.jar') else 1)"
tfail "مسار غير موجود يفشل" bash "$W" --into "$TMP/nope-missing"

echo "== verify-filter-app.sh على القالب =="
V="$TOOLS_DIR/verify-filter-app.sh"
t "القالب يمرّ الفحوص"     bash "$V" --dir "$TOOLS_DIR/filter-app-template" --gate
t "--list-checks"          bash "$V" --list-checks
t "apps/filter يمرّ إن وُجد" bash -c "[ ! -d '$ROOT/apps/filter' ] || bash '$V' --dir '$ROOT/apps/filter' --gate"

echo "== verify-filter-app.sh يلتقط الأعطال (فحوص سلبية) =="
B="$TMP/broken"
cp -R "$TOOLS_DIR/filter-app-template" "$B"
rm -f "$B/app/src/main/assets/shaders/sepia.agsl"
tfail "شيدر مفقود ⇒ فشل (04)" bash "$V" --dir "$B" --gate
python3 - "$B" <<'PY'
import pathlib, re, sys
p = pathlib.Path(sys.argv[1]) / 'app/src/main/res/values/strings.xml'
t = p.read_text(encoding='utf-8')
t = re.sub(r'<string name="filter_blur">.*?</string>\n', '', t, flags=re.S)
p.write_text(t, encoding='utf-8')
PY
tfail "نص محذوف من strings.xml ⇒ فشل (07)" bash "$V" --dir "$B" --gate
python3 - "$B" <<'PY'
import pathlib, sys
p = pathlib.Path(sys.argv[1]) / 'gradle.properties'
t = '\n'.join(l for l in p.read_text(encoding='utf-8').splitlines() if 'jvmargs' not in l) + '\n'
p.write_text(t, encoding='utf-8')
PY
tfail "بلا jvmargs ⇒ فشل (09)" bash "$V" --dir "$B" --gate
python3 - "$B" <<'PY'
import pathlib, sys
p = pathlib.Path(sys.argv[1]) / 'app/src/main/AndroidManifest.xml'
t = p.read_text(encoding='utf-8')
p.write_text(t.replace('<application', '<application UNCLOSED=', 1), encoding='utf-8')
PY
tfail "XML مكسور ⇒ فشل (03)" bash "$V" --dir "$B" --gate
python3 - "$B" <<'PY'
import pathlib, sys
p = pathlib.Path(sys.argv[1]) / 'app/src/main/java/com/tammtool/filterapp/render/RenderEffectFactory.kt'
t = p.read_text(encoding='utf-8')
t = t.replace('if (Build.VERSION.SDK_INT >= FilterCapability.RUNTIME_SHADER_API &&\n            FilterCapability.current() == RenderPath.AGSL\n        ) {', 'if (true) {')
p.write_text(t, encoding='utf-8')
PY
tfail "RuntimeShader بلا شرط SDK ⇒ فشل (06)" bash "$V" --dir "$B" --gate

echo "== scaffold-filter-app.sh =="
SC="$TOOLS_DIR/scaffold-filter-app.sh"
t "--print-manifest"       bash -c "bash '$SC' --print-manifest | grep -q 'settings.gradle.kts'"
t "--dry-run"              bash "$SC" --dry-run --into "$TMP/s1"
t "توليد فعلي"             bash -c "bash '$SC' --into '$TMP/s1' >/dev/null && [ -f '$TMP/s1/app/build.gradle.kts' ]"
t "مجلد موجود بلا --replace يفشل" bash -c "! bash '$SC' --into '$TMP/s1' >/dev/null 2>&1"
t "حزمة مخصصة تُطبَّق في المسارات والنصوص" bash -c "bash '$SC' --into '$TMP/s2' --package com.example.camfilter >/dev/null && grep -rq 'package com.example.camfilter' '$TMP/s2/app/src/main/java/com/example/camfilter/domain/Filter.kt'"
t "package رديء يُرفض"     bash -c "! bash '$SC' --into '$TMP/s3' --package 'Bad Pack!' >/dev/null 2>&1"
t "المولَّد بـ --package يمرّ الفحص" bash "$V" --dir "$TMP/s2" --gate

echo
printf 'النتيجة: \033[0;32m%d نجاح\033[0m' "$PASS"
if [[ $FAIL -gt 0 ]]; then printf ' · \033[0;31m%d فشل\033[0m\n' "$FAIL"; exit 1; fi
printf ' · 0 فشل\n'
