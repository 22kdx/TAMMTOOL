#!/usr/bin/env bash
#
# ci-logs.sh — قراءة نتائج GitHub Actions بدون السجلات الخام
#
# `gh run view --log-failed` يفشل في الشبكات المقيدة (يعتمد على
# results-receiver.actions.githubusercontent.com). هذا السكربت يستخدم
# api.github.com فقط، ويُخرج تقريراً جاهزاً للتشخيص:
#
#   1) بيانات الـ run: الحالة/الاستنتاج/الفرع/الكوميت/الرابط.
#   2) خطوات كل job وأيها فشل.
#   3) التعليقات (annotations) — منها تُقرأ رسائل الخطأ الحقيقية.
#   4) الـ artifacts بأحجامها، مع كشف الملفات الوهمية (placeholder صغير).
#   5) حكم «أخضر مزيف»: job ناجح بلا APK حقيقي، مع أسبابه في هذا المستودع.
#
# الاستخدام:
#   ./scripts/ci-logs.sh                          # آخر run على الفرع الحالي
#   ./scripts/ci-logs.sh latest --branch arena/xx # آخر run على فرع معين
#   ./scripts/ci-logs.sh 42267633951              # run محدد
#   ./scripts/ci-logs.sh --runs 12                # جدول آخر التشغيلات
#   ./scripts/ci-logs.sh latest --json            # نسخة JSON للأدوات
#   ./scripts/ci-logs.sh latest --gate            # رمز خروج 1 إن لم يكن البناء حقيقياً
#
# الخيارات:
#   --branch NAME   تصفية البحث عن آخر run بفرع معيّن
#   --repo owner/n  تجاوز اكتشاف المستودع من git remote
#   --runs [N]      عرض جدول آخر N تشغيلة (افتراضي 8) ثم الخروج
#   --json          طباعة ملخص JSON بعد التقرير
#   --gate          الخروج برمز 1 إذا لم يكن هناك APK حقيقي/ناجح (للبوابات)
#   --limit N       أقصى عدد تعليقات تُطبع (افتراضي 40)
#
# متغيرات بيئة: CI_REPO=owner/name · CI_LIMIT=N · NO_COLOR=1
#
# المخرجات الجانبية: <run-id>-annotations.tsv في المجلد الحالي (يُحذف مع --keep=no)
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

RUN_ARG="latest"
BRANCH=""
MODE="report"
RUNS_LIMIT=8
JSON_OUT=0
GATE=0
LIMIT="${CI_LIMIT:-40}"
MIN_APK_BYTES=1000000   # أقل حجم معقول لـ APK حقيقي

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  C_RED=$'\033[0;31m'
  C_GREEN=$'\033[0;32m'
  C_YELLOW=$'\033[1;33m'
  C_BLUE=$'\033[0;34m'
  C_BOLD=$'\033[1m'
  C_NC=$'\033[0m'
else
  C_RED=''
  C_GREEN=''
  C_YELLOW=''
  C_BLUE=''
  C_BOLD=''
  C_NC=''
fi

info() { printf '%s\n' "${C_BLUE}[i]${C_NC} $*"; }
ok() { printf '%s\n' "${C_GREEN}[✓]${C_NC} $*"; }
warn() { printf '%s\n' "${C_YELLOW}[!]${C_NC} $*"; }
err() { printf '%s\n' "${C_RED}[✗]${C_NC} $*"; }
hd() { printf '\n%s\n' "${C_BOLD}== $* ==${C_NC}"; }
die() {
  err "$*"
  exit 1
}

usage() {
  sed -n '3,36p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

# ---------- تحليل الوسائط ----------
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h | --help)
      usage
      exit 0
      ;;
    --branch)
      [[ $# -ge 2 ]] || die "--branch يحتاج اسماً"
      BRANCH="$2"
      shift
      ;;
    --branch=*) BRANCH="${1#*=}" ;;
    --repo)
      [[ $# -ge 2 ]] || die "--repo يحتاج owner/name"
      CI_REPO="$2"
      shift
      ;;
    --repo=*) CI_REPO="${1#*=}" ;;
    --runs)
      MODE="runs"
      if [[ $# -ge 2 && "${2:-}" =~ ^[0-9]+$ ]]; then
        RUNS_LIMIT="$2"
        shift
      fi
      ;;
    --json) JSON_OUT=1 ;;
    --gate) GATE=1 ;;
    --limit)
      [[ $# -ge 2 ]] || die "--limit يحتاج رقماً"
      LIMIT="$2"
      shift
      ;;
    --limit=*) LIMIT="${1#*=}" ;;
    latest) RUN_ARG="latest" ;;
    -*) die "خيار غير معروف: ${1}  (شغّل --help)" ;;
    *)
      [[ "$1" =~ ^[0-9]+$ ]] || die "رقم run غير معروف: $1"
      RUN_ARG="$1"
      ;;
  esac
  shift
