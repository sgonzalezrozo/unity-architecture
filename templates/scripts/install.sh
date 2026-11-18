#!/usr/bin/env bash
# Puts the files assistants and tools read from fixed paths at the project root, next to the .ai submodule:
# AGENTS.md, CLAUDE.md, .editorconfig, Copilot, Rider and Cursor rules, scripts/verify.sh and the Claude Code hook.
#
# Usage, from the project root (the folder that holds Assets and .ai):
#   bash .ai/templates/scripts/install.sh            creates the files that are missing, keeps the rest
#   bash .ai/templates/scripts/install.sh --update   also refreshes the copied templates after updating .ai
#
# AGENTS.md, CLAUDE.md and .claude/settings.json are never replaced: they're yours to edit.
set -u

UPDATE=false
for arg in "$@"; do
    case "$arg" in
        --update) UPDATE=true ;;
        -h|--help) sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Unknown option: $arg (use --update or --help)"; exit 2 ;;
    esac
done

AI_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
ROOT="$(cd "$AI_DIR/.." && pwd)"
TEMPLATES="$AI_DIR/templates"

if [ ! -d "$ROOT/Assets" ] || [ ! -d "$ROOT/ProjectSettings" ]; then
    echo "$ROOT doesn't look like a Unity project (no Assets or ProjectSettings folder)."
    echo "The rules must be a folder named .ai next to Assets. From the project root, run:"
    echo "  git submodule add https://github.com/sgonzalezrozo/unity-architecture-agents.git .ai"
    exit 2
fi

created=(); updated=(); kept=()

# copy <destination relative to root> <source file> [executable]
# A copied template: created when missing, refreshed with --update when it differs.
copy() {
    local dest="$ROOT/$1"
    if [ -e "$dest" ]; then
        if [ "$UPDATE" = false ] || cmp -s "$2" "$dest"; then
            kept+=("$1")
            return
        fi
        cp "$2" "$dest"
        updated+=("$1")
    else
        mkdir -p "$(dirname "$dest")"
        cp "$2" "$dest"
        created+=("$1")
    fi
    if [ "${3:-}" = "executable" ]; then chmod +x "$dest"; fi
}

# own <destination relative to root> <content>
# A file the project owns and edits: only created when missing.
own() {
    local dest="$ROOT/$1"
    if [ -e "$dest" ]; then
        kept+=("$1")
        return
    fi
    mkdir -p "$(dirname "$dest")"
    printf '%s\n' "$2" > "$dest"
    created+=("$1")
}

own "AGENTS.md" "# AGENTS.md

All rules live in the \`.ai\` submodule. Read \`.ai/AGENTS.md\` completely, then open only the document it points to.

If \`.ai/\` is empty, run \`git submodule update --init\`.

## Rules for this project only

(None yet.)"

# Claude Code loads both: the shared rules, and the project's own rules in AGENTS.md.
own "CLAUDE.md" "@.ai/AGENTS.md
@AGENTS.md"

copy ".editorconfig" "$TEMPLATES/.editorconfig"
copy ".github/copilot-instructions.md" "$TEMPLATES/copilot-instructions.md"
copy ".aiassistant/rules/project.md" "$TEMPLATES/rider-project-rule.md"
copy ".cursor/rules/unity-architecture.mdc" "$TEMPLATES/cursor-rule.mdc"
copy "scripts/verify.sh" "$TEMPLATES/scripts/verify.sh" executable
copy ".claude/hooks/verify-on-stop.sh" "$TEMPLATES/claude/hooks/verify-on-stop.sh" executable

if [ -e "$ROOT/.claude/settings.json" ]; then
    kept+=(".claude/settings.json")
    if ! grep -q "verify-on-stop.sh" "$ROOT/.claude/settings.json"; then
        SETTINGS_NOTE="Your .claude/settings.json was kept and has no verify hook. Add the Stop hook from .ai/templates/claude/settings.json to it."
    fi
else
    mkdir -p "$ROOT/.claude"
    cp "$TEMPLATES/claude/settings.json" "$ROOT/.claude/settings.json"
    created+=(".claude/settings.json")
fi

echo "Project: $ROOT"
print_list() {
    local title="$1"; shift
    [ $# -eq 0 ] && return
    echo
    echo "$title"
    for f in "$@"; do echo "  $f"; done
}
print_list "Created:" ${created[@]+"${created[@]}"}
print_list "Updated from .ai/templates:" ${updated[@]+"${updated[@]}"}
if [ "$UPDATE" = true ]; then
    print_list "Already up to date, or yours to edit:" ${kept[@]+"${kept[@]}"}
else
    print_list "Already there, kept (--update refreshes the copied templates):" ${kept[@]+"${kept[@]}"}
fi
if [ -n "${SETTINGS_NOTE:-}" ]; then
    echo
    echo "$SETTINGS_NOTE"
fi

echo
echo "Next:"
echo "  1. Commit these files and .ai in your project."
echo "  2. In Rider, open .aiassistant/rules/project.md and set the rule's type to Always."
echo "  3. Write rules that only apply to this project in AGENTS.md."
