#!/usr/bin/env bash
# Tests templates/scripts/install.sh on a throwaway project: the rules alone install no enforcement; --enforcement
# adds it in advisory mode; --enforce sets the mode that blocks. Usage: bash tools/test-install.sh
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
FAILURES=0

fresh() {  # fresh <name>: a project with Assets, ProjectSettings and this rules repo's working tree as .ai
    local project="$TMP/$1"
    mkdir -p "$project/Assets" "$project/ProjectSettings" "$project/Packages"
    echo '{ "dependencies": {} }' > "$project/Packages/manifest.json"
    rsync -a --exclude .git "$REPO/" "$project/.ai/"
    (cd "$project/.ai" && git init -q && git add -A >/dev/null 2>&1 && git -c user.email=t@t -c user.name=t commit -qm base)
    echo "$project"
}
check() { local label="$1"; shift; if "$@"; then echo "ok    $label"; else echo "FAIL  $label"; FAILURES=$((FAILURES + 1)); fi; }

# 1. Rules only: the instruction files, but no hooks, verify or checker, and no settings.json.
P="$(fresh rules)"
(cd "$P" && bash .ai/templates/scripts/install.sh --no-verify --no-mcp --no-analyzers >/dev/null 2>&1)
check "rules only creates AGENTS.md" [ -f "$P/AGENTS.md" ]
check "rules only creates no hooks" [ ! -e "$P/.claude/hooks/verify-on-stop.sh" ]
check "rules only creates no verify script" [ ! -e "$P/scripts/verify.sh" ]
check "rules only creates no checker" [ ! -e "$P/scripts/check-feature.sh" ]
check "rules only creates no settings.json" [ ! -e "$P/.claude/settings.json" ]
check "rules only writes no enforcement mode" [ ! -e "$P/.claude/enforcement.mode" ]

# 2. Enforcement in advisory mode (the default when asked for).
P="$(fresh advisory)"
(cd "$P" && bash .ai/templates/scripts/install.sh --enforcement --no-verify --no-mcp --no-analyzers >/dev/null 2>&1)
check "enforcement installs the verify-on-stop hook" [ -f "$P/.claude/hooks/verify-on-stop.sh" ]
check "enforcement installs the checker" [ -f "$P/scripts/check-feature.sh" ]
check "enforcement writes settings.json" [ -f "$P/.claude/settings.json" ]
check "enforcement mode is advisory" grep -qx advisory "$P/.claude/enforcement.mode"

# 3. Enforce: the mode that blocks.
P="$(fresh enforce)"
(cd "$P" && bash .ai/templates/scripts/install.sh --enforce --no-verify --no-mcp --no-analyzers >/dev/null 2>&1)
check "--enforce sets the enforce mode" grep -qx enforce "$P/.claude/enforcement.mode"

# 4. An existing mode file is kept.
printf 'advisory\n' > "$P/.claude/enforcement.mode"
(cd "$P" && bash .ai/templates/scripts/install.sh --enforce --no-verify --no-mcp --no-analyzers >/dev/null 2>&1)
check "an existing enforcement mode is kept" grep -qx advisory "$P/.claude/enforcement.mode"

# 5. Without a terminal nothing is asked: an existing static file (.editorconfig) is skipped, and an instruction file
#    takes the rules as a block (add, the default).
P="$(fresh collisions)"
printf 'root = true\n[*]\nindent_size = 2\n' > "$P/.editorconfig"
mkdir -p "$P/.github"; printf 'Our Copilot rules.\n' > "$P/.github/copilot-instructions.md"
(cd "$P" && bash .ai/templates/scripts/install.sh --no-verify --no-mcp --no-analyzers >/dev/null 2>&1)
check "a differing .editorconfig is skipped without a terminal" grep -q "indent_size = 2" "$P/.editorconfig"
check "no .bak is written for a skipped file" [ ! -e "$P/.editorconfig.bak" ]
check "an instruction file keeps its text and gets the block" grep -q "Our Copilot rules." "$P/.github/copilot-instructions.md"

# 6. --replace-instructions writes the instruction files and backs up the previous text.
P="$(fresh replace)"
mkdir -p "$P/.github"; printf 'Our Copilot rules.\n' > "$P/.github/copilot-instructions.md"
(cd "$P" && bash .ai/templates/scripts/install.sh --replace-instructions --no-verify --no-mcp --no-analyzers >/dev/null 2>&1)
check "--replace-instructions keeps the previous file as .bak" grep -q "Our Copilot rules." "$P/.github/copilot-instructions.md.bak"

# 7. An existing settings.json that differs is kept without a terminal (and the note says what to merge by hand).
P="$(fresh settings)"; mkdir -p "$P/.claude"; printf '{ "permissions": { "allow": ["Bash(make)"] } }\n' > "$P/.claude/settings.json"
(cd "$P" && bash .ai/templates/scripts/install.sh --enforcement --no-verify --no-mcp --no-analyzers >/dev/null 2>&1)
check "a differing settings.json is kept without a terminal" grep -q 'Bash(make)' "$P/.claude/settings.json"
check "no settings.json.bak when it is skipped" [ ! -e "$P/.claude/settings.json.bak" ]

echo
[ "$FAILURES" -eq 0 ] && echo "All passed." || echo "$FAILURES failed."
exit $(( FAILURES > 0 ))