done

command -v gh >/dev/null 2>&1 || die "يحتاج gh CLI: https://cli.github.com ثم gh auth login"
gh auth status >/dev/null 2>&1 || warn "لم يُكتشف تسجيل دخول في gh — قد تفشل الطلبات على مستودع خاص"

# ---------- المستودع ----------
if [[ -z "${CI_REPO:-}" ]]; then
  if [[ -n "${GITHUB_REPOSITORY:-}" ]]; then
    CI_REPO="$GITHUB_REPOSITORY"
  else
    CI_REPO="$(git -C "$PROJECT_ROOT" remote get-url origin 2>/dev/null |
      sed -n 's|.*github\.com[:/]\([^/]*/[^/]*\)\(\.git\)\{0,1\}$|\1|p')" || true
  fi
fi
[[ -n "${CI_REPO:-}" ]] || die "تعذّر اكتشاف المستودع — استخدم --repo owner/name"

human() {
  awk -v b="${1:-0}" 'BEGIN{s="B KB MB GB";split(s,u," ");i=1;while(b>=1024&&i<4){b/=1024;i++}printf "%.1f%s",b,u[i]}'
}

# ---------- جدول التشغيلات ----------
if [[ "$MODE" == "runs" ]]; then
  q="repos/$CI_REPO/actions/runs?per_page=$RUNS_LIMIT"
  [[ -n "$BRANCH" ]] && q="$q&branch=$BRANCH"
  printf 'آخر %s تشغيلة في %s\n' "$RUNS_LIMIT" "$CI_REPO"
  printf '%s\n' '----------------------------------------------------------------------'
  rows="$(gh api "$q" --jq '.workflow_runs[] | [.status,(.conclusion // "—"),.id,.head_branch,(.display_title|.[0:48]),.head_sha] | @tsv' 2>&1)" ||
    die "فشل الطلب: $rows"
  if [[ "$JSON_OUT" == "1" ]]; then
    printf '%s\n' "$rows" | awk -F'\t' 'BEGIN{printf "["}
      {gsub(/"/,"\\\"",$5); printf "%s{\"status\":\"%s\",\"conclusion\":\"%s\",\"run_id\":\"%s\",\"branch\":\"%s\",\"title\":\"%s\",\"sha\":\"%s\"}", (NR>1?",":""), $1,$2,$3,$4,$5,$6}
      END{printf "]\n"}'
    exit 0
  fi
  printf '%s\n' "$rows" | while IFS=$'\t' read -r st co id br ti sha; do
    case "$co" in
      success) cc="${C_GREEN}$co${C_NC}" ;;
      failure | cancelled) cc="${C_RED}$co${C_NC}" ;;
      *) cc="${C_YELLOW}${co:-—}${C_NC}" ;;
    esac
    printf '  %-11s %-18s %-12s %-30s %s %s\n' "${st:0:11}" "$cc" "$id" "$br" "${ti}" "${sha:0:7}"
  done
  printf '\n  للتفاصيل: ./scripts/ci-logs.sh <run-id>\n'
  exit 0
fi

# ---------- اختيار الـ run ----------
if [[ "$RUN_ARG" == "latest" ]]; then
  q="repos/$CI_REPO/actions/runs?per_page=1"
  if [[ -n "$BRANCH" ]]; then
    q="$q&branch=$BRANCH"
  else
    cur="$(git -C "$PROJECT_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || printf '')"
    [[ -n "$cur" && "$cur" != "HEAD" ]] && q="$q&branch=$cur"
  fi
  RUN_ID="$(gh api "$q" --jq '.workflow_runs[0].id' 2>/dev/null || printf '')"
  [[ -n "$RUN_ID" ]] || die "لا يوجد أي run مطابق — حدّد --branch <اسم> أو رقماً صريحاً (جرّب: --runs)"
else
  RUN_ID="$RUN_ARG"
fi

hd "التشغيل $RUN_ID · $CI_REPO"
meta="$(gh api "repos/$CI_REPO/actions/runs/$RUN_ID" \
  --jq '[.status,(.conclusion // "—"),.head_branch,.head_sha,.display_title,.html_url,(.name // "")] | @tsv' 2>&1)" ||
  die "تعذّر قراءة الـ run $RUN_ID — $meta"
