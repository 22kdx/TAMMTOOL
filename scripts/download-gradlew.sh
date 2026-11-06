#!/usr/bin/env bash
#
# download-gradlew.sh - تحميل ملفات Gradle Wrapper مباشرة
# جزء من مستودع TAMMTOOL
#
# يقوم بتحميل توزيع Gradle الكامل، استخراج ملفات الـ Wrapper (gradle-wrapper.jar,
# gradle-wrapper.properties)، وإنشاء سكريبت gradlew دون الحاجة إلى تثبيت
# أداة gradle على النظام.
#
# الاستخدام:
#   ./scripts/download-gradlew.sh [النسخة]
#
# مثال:
#   ./scripts/download-gradlew.sh 8.5

set -euo pipefail

GRADLE_VERSION="${1:-8.5}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ألوان للإخراج
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info()  { echo -e "${YELLOW}[ℹ]${NC} $*"; }
log_ok()    { echo -e "${GREEN}[✓]${NC} $*"; }
log_error() { echo -e "${RED}[✗]${NC} $*"; }

# ============================================================
# تحميل Gradle Wrapper للتطبيق المحدد
# ============================================================
download_wrapper() {
  local app_dir="$1"
  local wrapper_dir="$app_dir/gradle/wrapper"

  if [[ -x "$app_dir/gradlew" ]]; then
    log_info "Gradle Wrapper موجود بالفعل في: $app_dir"
    return 0
  fi

  log_info "تحميل Gradle Wrapper الإصدار $GRADLE_VERSION لـ: $app_dir"
  mkdir -p "$wrapper_dir"

  # تحميل توزيع Gradle الكامل
  local gradle_zip="$PROJECT_ROOT/.gradle-${GRADLE_VERSION}-bin.zip"
  local gradle_dist_url="https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip"

  log_info "جاري تحميل توزيع Gradle ${GRADLE_VERSION}..."
  curl -L --fail --retry 3 --retry-delay 5 \
    -o "$gradle_zip" \
    "$gradle_dist_url"

  # استخراج gradle-wrapper.jar من التوزيع
  log_info "استخراج gradle-wrapper.jar..."
  if command -v unzip &> /dev/null; then
    unzip -o -j "$gradle_zip" "gradle-${GRADLE_VERSION}/lib/gradle/wrapper/gradle-wrapper.jar" -d "$wrapper_dir" 2>/dev/null || \
    unzip -o -j "$gradle_zip" "gradle-${GRADLE_VERSION}/lib/plugins/gradle-wrapper.jar" -d "$wrapper_dir" 2>/dev/null || \
    unzip -l "$gradle_zip" | grep "wrapper/gradle-wrapper.jar" | head -1 | awk '{print $4}' | xargs -I{} unzip -o -j "$gradle_zip" "{}" -d "$wrapper_dir"
  else
    log_error "أداة unzip غير مثبتة."
    rm -f "$gradle_zip"
    exit 1
  fi

  if [[ ! -f "$wrapper_dir/gradle-wrapper.jar" ]]; then
    log_error "فشل العثور على gradle-wrapper.jar داخل التوزيع المحمل."
    rm -f "$gradle_zip"
    exit 1
  fi

  # إعداد ملف الخصائص
  log_info "إعداد gradle-wrapper.properties..."
  cat > "$wrapper_dir/gradle-wrapper.properties" << 'EOF'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.5-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF

  # إنشاء سكريبت gradlew (UNIX)
  log_info "إنشاء سكريبت gradlew..."
  cat > "$app_dir/gradlew" << 'WRAPPER_EOF'
#!/usr/bin/env sh

APP_HOME=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd) || exit
DEFAULT_JVM_OPTS='"-Xmx64m" "-Xms64m"'
MAX_FD="maximum"

warn () { echo "$*"; }
die () { echo; echo "$*"; echo; exit 1; }

cygwin=false
msys=false
darwin=false
nonstop=false
case "$(uname)" in
  CYGWIN* ) cygwin=true ;;
  Darwin* ) darwin=true ;;
  MINGW* ) msys=true ;;
  NONSTOP* ) nonstop=true ;;
esac

CLASSPATH=$APP_HOME/gradle/wrapper/gradle-wrapper.jar

if [ -n "$JAVA_HOME" ] ; then
    if [ -x "$JAVA_HOME/jre/sh/java" ] ; then
        JAVACMD="$JAVA_HOME/jre/sh/java"
    else
        JAVACMD="$JAVA_HOME/bin/java"
    fi
    if [ ! -x "$JAVACMD" ] ; then
        die "ERROR: JAVA_HOME is set to an invalid directory: $JAVA_HOME"
    fi
else
    JAVACMD="java"
    which java >/dev/null 2>&1 || die "ERROR: JAVA_HOME is not set and no 'java' command could be found in your PATH."
fi

