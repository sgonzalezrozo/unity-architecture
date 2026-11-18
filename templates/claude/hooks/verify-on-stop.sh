#!/usr/bin/env bash
# Stop hook: an agent can't finish with a broken build.
# When Unity files changed, it checks the project and sends failures back to the agent:
# with the Editor closed it runs scripts/verify.sh (batch mode); with the Editor open, scripts/verify-editor.sh,
# which reads the compile and test results the Editor writes (the agent compiles and tests through a Unity MCP).
set -u

MAX_ATTEMPTS=3

ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
STATE="$ROOT/Logs/verify"
PASSED_FILE="$STATE/last-passed"
ATTEMPTS_FILE="$STATE/attempts"
PATHS="Assets Packages ProjectSettings"

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
        git status --porcelain -- $PATHS
        git diff HEAD -- $PATHS
        git ls-files --others --exclude-standard -z -- $PATHS | xargs -0 git hash-object --
    } 2>/dev/null | git hash-object --stdin
}

# Nothing to check: no pending changes, or the same files already passed.
if [ -z "$(git status --porcelain -- $PATHS 2>/dev/null)" ]; then
    exit 0
fi

CURRENT="$(fingerprint)"
if [ "$CURRENT" = "$(cat "$PASSED_FILE" 2>/dev/null)" ]; then
    exit 0
fi

if editor_open && [ -x scripts/verify-editor.sh ]; then
    VERIFY="scripts/verify-editor.sh"
else
    VERIFY="scripts/verify.sh"
fi

OUTPUT="$("$VERIFY" 2>&1)"
CODE=$?

case "$CODE" in
    0)
        echo "$CURRENT" > "$PASSED_FILE"
        rm -f "$ATTEMPTS_FILE"
        notify "$(echo "$OUTPUT" | tail -1)"
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
