#!/usr/bin/env bash
# Copies the files assistants and tools read from fixed paths into the project root, next to the .ai submodule:
# AGENTS.md, CLAUDE.md, .editorconfig, Copilot, Rider and Cursor rules, scripts/verify.sh and the Claude Code hook.
# Files that already exist are kept, so it's safe to run again. --force replaces them.
#
# Usage, from the project root:
#   bash .ai/templates/scripts/install.sh
#   bash .ai/templates/scripts/install.sh --force
set -u

FORCE=false
for arg in "$@"; do
    case "$arg" in
        --force) FORCE=true ;;
        -h|--help) sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Unknown option: $arg (use --force or --help)"; exit 2 ;;
    esac
done

AI_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
ROOT="$(cd "$AI_DIR/.." && pwd)"
TEMPLATES="$AI_DIR/templates"

if [ ! -d "$ROOT/Assets" ] || [ ! -d "$ROOT/ProjectSettings" ]; then
    echo "$ROOT doesn't look like a Unity project (no Assets or ProjectSettings folder)."
    echo "Add the rules as .ai/ at the project root first:"
    echo "  git submodule add https://github.com/sgonzalezrozo/unity-architecture-agents.git .ai"
    exit 2
fi

created=(); kept=()

# place <destination relative to root> <source file> [executable]
place() {
    local dest="$ROOT/$1"
    if [ -e "$dest" ] && [ "$FORCE" = false ]; then
        kept+=("$1")
        return
    fi
    mkdir -p "$(dirname "$dest")"
    cp "$2" "$dest"
    [ "${3:-}" = "executable" ] && chmod +x "$dest"
    created+=("$1")
}

# write <destination relative to root> <content>
write() {
    local dest="$ROOT/$1"
    if [ -e "$dest" ] && [ "$FORCE" = false ]; then
        kept+=("$1")
        return
    fi
    mkdir -p "$(dirname "$dest")"
    printf '%s\n' "$2" > "$dest"
    created+=("$1")
}

write "AGENTS.md" "# AGENTS.md

All rules live in the \`.ai\` submodule. Read \`.ai/AGENTS.md\` completely, then open only the document it points to.

If \`.ai/\` is empty, run \`git submodule update --init\`."

write "CLAUDE.md" "@.ai/AGENTS.md"

place ".editorconfig" "$TEMPLATES/.editorconfig"
place ".github/copilot-instructions.md" "$TEMPLATES/copilot-instructions.md"
place ".aiassistant/rules/project.md" "$TEMPLATES/rider-project-rule.md"
place ".cursor/rules/unity-architecture.mdc" "$TEMPLATES/cursor-rule.mdc"
place "scripts/verify.sh" "$TEMPLATES/scripts/verify.sh" executable
place ".claude/hooks/verify-on-stop.sh" "$TEMPLATES/claude/hooks/verify-on-stop.sh" executable
place ".claude/settings.json" "$TEMPLATES/claude/settings.json"

echo "Project: $ROOT"
if [ ${#created[@]} -gt 0 ]; then
    echo
    echo "Created:"
    for f in "${created[@]}"; do echo "  $f"; done
fi
if [ ${#kept[@]} -gt 0 ]; then
    echo
    echo "Already there, kept (--force replaces them):"
    for f in "${kept[@]}"; do echo "  $f"; done
fi

for f in ${kept[@]+"${kept[@]}"}; do
    if [ "$f" = ".claude/settings.json" ]; then
        echo
        echo "Your .claude/settings.json was kept. To get the verify hook, add the Stop hook from"
        echo ".ai/templates/claude/settings.json to it."
    fi
done

echo
echo "Next: in Rider, set the rule's type to Always. Commit these files in your project."
echo "Keep rules that only apply to this project in the root AGENTS.md."
