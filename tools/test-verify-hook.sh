#!/usr/bin/env bash
# Tests templates/claude/hooks/verify-on-stop.sh with a stub scripts/verify.sh that records the environment it's given:
# a scope without tests ("solo codigo") runs no Unity unit tests, a scope with tests runs its features' tests, and the
# hook never starts a periodic full suite. Usage: bash tools/test-verify-hook.sh
set -u

REPO="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="${HOOK:-$REPO/templates/claude/hooks/verify-on-stop.sh}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
FAILURES=0

# A git project with a feature (Shop) and its tests, committed, so the changes made afterwards are pending.
make_project() {
    local project="$TMP/$1"
    mkdir -p "$project/scripts" "$project/Logs/verify" "$project/Assets/Client/Shop/ShopMain" "$project/Assets/Client/Shop/Tests"
    printf '#!/usr/bin/env bash\necho "COMPILE=${VERIFY_COMPILE_ONLY:-} FILTER=${VERIFY_TEST_FILTER:-} FEATURES=${VERIFY_TEST_FEATURES:-}" >> Logs/verify/calls.txt\nexit 0\n' > "$project/scripts/verify.sh"
    printf '#!/usr/bin/env bash\nexit 0\n' > "$project/scripts/check-feature.sh"
    chmod +x "$project/scripts/verify.sh" "$project/scripts/check-feature.sh"
    (cd "$project" && git init -q && git config user.email t@t && git config user.name t && git commit -q --allow-empty -m base)
    printf 'namespace Client.Shop { }\n' > "$project/Assets/Client/Shop/ShopMain/ShopModel.cs"
    printf 'namespace Client.Shop.Tests { }\n' > "$project/Assets/Client/Shop/Tests/ShopTests.cs"
    printf '{ "name": "Client.Shop.Tests", "rootNamespace": "Client.Shop.Tests" }\n' > "$project/Assets/Client/Shop/Tests/Client.Shop.Tests.asmdef"
    echo "$project"
}

# Runs the hook for a prompt the user typed, and prints what the stub verify.sh was given.
run_hook() {
    local project="$1" prompt="$2" transcript="$TMP/transcript-$RANDOM.jsonl"
    printf '{"type":"user","message":{"content":"%s"}}\n' "$prompt" > "$transcript"
    rm -f "$project/Logs/verify/calls.txt"
    (cd "$project" && CLAUDE_PROJECT_DIR="$project" bash "$HOOK" <<< "{\"session_id\":\"s1\",\"transcript_path\":\"$transcript\"}" > /dev/null 2>&1)
    cat "$project/Logs/verify/calls.txt" 2>/dev/null || echo "not run"
}

expect() {
    local label="$1" got="$2" want="$3"
    if [ "$got" = "$want" ]; then echo "ok    $label"; else echo "FAIL  $label: got \"$got\", want \"$want\""; FAILURES=$((FAILURES + 1)); fi
}

# "solo codigo": a feature change runs no tests, only the compile.
P="$(make_project solo)"
got="$(run_hook "$P" "solo codigo, cambia ShopModel")"
expect "solo codigo runs no feature tests" "$got" "COMPILE=1 FILTER= FEATURES="

# "code and tests" with the feature named in the test scope (TEST-13): the same change runs the feature's tests.
P="$(make_project tests)"
touch -t 202001010000 "$P/Logs/verify/turn-s1"
printf 'Assets/Client/Shop\n' > "$P/Logs/verify/test-scope"
got="$(run_hook "$P" "code and tests for Shop")"
case "$got" in *"FILTER=^Client\\.Shop\\."*) echo "ok    code and tests runs the feature's tests";; *) echo "FAIL  code and tests: $got"; FAILURES=$((FAILURES + 1));; esac

# A whole-project change with no full run due (no 2-hour or 24-hour mark) compiles only: the periodic suite is gone.
P="$(make_project whole)"
printf '{ "name": "Client", "references": [] }\n' > "$P/Assets/Client/Client.asmdef"
got="$(run_hook "$P" "code and tests")"
expect "a whole-project change compiles only, with no periodic full suite" "$got" "COMPILE=1 FILTER= FEATURES="

# The same whole-project change under "solo codigo" compiles only too.
P="$(make_project whole-solo)"
printf '{ "name": "Client", "references": [] }\n' > "$P/Assets/Client/Client.asmdef"
got="$(run_hook "$P" "solo codigo")"
expect "a whole-project change under solo codigo compiles only" "$got" "COMPILE=1 FILTER= FEATURES="

echo
[ "$FAILURES" -eq 0 ] && echo "All passed." || echo "$FAILURES failed."
exit $(( FAILURES > 0 ))
