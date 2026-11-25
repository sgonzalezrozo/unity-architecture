#!/usr/bin/env bash
# Checks the project while the Unity Editor is open, from the reports the Editor writes to Logs/verify/
# (the reporters in the .ai/unity package, which .ai/templates/scripts/install.sh adds). verify.sh can't run then,
# because batch mode can't open a project the Editor has open.
# The agent compiles and runs tests through a Unity MCP server (refresh_unity, run_tests); this script only reads
# the results. Exit codes: 0 passed, 1 failed or out of date, 2 couldn't check.
# Set VERIFY_COMPILE_ONLY=1 to check only the compile, as the Stop hook does between test runs.
# Set VERIFY_TEST_FEATURES to check the tests of some features instead of the full suite, as the Stop hook does while
# a task is scoped to them: feature folder names under Assets/Client, separated by spaces ("Inventory Store").
# A Unity MCP is optional. Without one (no MCP for Unity or Unity CLI package in the manifest, or
# VERIFY_EDITOR_BRIDGE=0), the agent can't compile or test in the Editor, so a result that's out of date is
# "couldn't check" (2) instead of a failure the agent can't fix. Errors the Editor already reported still fail.
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/Logs/verify"
COMPILE="$OUT/editor-compile.json"
TESTS="$OUT/editor-tests.json"
CLIENT="Assets/Client"
# The prefab validator (TEST-12) has one case per feature folder under Assets/Client, named after it, and the Editor
# writes each case's result to editor-prefabs-{Feature}.json. Each feature's tests go to editor-tests-{Feature}.json.
PREFAB_CASE_PREFIX="UnityArchitecture.Prefabs.Tests.ClientPrefabsTests."
GENERATION_STATUS="$ROOT/Assets/FastIoC/Generated/GenerationStatus.json"

# True when the agent can drive the open Editor: MCP for Unity, or the Unity CLI's package. VERIFY_EDITOR_BRIDGE=1 or 0
# overrides it, for another Unity MCP server.
has_bridge() {
    case "${VERIFY_EDITOR_BRIDGE:-}" in
        1) return 0 ;;
        0) return 1 ;;
    esac
    grep -Eqs '"(com\.coplaydev\.unity-mcp|com\.unity\.pipeline)"' "$ROOT/Packages/manifest.json"
}

NO_BRIDGE_HINT="Without a Unity MCP the agent can't do it for you. Or close the project in Unity, and the hook verifies in batch mode."

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

# The newest change to a file that makes Unity compile, optionally only under one folder of the project.
newest_script_change() {
    local newest=0 path time under="${1:+$ROOT/$1/}"
    while IFS= read -r path; do
        case "$path" in "$under"*) ;; *) continue ;; esac
        [ -f "$path" ] || continue
        time="$(modified_time "$path")"
        [ "$time" -gt "$newest" ] && newest="$time"
    done < <(changed_script_files | grep -v '~/' | grep -E '\.(cs|asmdef|asmref|rsp)$|/Packages/manifest\.json$')
    echo "$newest"
}