IFS=$'\t' read -r R_STATUS R_CONC R_BRANCH R_SHA R_TITLE R_URL R_WF <<<"$meta"

printf '  Workflow     : %s\n' "${R_WF:-—}"
printf '  الحالة       : %s\n' "$R_STATUS"
printf '  الاستنتاج    : %s\n' "$R_CONC"
printf '  الفرع        : %s\n' "$R_BRANCH"
printf '  الكوميت      : %s\n' "${R_SHA:0:10}"
printf '  العنوان      : %s\n' "$R_TITLE"
printf '  الرابط       : %s\n' "$R_URL"

# ---------- الخطوات ----------
hd "الخطوات"
steps="$(gh api "repos/$CI_REPO/actions/runs/$RUN_ID/jobs" \
  --jq '.jobs[] | .name as $j | (.steps[] | [$j,(.conclusion // .status),.name] | @tsv)' 2>&1)" ||
  die "تعذّر قراءة الـ jobs — $steps"
FAILED_STEPS=""
LAST_JOB=""
while IFS=$'\t' read -r job concl name; do
  [[ -n "$name" ]] || continue
  if [[ -n "$job" && "$job" != "$LAST_JOB" ]]; then
    printf '  %s— job: %s%s\n' "$C_BOLD" "$job" "$C_NC"
    LAST_JOB="$job"
  fi
  mark="  · "
  case "$concl" in
    success) mark="${C_GREEN}  ✓${C_NC} " ;;
    failure | cancelled)
      mark="${C_RED}  ✗${C_NC} "
      FAILED_STEPS="${FAILED_STEPS}${FAILED_STEPS:+ · }${name}"
      ;;
    skipped) mark="  - " ;;
  esac
  printf '%s%-46s %s\n' "$mark" "${name:0:46}" "$concl"
done <<<"$steps"

if [[ -n "$FAILED_STEPS" ]]; then
  err "خطوات فاشلة: $FAILED_STEPS"
else
  ok "لا خطوة بحالة failure"
fi

# ---------- التعليقات ----------
hd "التعليقات (annotations)"
ANN_FILE="$RUN_ID-annotations.tsv"
: >"$ANN_FILE"
while IFS= read -r cri; do
  [[ -n "$cri" ]] || continue
  gh api "${cri}/annotations" --jq '.[]? | [.annotation_level,(.path // "—"),((.start_line // 0)|tostring),.message] | @tsv' 2>/dev/null >>"$ANN_FILE" || true
done < <(gh api "repos/$CI_REPO/actions/runs/$RUN_ID/jobs" --jq '.jobs[].check_run_url' 2>/dev/null || true)

if [[ -s "$ANN_FILE" ]]; then
  printf '  %s تعليق (الملف الكامل: %s)\n' "$(grep -c . "$ANN_FILE")" "$ANN_FILE"
  fails="$(awk -F'\t' '$1=="failure"' "$ANN_FILE" 2>/dev/null | head -n "$LIMIT")"
  if [[ -n "$fails" ]]; then
    printf '%s\n' "$fails" | while IFS=$'\t' read -r lvl path line msg; do
      printf '    %s✗%s [%s:%s] %s\n' "$C_RED" "$C_NC" "$path" "$line" "${msg//$'\n'/ }"
    done
  else
    info "لا تعليقات من نوع failure — راجع «التشخيص» أدناه."
  fi
  awk -F'\t' '$1!="failure"' "$ANN_FILE" 2>/dev/null | head -n 4 | while IFS=$'\t' read -r lvl path line msg; do
    printf '    • %s [%s:%s] %s\n' "${lvl:-info}" "$path" "$line" "${msg//$'\n'/ }"
  done
else
  info "لا توجد annotations. لإضافتها في الـ workflow: استخدم ::error:: على أسطر الخطأ"
  info "أو خطوة «Annotate build errors» (نموذج جاهز في TEAM_COLLABORATION.md §0)."
fi

# ---------- الـ artifacts ----------
hd "المخرجات المرفوعة (artifacts)"
art="$(gh api "repos/$CI_REPO/actions/runs/$RUN_ID/artifacts" \
  --jq '.artifacts[] | [.name,(.size_in_bytes|tostring),.expired] | @tsv' 2>&1)" || art=""
