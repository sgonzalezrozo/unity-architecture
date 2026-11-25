#!/usr/bin/env bash
# Tests templates/scripts/install.sh on a throwaway project: the rules install only .editorconfig and the Rules Guide
# package, and nothing that makes an AI read them (no AGENTS.md, CLAUDE.md, hooks, settings or scripts).
# Usage: bash tools/test-install.sh
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
FAILURES=0

fresh() {  # fresh <name>: a Unity project with this rules repo's working tree as .ai
    local project="$TMP/$1"
    mkdir -p "$project/Assets" "$project/ProjectSettings" "$project/Packages"
    printf '{\n  "dependencies": {\n    "com.unity.ugui": "2.0.0"\n  }\n}\n' > "$project/Packages/manifest.json"
    rsync -a --exclude .git "$REPO/" "$project/.ai/"
    (cd "$project/.ai" && git init -q && git add -A >/dev/null 2>&1 && git -c user.email=t@t -c user.name=t commit -qm base)
    echo "$project"
}
check() { local label="$1"; shift; if "$@"; then echo "ok    $label"; else echo "FAIL  $label"; FAILURES=$((FAILURES + 1)); fi; }
count() { grep -c "$1" "$2"; }

P="$(fresh rules)"
(cd "$P" && bash .ai/templates/scripts/install.sh >/dev/null 2>&1)
check "the rules create .editorconfig" [ -f "$P/.editorconfig" ]
check "the rules add the Rules Guide package" grep -q '"com.sgonzalezrozo.unity-architecture": "file:../.ai/unity"' "$P/Packages/manifest.json"
check "the manifest is still valid JSON" python3 -c "import json,sys; json.load(open('$P/Packages/manifest.json'))"
check "the rules create no AGENTS.md" [ ! -e "$P/AGENTS.md" ]
check "the rules create no CLAUDE.md" [ ! -e "$P/CLAUDE.md" ]
check "the rules create no PROJECT_RULES.md" [ ! -e "$P/PROJECT_RULES.md" ]
check "the rules create no .claude folder" [ ! -e "$P/.claude" ]
check "the rules create no scripts" [ ! -e "$P/scripts" ]
check "the rules create no Copilot, Cursor or Rider files" [ ! -e "$P/.github" ] && [ ! -e "$P/.cursor" ] && [ ! -e "$P/.aiassistant" ]

(cd "$P" && bash .ai/templates/scripts/install.sh >/dev/null 2>&1)
check "a second install adds the package once" [ "$(count 'com.sgonzalezrozo.unity-architecture"' "$P/Packages/manifest.json")" -eq 1 ]

P="$(fresh editorconfig)"
printf 'root = true\n[*]\nindent_size = 2\n' > "$P/.editorconfig"
(cd "$P" && bash .ai/templates/scripts/install.sh >/dev/null 2>&1)
check "a differing .editorconfig is skipped without a terminal" grep -q "indent_size = 2" "$P/.editorconfig"
check "no .bak for a skipped file" [ ! -e "$P/.editorconfig.bak" ]

P="$(fresh oldflags)"
out="$(cd "$P" && bash .ai/templates/scripts/install.sh --enforcement --no-verify 2>&1)"; code=$?
check "the old enforcement flags don't fail" [ "$code" -eq 0 ]
check "the old flags point to the enforcement package" grep -q "enforcement package" <<< "$out"
check "the old flags install no enforcement" [ ! -e "$P/.claude" ]

echo
[ "$FAILURES" -eq 0 ] && echo "All passed." || echo "$FAILURES failed."
exit $(( FAILURES > 0 ))