# Each changed prefab under Assets/Client that still exists, as "<feature> <modified time>": the feature is its first
# folder there, or Root for a prefab directly in Assets/Client, like the validator's cases.
changed_prefabs() {
    local path relative feature
    (cd "$ROOT" && git status --porcelain --untracked-files=all -- "$CLIENT" 2>/dev/null \
        | sed 's/^...//; s/^.* -> //; s/^"//; s/"$//' | grep '\.prefab$') | while IFS= read -r path; do
        [ -f "$ROOT/$path" ] || continue
        relative="${path#"$CLIENT"/}"
        case "$relative" in
            */*) feature="${relative%%/*}" ;;
            *) feature="Root" ;;
        esac
        echo "$feature $(modified_time "$ROOT/$path")"
    done
}

if [ ! -f "$COMPILE" ]; then
    echo "The Editor is open, but it hasn't written Logs/verify/editor-compile.json yet."
    echo "Run bash .ai/templates/scripts/install.sh so the .ai/unity package is in Packages/manifest.json, let Unity compile once, then try again."
    exit 2
fi

if grep -Eq '"compiling": *true' "$COMPILE"; then
    if ! has_bridge; then
        echo "Unity is compiling; check again when it finishes. $NO_BRIDGE_HINT"
        exit 2
    fi
    echo "Unity is compiling. Wait until it finishes (read_console through the Unity MCP), then check again."
    exit 1
fi

COMPILED_AT="$(json_number finishedAtUnixSeconds "$COMPILE")"
COMPILED_AT="${COMPILED_AT:-0}"
NEWEST_CHANGE="$(newest_script_change)"
if [ "$NEWEST_CHANGE" -gt "$COMPILED_AT" ]; then
    if ! has_bridge; then
        echo "Unity hasn't compiled the latest script changes: switch to the Editor so it compiles. $NO_BRIDGE_HINT"
        exit 2
    fi
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

# A data asset spec without its asset (EDIT-14): the Editor builds it through the bridge, or a person from the menu.
MISSING_SPECS="$(find "$ROOT/Assets/Client" -name '*.asset.json' 2>/dev/null | while IFS= read -r spec; do
    [ -e "${spec%.json}" ] || echo "${spec#"$ROOT"/}"
done)"
if [ -n "$MISSING_SPECS" ]; then
    if ! has_bridge; then
        echo "These data asset specs have no asset yet: select each one and run Assets > Unity Architecture > Build Asset From Spec. $NO_BRIDGE_HINT"
        echo "$MISSING_SPECS"
        exit 2
    fi
    echo "These data asset specs have no asset yet (EDIT-14):"
    echo "$MISSING_SPECS"
    echo "Build them through the Unity MCP's code tool: return UnityArchitecture.Prefabs.AssetSpecs.BuildMissing(\"Assets/Client\"), check every result is empty, then check again."
    exit 1
fi

# A changed prefab is checked on every stop, even between test runs: its feature's validator case is one quick test.
if grep -qs '"com.sgonzalezrozo.unity-architecture"' "$ROOT/Packages/manifest.json"; then
    DUE_PREFABS=""
    PREFAB_ERRORS=""
    for feature in $(changed_prefabs | awk '{ print $1 }' | sort -u); do
        changed_at="$(changed_prefabs | awk -v f="$feature" '$1 == f && $2 > newest { newest = $2 } END { print newest + 0 }')"
        report="$OUT/editor-prefabs-$feature.json"
        validated_at="$(json_number startedAtUnixSeconds "$report" 2>/dev/null)"
        if [ ! -f "$report" ] || [ "${validated_at:-0}" -lt "$changed_at" ]; then
            DUE_PREFABS="$DUE_PREFABS $feature"
        elif grep -Eq '"passed": *false' "$report"; then
            PREFAB_ERRORS="$PREFAB_ERRORS$(json_list errors "$report")
"
        fi
    done

    if [ -n "$DUE_PREFABS" ]; then
        names=""
        for feature in $DUE_PREFABS; do names="$names, \"$PREFAB_CASE_PREFIX$feature\""; done
        if ! has_bridge; then
            echo "Prefabs of$DUE_PREFABS changed after the prefab validator last checked them: run their ClientPrefabsTests cases in the Test Runner. $NO_BRIDGE_HINT"
            exit 2
        fi
        echo "Prefabs of$DUE_PREFABS changed after the prefab validator last checked them."
        echo "Run their cases with run_tests through the Unity MCP (EditMode, test_names: [${names#, }]), poll get_test_job until it finishes, then check again."
        exit 1
    fi

    if [ -n "$PREFAB_ERRORS" ]; then
        echo "The prefab validator found errors. Fix the prefabs through the recipes or a spec, never as text (EDIT-06):"
        printf '%s' "$PREFAB_ERRORS"
        exit 1
    fi
fi

COMPILE_ONLY="${VERIFY_COMPILE_ONLY:-0}"
TEST_FEATURES="${VERIFY_TEST_FEATURES:-}"
if [ "$COMPILE_ONLY" != "1" ] && [ -n "$TEST_FEATURES" ]; then
    # Each feature's tests, all of them in one run that started after the feature's last script change.
    DUE_FEATURES=""
    TOTAL=0
    for feature in $TEST_FEATURES; do
        report="$OUT/editor-tests-$feature.json"
        tested_at="$(json_number startedAtUnixSeconds "$report" 2>/dev/null)"
        if [ ! -f "$report" ] || [ "${tested_at:-0}" -lt "$(newest_script_change "$CLIENT/$feature")" ] \
            || ! grep -Eq '"complete": *true' "$report"; then
            DUE_FEATURES="$DUE_FEATURES $feature"
            continue
        fi
        failed="$(json_number failed "$report")"
        if [ "${failed:-0}" != "0" ]; then
            echo "Tests of $feature failed: $failed of $(json_number total "$report"):"
            json_list failures "$report"
            exit 1
        fi
        TOTAL=$(( TOTAL + $(json_number total "$report") ))
    done

    if [ -n "$DUE_FEATURES" ]; then
        groups=""
        for feature in $DUE_FEATURES; do groups="$groups, \"^Client\\\\.$feature\\\\.\""; done
        if ! has_bridge; then
            echo "The tests of$DUE_FEATURES are due: run them in Window > General > Test Runner. $NO_BRIDGE_HINT"
            exit 2
        fi
        echo "The tests of$DUE_FEATURES are due, and they haven't all run since the feature's last script change."
        echo "Run them with run_tests through the Unity MCP (EditMode, group_names: [${groups#, }]), poll get_test_job until it finishes, then check again."
        exit 1
    fi
    FEATURES_TESTED=true
elif [ "$COMPILE_ONLY" != "1" ] && grep -qs '"com.unity.test-framework"' "$ROOT/Packages/manifest.json" "$ROOT/Packages/packages-lock.json"; then
    # Compared with the newest script change, not the last compile: Unity also compiles after a test run, with no
    # script changed. A run that started after the change tested the code as it is.
    TESTED_AT="$(json_number startedAtUnixSeconds "$TESTS" 2>/dev/null)"
    [ -n "$TESTED_AT" ] || TESTED_AT="$(json_number finishedAtUnixSeconds "$TESTS" 2>/dev/null)"
    # Only a full run counts: the related tests or the prefab validator alone (a filtered run) aren't the suite.
    if [ ! -f "$TESTS" ] || [ "${TESTED_AT:-0}" -lt "$NEWEST_CHANGE" ] || ! grep -Eq '"fullRun": *true' "$TESTS"; then
        if ! has_bridge; then
            echo "The full EditMode suite is due: run it in Window > General > Test Runner. $NO_BRIDGE_HINT"
            exit 2
        fi
        if [ -f "$TESTS" ] && grep -Eq '"fullRun": *true' "$TESTS"; then
            echo "The full EditMode suite is due: the last full run started at $(date -r "${TESTED_AT:-0}" '+%H:%M:%S' 2>/dev/null || echo "$TESTED_AT"), and a script changed after it, at $(date -r "$NEWEST_CHANGE" '+%H:%M:%S' 2>/dev/null || echo "$NEWEST_CHANGE"). A run only counts when it starts after the last change."
        else
            echo "The full EditMode suite is due, and it hasn't run since the last script change."
        fi
        echo "Run every EditMode test with run_tests through the Unity MCP (EditMode, no filter), poll get_test_job until it finishes, then check again."
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

if [ "$COMPILE_ONLY" = "1" ]; then
    echo "Verify passed in the open Editor: compiled."
elif [ "${FEATURES_TESTED:-false}" = true ]; then
    echo "Verify passed in the open Editor: compiled, ${TOTAL} tests of $TEST_FEATURES."
elif [ -n "${TOTAL:-}" ]; then
    echo "Verify passed in the open Editor: compiled, ${TOTAL} tests."
else
    echo "Verify passed in the open Editor: compiled. No tests ran: the Test Framework package isn't installed."
fi
exit 0
