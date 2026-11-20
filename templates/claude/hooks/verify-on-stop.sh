#!/usr/bin/env bash
# Stop hook: an agent can't finish with a broken build.
# When Unity files changed, it checks the project and sends failures back to the agent:
# with the Editor closed it runs scripts/verify.sh (batch mode); with the Editor open, scripts/verify-editor.sh,
# which reads the compile and test results the Editor writes (with a Unity MCP, the agent compiles and tests there;
# without one, an out-of-date result is reported, not sent back as a failure).
set -u

MAX_ATTEMPTS=3

ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
STATE="$ROOT/Logs/verify"
PASSED_FILE="$STATE/last-passed"
ATTEMPTS_FILE="$STATE/attempts"
# Which tests a change owes. When the user names the feature a task is about (TEST-13), the agent writes its folder
# to Logs/verify/test-scope, one path per line (Assets/Client/Inventory). Then every stop runs the tests of those
# features and of every feature the change touched (namespace Client.{Feature}). With no scope file, or a change that
# can affect any feature (Shared, Client.asmdef, Packages, ProjectSettings...), the scope is the whole project.
# The file can only add tests: the features a change touched are always tested.
SCOPE_FILE="$STATE/test-scope"
CLIENT="Assets/Client"
ALL="*"
# Compiling is quick and runs on every stop. The full suite is slow, so it runs at most every
# VERIFY_TESTS_EVERY_SECONDS (2 hours by default) when the scope is the whole project, and every
# VERIFY_FULL_TESTS_EVERY_SECONDS (24 hours by default) while it's a few features, whose tests run on every stop.
# Either way, only for changes that haven't passed it yet.
TESTS_EVERY="${VERIFY_TESTS_EVERY_SECONDS:-7200}"
FULL_TESTS_EVERY="${VERIFY_FULL_TESTS_EVERY_SECONDS:-86400}"
LAST_TESTS_FILE="$STATE/last-tests"
TESTS_PENDING_FILE="$STATE/tests-pending"
# The prefab validator (TEST-12) has one case per feature folder under Assets/Client, named after it.
PREFAB_CASE_PREFIX="UnityArchitecture.Prefabs.Tests.ClientPrefabsTests."
# Unity files the agent can change. Code generators' output doesn't count: Fast IoC writes Assets/FastIoC/Generated and
# a FastIoC.InternalsVisibleTo.g.cs next to an assembly's .asmdef every time it compiles, and counting those would make
# each check look like a new change and run the verify again.
PATHSPEC=(Assets Packages ProjectSettings
    ':(exclude)Assets/FastIoC/Generated'
    ':(exclude,glob)**/*.g.cs'
    ':(exclude,glob)**/*.g.cs.meta')

cat > /dev/null
cd "$ROOT" || exit 0
mkdir -p "$STATE"

# Unity holds Temp/UnityLockfile while the project is open. lsof tells a live lock from one left by a crash.
editor_open() {
    local lock="$ROOT/Temp/UnityLockfile"
    [ -f "$lock" ] || return 1
    if command -v lsof >/dev/null 2>&1; then
        lsof "$lock" >/dev/null 2>&1
        return $?
    fi
    return 0
}

notify() {
    local message
    message="$(printf '%s' "$1" | tr '\n' ' ' | sed 's/\\/\\\\/g; s/"/\\"/g')"
    printf '{"systemMessage": "%s"}\n' "$message"
}

# The scope file counts too: naming another feature makes the same files owe its tests.
fingerprint() {
    {
        git status --porcelain -- "${PATHSPEC[@]}"
        git diff HEAD -- "${PATHSPEC[@]}"
        git ls-files --others --exclude-standard -z -- "${PATHSPEC[@]}" | xargs -0 git hash-object --
        cat "$SCOPE_FILE"
    } 2>/dev/null | git hash-object --stdin
}

# Every changed path, one per line: both sides of a rename, without Git's quotes.
changed_paths() {
    git status --porcelain --untracked-files=all -- "${PATHSPEC[@]}" 2>/dev/null | awk '{
        sub(/^.../, "")
        count = split($0, parts, / -> /)
        for (i = 1; i <= count; i++) { path = parts[i]; gsub(/^"|"$/, "", path); print path }
    }'
}

# The feature a path belongs to: its first folder under Assets/Client. Prints * for a path whose change can affect
# any feature: anything outside Assets/Client, Client.asmdef and the files next to it, Shared/, the test assemblies
# in Tests/ and PlayModeTests/, and the analyzers.
feature_of() {
    local rest="${1#"$CLIENT"/}" feature
    rest="${rest%/}"
    if [ "$rest" = "$1" ]; then
        echo "$ALL"
        return
    fi
    case "$rest" in
        */*) feature="${rest%%/*}" ;;
        *.meta) feature="${rest%.meta}" ;;
        *) feature="$rest"; [ -d "$CLIENT/$feature" ] || feature="$ALL" ;;
    esac
    case "$feature" in
        *.*|Shared|Tests|PlayModeTests|Analyzers) echo "$ALL" ;;
        *) echo "$feature" ;;
    esac
}

# The features the change and the scope file name, one per line, or * when the scope is the whole project.
scoped_features() {
    local path
    [ -f "$SCOPE_FILE" ] || { echo "$ALL"; return; }
    { grep -v '^[[:space:]]*$' "$SCOPE_FILE" | tr -d '\r'; changed_paths; } | while IFS= read -r path; do
        feature_of "$path"
    done | sort -u
}

# The feature folders, among those named, that have tests (a .cs file in a Tests folder).
features_with_tests() {
    local feature
    for feature in "$@"; do
        [ -n "$(find "$CLIENT/$feature" -path '*/Tests/*' -name '*.cs' 2>/dev/null | head -1)" ] && echo "$feature"
    done
}

# The features whose prefabs changed (Root for one directly in Assets/Client), for the prefab validator's cases.
prefab_features() {
    grep -qs '"com.sgonzalezrozo.unity-architecture"' Packages/manifest.json || return
    changed_paths | grep "^$CLIENT/.*\.prefab\$" | while IFS= read -r path; do
        [ -f "$path" ] || continue
        case "${path#"$CLIENT"/}" in
            */*) path="${path#"$CLIENT"/}"; echo "${path%%/*}" ;;
            *) echo "Root" ;;
        esac
    done | sort -u
}

