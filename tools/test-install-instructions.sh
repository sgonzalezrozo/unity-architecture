#!/usr/bin/env bash
# Tests templates/scripts/instructions.sh: an existing instruction file keeps the user's text and gets the rules in a
# block that a later install replaces in place; replace backs the file up; a missing file is created.
# Usage: bash tools/test-install-instructions.sh
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
FAILURES=0
TEMPLATE="$TMP/template.md"
printf '%s\n' "# Rules" "" "Read the shared rules." > "$TEMPLATE"

run() {  # run <root> <mode>: one install of the instruction file AGENTS.md
    (
        ROOT="$1"; INSTRUCTIONS_MODE="$2"; created=(); kept=(); added=(); replaced=()
        . "$REPO/templates/scripts/instructions.sh"
        instructions "AGENTS.md" "$TEMPLATE"
    )
}
check() {  # check <label> <condition...>
    local label="$1"; shift
    if "$@"; then echo "ok    $label"; else echo "FAIL  $label"; FAILURES=$((FAILURES + 1)); fi
}
count() { grep -c "ai-agent-rules:begin" "$1"; }

# 1. A project's own AGENTS.md keeps its text and gets the rules in a block, once.
P="$TMP/own"; mkdir -p "$P"
printf '%s\n' "# Our rules" "" "Never commit secrets." > "$P/AGENTS.md"
run "$P" add; run "$P" add
check "the user's text is kept" grep -q "Never commit secrets." "$P/AGENTS.md"
check "the rules are added once after two installs" [ "$(count "$P/AGENTS.md")" -eq 1 ]
check "the rules are in the block" grep -q "Read the shared rules." "$P/AGENTS.md"

# 2. The user's text written after the block survives a later install, which updates only the block.
printf '%s\n' "" "## Our section" "Use Haiku for drafts." >> "$P/AGENTS.md"
sed -i.bak 's/Read the shared rules./Read the shared rules, version 2./' "$TEMPLATE"
run "$P" add
check "text after the block survives an update" grep -q "Use Haiku for drafts." "$P/AGENTS.md"
check "the block is updated in place" grep -q "version 2" "$P/AGENTS.md"
check "still one block after an update" [ "$(count "$P/AGENTS.md")" -eq 1 ]

# 3. A missing file is created from the template.
M="$TMP/missing"; mkdir -p "$M"
run "$M" add
check "a missing file is created" cmp -s "$TEMPLATE" "$M/AGENTS.md"

# 4. Replace writes the template and keeps the old text in a .bak.
R="$TMP/replace"; mkdir -p "$R"
printf '%s\n' "old text" > "$R/AGENTS.md"
run "$R" replace
check "replace writes the template" cmp -s "$TEMPLATE" "$R/AGENTS.md"
check "replace keeps the previous file as .bak" grep -q "old text" "$R/AGENTS.md.bak"

echo
[ "$FAILURES" -eq 0 ] && echo "All passed." || echo "$FAILURES failed."
exit $(( FAILURES > 0 ))
