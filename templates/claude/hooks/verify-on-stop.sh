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

HOOK_INPUT="$(cat)"
cd "$ROOT" || exit 0
mkdir -p "$STATE"

# Each session keeps its own task state, so two sessions in one project never check each other's work. The timing hook
# marks the start of a turn (Logs/verify/turn-<session>, a timestamp); the mark goes when this hook lets the turn end.
# The test scope and the plan an agent writes during its turn are copied to Logs/verify/session-<session>/, and the
# first plan of a turn is kept as the approved one: a plan rewritten later in the same turn, after a rejection, is
# compared with it (PLAN-02), so an agent can't pass a check by dropping what the check asked for.
SESSION_ID="$(printf '%s' "$HOOK_INPUT" | sed -n 's/.*"session_id" *: *"\([A-Za-z0-9_-]*\)".*/\1/p' | head -1)"
TURN_MARKER="$STATE/turn-${SESSION_ID:-unknown}"
SESSION_DIR="$STATE/session-${SESSION_ID:-unknown}"
mkdir -p "$SESSION_DIR"
trap 'code=$?; [ "$code" -eq 0 ] && rm -f "$TURN_MARKER"' EXIT
written_this_turn() {
    [ -f "$1" ] && [ -f "$TURN_MARKER" ] && [ "$1" -nt "$TURN_MARKER" ]
}
if written_this_turn "$STATE/test-scope"; then
    cp "$STATE/test-scope" "$SESSION_DIR/test-scope"
fi
if written_this_turn "Logs/ai/plan.md"; then
    cp "Logs/ai/plan.md" "$SESSION_DIR/plan.md"
    if [ "$(cat "$SESSION_DIR/plan.approved.turn" 2>/dev/null)" != "$(cat "$TURN_MARKER")" ]; then
        cp "Logs/ai/plan.md" "$SESSION_DIR/plan.approved.md"
        cat "$TURN_MARKER" > "$SESSION_DIR/plan.approved.turn"
    fi
fi
SCOPE_FILE="$SESSION_DIR/test-scope"
ATTEMPTS_FILE="$SESSION_DIR/attempts"

