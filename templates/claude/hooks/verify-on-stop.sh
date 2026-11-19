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
# Compiling is quick and runs on every stop. The tests are slow, so they run at most every
# VERIFY_TESTS_EVERY_SECONDS (2 hours by default), and only for changes that haven't passed them yet.
TESTS_EVERY="${VERIFY_TESTS_EVERY_SECONDS:-7200}"
LAST_TESTS_FILE="$STATE/last-tests"
TESTS_PENDING_FILE="$STATE/tests-pending"
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

fingerprint() {
    {
        git status --porcelain -- "${PATHSPEC[@]}"
        git diff HEAD -- "${PATHSPEC[@]}"
        git ls-files --others --exclude-standard -z -- "${PATHSPEC[@]}" | xargs -0 git hash-object --
    } 2>/dev/null | git hash-object --stdin
}

# Unix time of the last full test run that passed, one this hook asked for. A run in the Editor doesn't count: it may
# be filtered (the related tests, or the prefab validator), and it would keep pushing the full run back.
last_tests_time() {
    cat "$LAST_TESTS_FILE" 2>/dev/null || echo 0
}

seconds_until_tests() {
    echo $(( $(last_tests_time) + TESTS_EVERY - $(date +%s) ))
}

# Nothing to check: no pending changes, or the same files already passed.
if [ -z "$(git status --porcelain -- "${PATHSPEC[@]}" 2>/dev/null)" ]; then
    exit 0
fi

CURRENT="$(fingerprint)"
UNTIL_TESTS="$(seconds_until_tests)"
if [ "$UNTIL_TESTS" -le 0 ]; then
    MODE=tests
else
    MODE=compile
fi

# These files already passed. Check them again only for the tests they still owe, once those are due.
if [ "$CURRENT" = "$(cat "$PASSED_FILE" 2>/dev/null)" ]; then
    if [ "$MODE" = compile ] || [ ! -f "$TESTS_PENDING_FILE" ]; then
        exit 0
    fi
fi

if editor_open && [ -x scripts/verify-editor.sh ]; then
    VERIFY="scripts/verify-editor.sh"
else
    VERIFY="scripts/verify.sh"
fi

# A changed prefab under Assets/Client gets the prefab validator (TEST-12) on every stop, even between test runs.
# With the Editor open, verify-editor.sh asks the agent to run it; with it closed, verify.sh runs only that test.
PREFAB_TEST="UnityArchitecture.Prefabs.Tests.ClientPrefabsTests.ClientPrefabsFollowThePrefabRules"
prefab_changed() {
    git status --porcelain --untracked-files=all -- Assets/Client 2>/dev/null | grep -Eq '\.prefab"?$' \
        && grep -qs '"com.sgonzalezrozo.unity-architecture"' Packages/manifest.json
}

if [ "$MODE" = compile ]; then
    if [ "$VERIFY" = "scripts/verify.sh" ] && prefab_changed; then
        export VERIFY_TEST_FILTER="$PREFAB_TEST" VERIFY_EDITMODE_ONLY=1
    else
        export VERIFY_COMPILE_ONLY=1
    fi
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
            notify "$(echo "$OUTPUT" | tail -1) The tests run when they're due, in $(( (UNTIL_TESTS + 59) / 60 )) min."
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
