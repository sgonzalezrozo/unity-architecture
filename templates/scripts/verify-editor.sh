#!/usr/bin/env bash
# Checks the project while the Unity Editor is open, from the reports the Editor writes to Logs/verify/
# (Assets/Editor/UnityArchitecture, installed by .ai/templates/scripts/install.sh). verify.sh can't run then,
# because batch mode can't open a project the Editor has open.
# The agent compiles and runs tests through a Unity MCP server (refresh_unity, run_tests); this script only reads
# the results. Exit codes: 0 passed, 1 failed or out of date, 2 couldn't check.
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/Logs/verify"
COMPILE="$OUT/editor-compile.json"
TESTS="$OUT/editor-tests.json"
GENERATION_STATUS="$ROOT/Assets/FastIoC/Generated/GenerationStatus.json"

json_number() {
    sed -n "s/.*\"$1\": *\\([0-9][0-9]*\\).*/\\1/p" "$2" | head -1
}

json_list() {
    sed -n "/\"$1\": *\\[/,/\\]/p" "$2" | sed '1d;$d' | sed 's/^ *"//; s/",* *$//; s/^/  /'
}

modified_time() {
    stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null || echo 0
}

# Files that make Unity compile, among the changes git sees: the project's own, and those of local packages
# ("file:" entries in Packages/manifest.json) that sit in their own Git work trees.
changed_script_files() {
    (cd "$ROOT" && git status --porcelain --untracked-files=all -- Assets Packages 2>/dev/null \
        | sed 's/^...//; s/^.* -> //; s/^"//; s/"$//; s|^|'"$ROOT"'/|')
    sed -n 's/.*"file:\([^"]*\)".*/\1/p' "$ROOT/Packages/manifest.json" 2>/dev/null | while IFS= read -r path; do
        case "$path" in
            /*) dir="$path" ;;
            *) dir="$ROOT/Packages/$path" ;;
        esac
        dir="$(cd "$dir" 2>/dev/null && pwd)" || continue
        git -C "$dir" status --porcelain --untracked-files=all 2>/dev/null \
            | sed 's/^...//; s/^.* -> //; s/^"//; s/"$//; s|^|'"$dir"'/|'
    done
}

newest_script_change() {
    local newest=0 path time
    while IFS= read -r path; do
        [ -f "$path" ] || continue
        time="$(modified_time "$path")"
        [ "$time" -gt "$newest" ] && newest="$time"
    done < <(changed_script_files | grep -v '~/' | grep -E '\.(cs|asmdef|asmref|rsp)$|/Packages/manifest\.json$')
    echo "$newest"
}

if [ ! -f "$COMPILE" ]; then
    echo "The Editor is open, but it hasn't written Logs/verify/editor-compile.json yet."
    echo "Run bash .ai/templates/scripts/install.sh so Assets/Editor/UnityArchitecture is in the project, let Unity compile once, then try again."
    exit 2
fi

if grep -Eq '"compiling": *true' "$COMPILE"; then
    echo "Unity is compiling. Wait until it finishes (read_console through the Unity MCP), then check again."
    exit 1
fi

COMPILED_AT="$(json_number finishedAtUnixSeconds "$COMPILE")"
COMPILED_AT="${COMPILED_AT:-0}"
NEWEST_CHANGE="$(newest_script_change)"
if [ "$NEWEST_CHANGE" -gt "$COMPILED_AT" ]; then
    echo "Unity hasn't compiled the latest script changes: the Editor only refreshes when asked or focused."
    echo "Call refresh_unity through the Unity MCP, wait for the compile to finish, read_console, then check again."
    exit 1
fi

ERRORS="$(json_number errorCount "$COMPILE")"
if [ "${ERRORS:-0}" != "0" ]; then
    echo "Compilation failed in the Editor ($ERRORS error(s)):"
    json_list errors "$COMPILE"
    exit 1
fi

if grep -qs '"com.unity.test-framework"' "$ROOT/Packages/manifest.json" "$ROOT/Packages/packages-lock.json"; then
    # Compared with the newest script change, not the last compile: Unity also compiles after a test run, with no
    # script changed. A run that started after the change tested the code as it is.
    TESTED_AT="$(json_number startedAtUnixSeconds "$TESTS" 2>/dev/null)"
    [ -n "$TESTED_AT" ] || TESTED_AT="$(json_number finishedAtUnixSeconds "$TESTS" 2>/dev/null)"
    if [ ! -f "$TESTS" ] || [ "${TESTED_AT:-0}" -lt "$NEWEST_CHANGE" ]; then
        echo "The EditMode tests haven't run since the last script change."
        echo "Run them with run_tests through the Unity MCP (EditMode), poll get_test_job until it finishes, then check again."
        exit 1
    fi

    FAILED="$(json_number failed "$TESTS")"
    if [ "${FAILED:-0}" != "0" ]; then
        echo "Tests failed: $FAILED of $(json_number total "$TESTS"):"
        json_list failures "$TESTS"
        exit 1
    fi
    TOTAL="$(json_number total "$TESTS")"
fi

# A failed Fast IoC generation doesn't stop the compile, so check its status file.
if [ -f "$GENERATION_STATUS" ] && grep -Eq '"status": *1' "$GENERATION_STATUS"; then
    echo "Fast IoC code generation failed. Fix the installers or constructors, not the generated code:"
    sed -n 's/.*"errorReason": *"\(.*\)",*$/  \1/p' "$GENERATION_STATUS"
    exit 1
fi

if [ -n "${TOTAL:-}" ]; then
    echo "Verify passed in the open Editor: compiled, ${TOTAL} tests."
else
    echo "Verify passed in the open Editor: compiled. No tests ran: the Test Framework package isn't installed."
fi
exit 0