# What the user chose to deliver (TASK-01), read from the session's transcript: only what the user typed and the
# answers to the agent's questions (never tool output, which can quote the rules). The last scope answer or scope named
# in a prompt wins, in English or Spanish. Unknown when neither says.
task_scope() {
    local transcript
    transcript="$(printf '%s' "$HOOK_INPUT" | sed -n 's/.*"transcript_path" *: *"\([^"]*\)".*/\1/p' | head -1)"
    [ -f "$transcript" ] && command -v jq > /dev/null 2>&1 || { echo unknown; return; }
    jq -rs '
        [ .[] | select(.type == "user" and .isMeta != true)
          | ( (.message.content | if type == "string" then . else (.[]? | select(.type == "text") | .text) end),
              (.toolUseResult | objects | .answers // {} | to_entries[] | .value | tostring) ) ]
        | join(" ") | ascii_downcase | gsub("ó"; "o") as $text
        | [ { scope: "code+prefabs+tests", at: ([$text | rindex("code, prefabs and tests"), rindex("codigo, prefabs y tests")] | map(. // -1) | max) },
            { scope: "code+tests", at: ([$text | rindex("code and tests"), rindex("codigo y tests")] | map(. // -1) | max) },
            { scope: "code+prefabs", at: ([$text | rindex("code and prefabs"), rindex("codigo y prefabs")] | map(. // -1) | max) },
            { scope: "code", at: ([$text | rindex("code only"), rindex("solo codigo")] | map(. // -1) | max) } ]
        | map(select(.at >= 0)) | if length == 0 then "unknown" else (max_by(.at) | .scope) end
    ' "$transcript" 2>/dev/null || echo unknown
}

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

# The features to check: the folders the user named for the task (Logs/verify/test-scope, TEST-13), the same ones
# whose tests run. With the whole project in scope, only the features this turn changed: files under Assets/Client
# written after the turn began (the timing hook marks it in Logs/verify/turn-<session>, and the mark goes when the
# hook lets the turn end), or without a mark, every feature with pending changes. Another task's unfinished feature
# never blocks this one.
turn_features() {
    if [ -f "$SCOPE_FILE" ]; then
        grep -v '^[[:space:]]*$' "$SCOPE_FILE" | tr -d '\r'
    elif [ -f "$TURN_MARKER" ]; then
        find "$CLIENT" -mindepth 2 -type f ! -name '*.meta' -newer "$TURN_MARKER" 2>/dev/null
    else
        changed_paths
    fi | while IFS= read -r path; do feature_of "$path"; done | grep -vxF "$ALL" | grep -v '^$' | sort -u
}

# A failed check counts as one attempt; after MAX_ATTEMPTS in a row the hook stops asking and says so.
fail_attempt() {
    local label="$1" output="$2" attempts
    attempts=$(( $(cat "$ATTEMPTS_FILE" 2>/dev/null || echo 0) + 1 ))
    if [ "$attempts" -ge "$MAX_ATTEMPTS" ]; then
        rm -f "$ATTEMPTS_FILE"
        notify "$label still fails after $MAX_ATTEMPTS attempts. Check Logs/verify/."
        exit 0
    fi
    echo "$attempts" > "$ATTEMPTS_FILE"
    {
        echo "$label failed (attempt $attempts of $MAX_ATTEMPTS). Fix this before finishing:"
        echo "$output"
    } >&2
    exit 2
}

# The feature rules a tool can check (scripts/check-feature.sh: names, namespaces, plan, installer, specs, tests,
# handoff), for every feature the change touched or the task is scoped to, before compiling. It needs no Unity and
# gives the same result whatever agent or model wrote the code.
if [ -x scripts/check-feature.sh ]; then
    CHECKED_FEATURES="$(turn_features | tr '\n' ' ')"
    if [ -n "${CHECKED_FEATURES// /}" ] && ! CHECK_OUTPUT="$(CHECK_PLAN="$SESSION_DIR/plan.md" CHECK_APPROVED_PLAN="$SESSION_DIR/plan.approved.md" \
        CHECK_TASK_SCOPE="$(task_scope)" scripts/check-feature.sh $CHECKED_FEATURES 2>&1)"; then
        fail_attempt "scripts/check-feature.sh" "$(printf '%s\n' "$CHECK_OUTPUT" | grep -v '^warning ')"
    fi
fi

# OPT-07: with task packs, the final report of a feature task ends with "Outside packs:" and what was read outside them.
if [ -d Logs/ai/packs ] && [ -n "${CHECKED_FEATURES// /}" ] && command -v jq > /dev/null 2>&1; then
    TRANSCRIPT_PATH="$(printf '%s' "$HOOK_INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)"
    if [ -f "$TRANSCRIPT_PATH" ]; then
        LAST_REPORT="$(jq -rs '[ .[] | select(.type == "assistant") | .message.content[]? | select(.type == "text") | .text ] | last // ""' "$TRANSCRIPT_PATH" 2>/dev/null)"
        if [ -n "$LAST_REPORT" ] && ! grep -q 'Outside packs:' <<< "$LAST_REPORT"; then
            fail_attempt "The final report" "It has no \"Outside packs:\" line (OPT-07). End the report with Outside packs: and every rule, package or source file you opened that no pack included, or none."
        fi
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
VERIFY_STARTED="$(date +%s)"
OUTPUT="$("$VERIFY" 2>&1)"
CODE=$?
VERIFY_DURATION_MS=$(( ($(date +%s) - VERIFY_STARTED) * 1000 ))
if [ -x "$ROOT/.claude/hooks/log-timing.sh" ]; then
    TIMING_EVENT=Verification \
    TIMING_TOOL_NAME="$VERIFY" \
    TIMING_DURATION_MS="$VERIFY_DURATION_MS" \
        "$ROOT/.claude/hooks/log-timing.sh" <<<"$HOOK_INPUT" ||
        echo "Could not log verification timing." >&2
fi

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
        fail_attempt "$VERIFY" "$OUTPUT"
        ;;
    *)
        notify "$VERIFY couldn't check this change: $(echo "$OUTPUT" | head -1 | tr -d '"')"
        exit 0
        ;;
esac
