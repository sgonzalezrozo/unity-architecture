#!/usr/bin/env bash
# Compiles the project, runs the EditMode tests in batch mode and checks Fast IoC code generation.
# Exit codes: 0 passed, 1 failed, 2 couldn't run.
# Set UNITY_PATH to use a specific Unity executable. Close the project in the Editor first.
# Set VERIFY_COMPILE_ONLY=1 to only compile, as the Stop hook does between test runs.
# Set VERIFY_TEST_FILTER to run only some tests: names or a regex, separated by ";", as Unity's -testFilter takes them.
# Writes Logs/verify/summary.json so agents and CI can read the result without parsing text.
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/Logs/verify"
LOG="$OUT/unity.log"
RESULTS="$OUT/results.xml"
SUMMARY_JSON="$OUT/summary.json"
GENERATION_STATUS="$ROOT/Assets/FastIoC/Generated/GenerationStatus.json"
VERSION="$(sed -n 's/^m_EditorVersion: //p' "$ROOT/ProjectSettings/ProjectVersion.txt" | tr -d '\r')"

# The editor folder Unity Hub installs into by default, and the one set in Hub > Preferences > Installs, if any.
editor_folders() {
    local hub_config=""
    case "$(uname -s)" in
        Darwin)
            echo "/Applications/Unity/Hub/Editor"
            hub_config="$HOME/Library/Application Support/UnityHub" ;;
        Linux)
            echo "$HOME/Unity/Hub/Editor"
            hub_config="$HOME/.config/UnityHub" ;;
        MINGW*|MSYS*|CYGWIN*)
            echo "/c/Program Files/Unity/Hub/Editor"
            hub_config="$(cygpath -u "${APPDATA:-}" 2>/dev/null)/UnityHub" ;;
    esac

    local secondary
    secondary="$(sed 's/^"//; s/"$//; s/\\\\/\//g' "$hub_config/secondaryInstallPath.json" 2>/dev/null)"
    if [ -n "$secondary" ]; then
        case "$(uname -s)" in
            MINGW*|MSYS*|CYGWIN*) cygpath -u "$secondary" 2>/dev/null || echo "$secondary" ;;
            *) echo "$secondary" ;;
        esac
    fi
}

editor_executable() {
    case "$(uname -s)" in
        Darwin) echo "$1/$VERSION/Unity.app/Contents/MacOS/Unity" ;;
        Linux) echo "$1/$VERSION/Editor/Unity" ;;
        MINGW*|MSYS*|CYGWIN*) echo "$1/$VERSION/Editor/Unity.exe" ;;
    esac
}

default_unity_path() {
    local folder candidate first=""
    while IFS= read -r folder; do
        [ -z "$folder" ] && continue
        candidate="$(editor_executable "$folder")"
        [ -z "$first" ] && first="$candidate"
        if [ -x "$candidate" ]; then
            echo "$candidate"
            return
        fi
    done < <(editor_folders)
    echo "$first"
}

UNITY="${UNITY_PATH:-$(default_unity_path)}"

mkdir -p "$OUT"
rm -f "$LOG" "$RESULTS" "$SUMMARY_JSON"

# Writes the machine-readable result: summary <result> <message> [total] [failed]
summary() {
    local message="${2//\\/\\\\}"
    message="${message//\"/\\\"}"
    printf '{"result": "%s", "message": "%s", "unityVersion": "%s", "testsTotal": %s, "testsFailed": %s}\n' \
        "$1" "$message" "$VERSION" "${3:-null}" "${4:-null}" > "$SUMMARY_JSON"
}

if [ ! -x "$UNITY" ]; then
    echo "Unity $VERSION not found at: $UNITY"
    echo "Install it from Unity Hub, or set UNITY_PATH to the Unity executable."
    summary "not-run" "Unity $VERSION not found"
    exit 2
fi

# The tests related to a change (TEST-11), when VERIFY_TEST_FILTER names them.
FILTER_ARGS=()
if [ -n "${VERIFY_TEST_FILTER:-}" ]; then
    FILTER_ARGS=(-testFilter "$VERIFY_TEST_FILTER")
fi

START_MARKER="$OUT/.started"
touch "$START_MARKER"

# Data assets described by a spec (EDIT-14) that don't exist yet are built first, in their own batch run, so the main
# run's compile and the Fast IoC generation already find them. Nothing runs when every spec has its asset.
MISSING_SPECS="$(find "$ROOT/Assets/Client" -name '*.asset.json' 2>/dev/null | while IFS= read -r spec; do
    [ -e "${spec%.json}" ] || echo "${spec#"$ROOT"/}"