APK_REAL=0
if [[ -z "${art//[[:space:]]/}" ]]; then
  warn "لا يوجد أي artifact مرفوع في هذا التشغيل."
else
  while IFS=$'\t' read -r name size expired; do
    [[ -n "$name" ]] || continue
    sz="$(human "$size")"
    case "$name" in
      *apk* | *aab* | *artifact*)
        if [[ "${size:-0}" -lt "$MIN_APK_BYTES" ]]; then
          printf '  %s⚠%s %-26s %s  ← أصغر من أن يكون APK حقيقياً (placeholder على الأرجح)\n' "$C_YELLOW" "$C_NC" "$name" "$sz"
        else
          printf '  %s✓%s %-26s %s  ← حجم منطقي لـ APK\n' "$C_GREEN" "$C_NC" "$name" "$sz"
          APK_REAL=$((APK_REAL + 1))
        fi
        ;;
      *log* | *report* | *summary*)
        printf '    • %-26s %s  ← سجل بناء (نزّله: gh run download %s --repo %s --name %s --dir ./ci-log)\n' "$name" "$sz" "$RUN_ID" "$CI_REPO" "$name"
        ;;
      *)
        printf '    • %-26s %s%s\n' "$name" "$sz" "$( [[ "$expired" == "true" ]] && printf '  (منتهي الصلاحية)' )"
        ;;
    esac
  done <<<"$art"
fi

# ---------- الحكم ----------
hd "التشخيص"
VERDICT="ok"
if [[ "$R_CONC" == "success" && "$APK_REAL" -eq 0 ]]; then
  err "النتيجة خضراء لكن لا يوجد APK حقيقي — لا تعتمد على هذا التشغيل."
  printf '   أسباب معروفة في .github/workflows الحالية بهذا المستودع:\n'
  printf '     • خطوة البناء تستخدم set +e و تحفظ BUILD_EXIT في GITHUB_ENV دون فحصها ⇒ لا شيء يفشل الـ job.\n'
  printf '     • خطوة البحث عن APK تكتب apk-output/no-apk.txt عند غياب البناء + if-no-files-found: warn.\n'
  printf '     • حفظ ci-build.log في git يفشل بصمت لأن .gitignore يحتوي *.log (يحتاج git add -f أو رفعه كأثر).\n'
  printf '     • لا خطوة annotations ⇒ API لا يُظهر شيئاً حين يُحجب السجل الخام.\n'
  printf '   الرقع الجاهزة: TEAM_COLLABORATION.md §0 · خطوات البناء المحلي: BUILD_GUIDE.md §3\n'
  VERDICT="fake-green"
elif [[ "$R_CONC" == "success" ]]; then
  ok "بناء ناجح فعلاً: $APK_REAL artifact بحجم منطقي."
  printf '   نزّله: gh run download %s --repo %s --name <artifact-name> --dir ./ci-apk\n' "$RUN_ID" "$CI_REPO"
elif [[ "$R_STATUS" == "in_progress" ]]; then
  warn "التشغيل ما زال قيد التنفيذ — أعد المحاولة بعد دقائق."
  VERDICT="running"
else
  VERDICT="failed"
  if [[ -s "$ANN_FILE" ]] && awk -F'\t' '$1=="failure"{found=1} END{exit !found}' "$ANN_FILE"; then
    printf '   اقرأ رسائل ✗ أعلاه؛ إن كانت «Java heap space» فالحل في TROUBLESHOOTING.md §1.1\n'
  else
    printf '   لا رسائل خطأ متاحة عبر API: اطلب من المنسّق إضافة خطوة annotations إلى الـ workflow.\n'
  fi
fi

if [[ "$JSON_OUT" == "1" ]]; then
  printf '\n'
  printf '{\n'
  printf '  "run_id": "%s",\n' "$RUN_ID"
  printf '  "status": "%s",\n' "$R_STATUS"
  printf '  "conclusion": "%s",\n' "$R_CONC"
  printf '  "branch": "%s",\n' "$R_BRANCH"
  printf '  "sha": "%s",\n' "$R_SHA"
  printf '  "failed_steps": "%s",\n' "${FAILED_STEPS//\"/\'}"
  printf '  "real_apk_artifacts": %s,\n' "$APK_REAL"
  printf '  "verdict": "%s",\n' "$VERDICT"
  printf '  "annotations_tsv": "%s"\n' "$ANN_FILE"
  printf '}\n'
fi

case "$VERDICT" in
  ok) exit 0 ;;
  *) [[ "$GATE" == "1" ]] && exit 1 || exit 0 ;;
esac
