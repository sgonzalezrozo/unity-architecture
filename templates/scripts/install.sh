#!/usr/bin/env bash
# Installs the rules in a Unity project. The rules are documents: they describe the architecture, and nothing reads
# them by default. This puts in the project only:
#   - .editorconfig, the code style the rules use;
#   - the Rules Guide package (com.sgonzalezrozo.unity-architecture, from .ai/unity), to read the rules, examples and
#     good practices in the Editor (Tools > Unity Architecture > Rules Guide).
# What makes an AI read and follow the rules (the instruction files, the hooks and the checks) is a separate, optional
# enforcement package (.ai-enforcement), private for now. Its install runs this one first.
#
# Usage, from the project root (the folder that holds Assets and .ai):
#   bash .ai/templates/scripts/install.sh            creates what's missing, asks about each file that differs
#   bash .ai/templates/scripts/install.sh --update   also refreshes copies nobody changed after updating .ai
# A file that differs is asked about from a terminal ([r] replace with a backup, [s] skip); without one, it's skipped.
set -u

UPDATE=false
OLD_FLAGS=()
for arg in "$@"; do
    case "$arg" in
        --update) UPDATE=true ;;
        # The installer's options from before the enforcement was a separate package.
        --enforcement|--enforce|--verify|--no-verify|--mcp|--no-mcp|--analyzers|--no-analyzers|--add-instructions|--replace-instructions) OLD_FLAGS+=("$arg") ;;
        -h|--help) sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Unknown option: $arg (use --update or --help)"; exit 2 ;;
    esac
done

AI_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
ROOT="$(cd "$AI_DIR/.." && pwd)"
TEMPLATES="$AI_DIR/templates"

if [ ! -d "$ROOT/Assets" ] || [ ! -d "$ROOT/ProjectSettings" ]; then
    echo "$ROOT doesn't look like a Unity project (no Assets or ProjectSettings folder)."
    echo "The rules must be a folder named .ai next to Assets. From the project root, run:"
    echo "  git submodule add https://github.com/sgonzalezrozo/unity-architecture.git .ai"
    exit 2
fi

created=(); updated=(); kept=(); customized=(); replaced=()

# True when <file> has the exact content of an earlier version of <template> in the .ai repository's history,
# so it's an old copy nobody edited. Without that history, nothing counts as unedited.
is_unedited_copy() {
    local file="$1" template="${2#"$AI_DIR"/}" blob revision
    blob="$(git hash-object "$file" 2>/dev/null)" || return 1
    for revision in $(git -C "$AI_DIR" rev-list HEAD -- "$template" 2>/dev/null); do
        [ "$(git -C "$AI_DIR" rev-parse "$revision:$template" 2>/dev/null)" = "$blob" ] && return 0
    done
    return 1
}

# copy <destination relative to root> <source file>: created when missing, refreshed when it's an unedited earlier
# version of the template, and asked about when someone changed it. It's a fixed file, so it can't be merged: [r]
# replaces it (the old one is kept as <file>.bak), [s] skips it. Without a terminal it's skipped.
copy() {
    local dest="$ROOT/$1" answer
    if [ ! -e "$dest" ]; then
        mkdir -p "$(dirname "$dest")"
        cp "$2" "$dest"
        created+=("$1")
    elif cmp -s "$2" "$dest"; then
        kept+=("$1")
    elif is_unedited_copy "$dest" "$2"; then
        cp "$2" "$dest"
        updated+=("$1")
    else
        answer=s
        if [ -t 0 ] && [ -t 1 ]; then
            echo
            echo "$1 already exists and differs from the rules."
            printf '  [r] replace (backup as %s.bak)   [s] skip (default): ' "$1"
            read -r answer
        fi
        case "$answer" in
            r|R) cp "$dest" "$dest.bak"; cp "$2" "$dest"; replaced+=("$1 (previous kept as $1.bak)") ;;
            *) customized+=("$1") ;;
        esac
    fi
}

copy ".editorconfig" "$TEMPLATES/.editorconfig"

# The Rules Guide package, from .ai/unity, so it stays on the same version as the rules.
MANIFEST="$ROOT/Packages/manifest.json"
RULES_PACKAGE="com.sgonzalezrozo.unity-architecture"
if [ -f "$MANIFEST" ] && ! grep -q "\"$RULES_PACKAGE\"" "$MANIFEST"; then
    temporary="$MANIFEST.tmp"
    if awk -v name="$RULES_PACKAGE" '
        { print }
        /"dependencies"[[:space:]]*:[[:space:]]*\{/ && !done { print "    \"" name "\": \"file:../.ai/unity\","; done = 1 }
    ' "$MANIFEST" > "$temporary" && mv "$temporary" "$MANIFEST"; then
        updated+=("Packages/manifest.json (adds $RULES_PACKAGE from .ai/unity: the Rules Guide)")
    else
        rm -f "$temporary"
        MANIFEST_NOTE="Couldn't add $RULES_PACKAGE to Packages/manifest.json. Add \"$RULES_PACKAGE\": \"file:../.ai/unity\" to dependencies."
    fi
fi

echo "Rules for: $ROOT"
print_list() {
    local title="$1"; shift
    [ $# -eq 0 ] && return
    echo
    echo "$title"
    for f in "$@"; do echo "  $f"; done
}
print_list "Created:" ${created[@]+"${created[@]}"}
print_list "Updated from .ai:" ${updated[@]+"${updated[@]}"}
print_list "Replaced (previous versions backed up):" ${replaced[@]+"${replaced[@]}"}
print_list "Changed in this project, kept (compare with .ai/templates and merge what you want by hand):" ${customized[@]+"${customized[@]}"}
print_list "Already there, kept:" ${kept[@]+"${kept[@]}"}
[ -n "${MANIFEST_NOTE:-}" ] && { echo; echo "$MANIFEST_NOTE"; }
if [ ${#OLD_FLAGS[@]} -gt 0 ]; then
    echo
    echo "Ignored: ${OLD_FLAGS[*]}. The AI wiring and the checks are a separate, optional enforcement package now"
    echo "(.ai-enforcement); with it, run bash .ai-enforcement/templates/scripts/install.sh instead."
fi
# Called by the enforcement's install, which prints its own next steps.
if [ ! -d "$ROOT/.ai-enforcement" ]; then
    echo
    echo "The rules are documents: read them in the Editor (Tools > Unity Architecture > Rules Guide) or in .ai/."
    echo "An AI reads and follows them only through the optional enforcement package (.ai/docs/INSTALLATION.md)."
fi