done)"
if [ -n "$MISSING_SPECS" ]; then
    SPECS_LOG="$OUT/unity-asset-specs.log"
    "$UNITY" -batchmode -nographics -quit -projectPath "$ROOT" \
        -executeMethod UnityArchitecture.Prefabs.AssetSpecs.BuildMissingFromCommandLine -logFile "$SPECS_LOG"
    SPECS_CODE=$?
    # With compile errors the method can't run: the main run below reports them.
    if [ "$SPECS_CODE" -ne 0 ] && ! grep -qE 'error [A-Z]{2,}[0-9]{4}' "$SPECS_LOG" 2>/dev/null; then
        echo "Building data assets from their specs failed (EDIT-14):"
        cat "$ROOT/Logs/verify/asset-specs.txt" 2>/dev/null || echo "$MISSING_SPECS"
        summary "failed" "Building data assets from their specs failed"
        exit 1
    fi
fi

# Without the Test Framework package, Unity ignores -runTests and never quits, so only compile.
COMPILE_ONLY="${VERIFY_COMPILE_ONLY:-0}"
if [ "$COMPILE_ONLY" != "1" ] && grep -qs '"com.unity.test-framework"' "$ROOT/Packages/manifest.json" "$ROOT/Packages/packages-lock.json"; then
    RUN_TESTS=true
    "$UNITY" -batchmode -nographics -projectPath "$ROOT" \
        -runTests -testPlatform EditMode -testResults "$RESULTS" "${FILTER_ARGS[@]+"${FILTER_ARGS[@]}"}" -logFile "$LOG"
else
    RUN_TESTS=false
    "$UNITY" -batchmode -nographics -quit -projectPath "$ROOT" -logFile "$LOG"
fi
CODE=$?

if grep -q 'another Unity instance is running' "$LOG" 2>/dev/null; then
    echo "Close this project in the Unity Editor, then run verify again."
    summary "not-run" "The project is open in the Unity Editor"
    exit 2
fi

# Compiler errors (CS) and analyzer errors (UA and any other prefix) both fail the build.
ERRORS="$(grep -E 'error [A-Z]{2,}[0-9]{4}' "$LOG" 2>/dev/null | sort -u)"
if [ -n "$ERRORS" ]; then
    echo "Compilation failed:"
    echo "$ERRORS"
    summary "failed" "Compilation failed: $(echo "$ERRORS" | wc -l | tr -d ' ') error(s)"
    exit 1
fi

if [ "$RUN_TESTS" = false ]; then
    if [ "$CODE" -ne 0 ]; then
        echo "Unity exited with code $CODE. See $LOG"
        summary "not-run" "Unity exited with code $CODE"
        exit 2
    fi
    TOTAL=0
elif [ ! -f "$RESULTS" ]; then
    echo "Unity exited with code $CODE and wrote no test results. See $LOG"
    summary "not-run" "Unity exited with code $CODE and wrote no test results"
    exit 2
fi

if [ "$RUN_TESTS" = true ]; then
    RUN="$(grep -m1 '<test-run' "$RESULTS")"
    TOTAL="$(echo "$RUN" | sed -n 's/.* total="\([0-9]*\)".*/\1/p')"
    FAILED="$(echo "$RUN" | sed -n 's/.* failed="\([0-9]*\)".*/\1/p')"
fi

if [ "$RUN_TESTS" = true ] && { [ "$CODE" -ne 0 ] || [ "${FAILED:-1}" != "0" ]; }; then
    echo "Tests failed: ${FAILED:-unknown} of ${TOTAL:-unknown}. See $RESULTS"
    grep '<test-case ' "$RESULTS" | grep 'result="Failed"' | sed -n 's/.* fullname="\([^"]*\)".*/  \1/p'
    summary "failed" "Tests failed: ${FAILED:-unknown} of ${TOTAL:-unknown}" "${TOTAL:-null}" "${FAILED:-null}"
    exit 1
fi

# A failed Fast IoC generation doesn't stop the compile, so check its status file.
if [ -f "$GENERATION_STATUS" ]; then
    if grep -Eq '"status": *1' "$GENERATION_STATUS"; then
        echo "Fast IoC code generation failed. Fix the installers or constructors, not the generated code:"
        sed -n 's/.*"errorReason": *"\(.*\)",*$/  \1/p' "$GENERATION_STATUS"
        grep -A50 '"errorDetails"' "$GENERATION_STATUS" | sed -n 's/^ *"\(.*\)",*$/  \1/p' | grep -v '^  items$'
        summary "failed" "Fast IoC code generation failed" "$TOTAL" "0"
        exit 1
    fi
    if [ ! "$GENERATION_STATUS" -nt "$START_MARKER" ]; then
        echo "Note: GenerationStatus.json wasn't rewritten during this run, so it may be stale."
    fi
fi

if [ "$COMPILE_ONLY" = "1" ]; then
    echo "Verify passed: compiled."
    summary "passed" "Compiled; tests not run (VERIFY_COMPILE_ONLY)" "0" "0"
elif [ "$RUN_TESTS" = false ]; then
    echo "Verify passed: compiled. No tests ran: add the Test Framework package (com.unity.test-framework) to run EditMode tests."
    summary "passed" "Compiled; no tests ran because the Test Framework package isn't installed" "0" "0"
else
    echo "Verify passed: $TOTAL tests."
    summary "passed" "Verify passed: $TOTAL tests" "$TOTAL" "0"
fi