# A -testFilter entry per test: ^Client\.Inventory\. for a feature's tests, and an exact prefab validator case.
test_filter() {
    local filter="" feature
    for feature in $1; do filter="$filter;^Client\\.$feature\\."; done
    for feature in $2; do filter="$filter;^${PREFAB_CASE_PREFIX//./\\.}$feature\$"; done
    echo "${filter#;}"
}

# Unix time of the last full test run that passed, one this hook asked for. A run in the Editor doesn't count: it may
# be filtered (the related tests, or the prefab validator), and it would keep pushing the full run back.
last_tests_time() {
    cat "$LAST_TESTS_FILE" 2>/dev/null || echo 0
}

# Nothing to check: no pending changes, or the same files already passed.
if [ -z "$(git status --porcelain -- "${PATHSPEC[@]}" 2>/dev/null)" ]; then
    exit 0
fi

CURRENT="$(fingerprint)"
SCOPED="$(scoped_features)"
if printf '%s\n' "$SCOPED" | grep -qxF "$ALL"; then
    FEATURES=""
    UNTIL_TESTS=$(( $(last_tests_time) + TESTS_EVERY - $(date +%s) ))
else
    FEATURES="$(features_with_tests $SCOPED | tr '\n' ' ')"
    FEATURES="${FEATURES% }"
    UNTIL_TESTS=$(( $(last_tests_time) + FULL_TESTS_EVERY - $(date +%s) ))
fi
if [ "$UNTIL_TESTS" -le 0 ]; then
    MODE=tests
elif [ -n "$FEATURES" ]; then
    MODE=features
else
    MODE=compile
fi

# These files already passed. Check them again only for the full suite they still owe, once it's due.
if [ "$CURRENT" = "$(cat "$PASSED_FILE" 2>/dev/null)" ]; then
    if [ "$MODE" != tests ] || [ ! -f "$TESTS_PENDING_FILE" ]; then
        exit 0
    fi
fi

if editor_open && [ -x scripts/verify-editor.sh ]; then
    VERIFY="scripts/verify-editor.sh"
else
    VERIFY="scripts/verify.sh"
fi

# A changed prefab gets its feature's prefab validator case (TEST-12) on every stop, even between test runs.
# With the Editor open, verify-editor.sh asks the agent to run it; with it closed, verify.sh runs it with the filter.
PREFAB_FEATURES="$(prefab_features | tr '\n' ' ')"
PREFAB_FEATURES="${PREFAB_FEATURES% }"

if [ "$VERIFY" = "scripts/verify.sh" ]; then
    case "$MODE" in
        features) export VERIFY_TEST_FILTER="$(test_filter "$FEATURES" "$PREFAB_FEATURES")" ;;
        compile)
            if [ -n "$PREFAB_FEATURES" ]; then
                export VERIFY_TEST_FILTER="$(test_filter "" "$PREFAB_FEATURES")"
            else
                export VERIFY_COMPILE_ONLY=1
            fi ;;
    esac
else
    case "$MODE" in
        features) export VERIFY_TEST_FEATURES="$FEATURES" ;;
        compile) export VERIFY_COMPILE_ONLY=1 ;;
    esac
fi
OUTPUT="$("$VERIFY" 2>&1)"
CODE=$?

case "$CODE" in
    0)
        echo "$CURRENT" > "$PASSED_FILE"
        rm -f "$ATTEMPTS_FILE"
        if [ "$MODE" = tests ]; then
            date +%s > "$LAST_TESTS_FILE"
            rm -f "$TESTS_PENDING_FILE"
            notify "$(echo "$OUTPUT" | tail -1)"
        else
            touch "$TESTS_PENDING_FILE"
            SCOPE_NOTE=""
            [ "$MODE" = features ] && SCOPE_NOTE=" Tests of $FEATURES ran."
            notify "$(echo "$OUTPUT" | tail -1)$SCOPE_NOTE The full suite runs when it's due, in $(( (UNTIL_TESTS + 59) / 60 )) min."
        fi
        exit 0
        ;;
    1)
        ATTEMPTS=$(( $(cat "$ATTEMPTS_FILE" 2>/dev/null || echo 0) + 1 ))
        if [ "$ATTEMPTS" -ge "$MAX_ATTEMPTS" ]; then
            rm -f "$ATTEMPTS_FILE"
            notify "Verify still fails after $MAX_ATTEMPTS attempts. Check Logs/verify/."
            exit 0
        fi

        echo "$ATTEMPTS" > "$ATTEMPTS_FILE"
        {
            echo "$VERIFY failed (attempt $ATTEMPTS of $MAX_ATTEMPTS). Fix this before finishing:"
            echo "$OUTPUT"
        } >&2
        exit 2
        ;;
    *)
        notify "$VERIFY couldn't check this change: $(echo "$OUTPUT" | head -1 | tr -d '"')"
        exit 0
        ;;
esac