if [ "$cygwin" = "false" -a "$darwin" = "false" ] ; then
    MAX_FD_LIMIT=$(ulimit -H -n)
    if [ $? -eq 0 ] ; then
        if [ "$MAX_FD" = "maximum" -o "$MAX_FD" = "max" ] ; then
            MAX_FD="$MAX_FD_LIMIT"
        fi
        ulimit -n $MAX_FD || warn "Could not set maximum file descriptor limit: $MAX_FD"
    fi
fi

STDIN=
exec "$JAVACMD" \
    $DEFAULT_JVM_OPTS \
    -classpath "$CLASSPATH" \
    org.gradle.wrapper.GradleWrapperMain \
    "$@"
WRAPPER_EOF

  # إنشاء سكريبت gradlew.bat (Windows)
  cat > "$app_dir/gradlew.bat" << 'BAT_EOF'
@rem
@rem Copyright 2015 the original author or authors.
@rem
@rem Licensed under the Apache License, Version 2.0 (the "License");
@rem you may not use this file except in compliance with the License.
@rem You may obtain a copy of the License at
@rem
@rem      https://www.apache.org/licenses/LICENSE-2.0
@rem
@rem Unless required by applicable law or agreed to in writing, software
@rem distributed under the License is distributed on an "AS IS" BASIS,
@rem WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
@rem See the License for the specific language governing permissions and
@rem limitations under the License.
@rem

@if "%DEBUG%"=="" @echo off
@rem ##########################################################################
@rem
@rem  Gradle startup script for Windows
@rem
@rem ##########################################################################

@rem Set local scope for the variables with windows NT shell
if "%OS%"=="Windows_NT" setlocal

set DIRNAME=%~dp0
if "%DIRNAME%"=="" set DIRNAME=.
set APP_BASE_NAME=%~n0
set APP_HOME=%DIRNAME%

@rem Resolve any "." and ".." in APP_HOME to make it shorter.
for %%i in ("%APP_HOME%") do set APP_HOME=%%~fi

@rem Add default JVM options here. You can also use JAVA_OPTS and GRADLE_OPTS to pass JVM options to this script.
set DEFAULT_JVM_OPTS="-Xmx64m" "-Xms64m"

@rem Find java.exe
if defined JAVA_HOME goto findJavaFromJavaHome

set JAVA_EXE=java.exe
%JAVA_EXE% -version >NUL 2>&1
if "%ERRORLEVEL%"=="0" goto init

echo.
echo ERROR: JAVA_HOME is not set and no 'java' command could be found in your PATH.
echo.
echo Please set the JAVA_HOME variable in your environment to match the
echo location of your Java installation.

goto fail

:findJavaFromJavaHome
set JAVA_HOME=%JAVA_HOME:"=%
set JAVA_EXE=%JAVA_HOME%/bin/java.exe

if exist "%JAVA_EXE%" goto init

echo.
echo ERROR: JAVA_HOME is set to an invalid directory: %JAVA_HOME%
echo.
echo Please set the JAVA_HOME variable in your environment to match the
echo location of your Java installation.

goto fail

:init
@rem Get command-line arguments, handling Windows variants

if not "%OS%"=="Windows_NT" goto win9xME_args

:win9xME_args
@rem Slurp the command line arguments.
set CMD_LINE_ARGS=
set _SKIP=2

:win9xME_args_slurp
if "x%~1"=="x" goto execute

set CMD_LINE_ARGS=%*
goto execute

:execute
@rem Setup the command line

set CLASSPATH=%APP_HOME%\gradle\wrapper\gradle-wrapper.jar

@rem Execute Gradle
"%JAVA_EXE%" %DEFAULT_JVM_OPTS% -classpath "%CLASSPATH%" org.gradle.wrapper.GradleWrapperMain %CMD_LINE_ARGS%

:end
@rem End local scope for the variables with windows NT shell
if "%ERRORLEVEL%"=="0" goto mainEnd

:fail
rem Set variable GRADLE_EXIT_CONSOLE if you need the _script_ return code instead of
rem the _cmd.exe /c_ return code.
set EXIT_CODE=%ERRORLEVEL%
if %EXIT_CODE%==0 set EXIT_CODE=1
goto done

:mainEnd
if "%OS%"=="Windows_NT" endlocal

:done
BAT_EOF

  chmod +x "$app_dir/gradlew"

  # تنظيف ملف zip المؤقت
  rm -f "$gradle_zip"

  log_ok "تم تحميل Gradle Wrapper بنجاح في: $app_dir"
}

# ============================================================
# التنفيذ
# ============================================================
echo "============================================="
echo "  TAMMTOOL - تحميل Gradle Wrapper"
echo "============================================="
echo "الإصدار: $GRADLE_VERSION"
echo ""

# تحميل للتطبيقين
download_wrapper "$PROJECT_ROOT/apps/marketer"
download_wrapper "$PROJECT_ROOT/apps/orders-delivery"

echo ""
log_ok "اكتمل تحميل Gradle Wrapper لجميع التطبيقات."
