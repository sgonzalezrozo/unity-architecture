#!/usr/bin/env bash
# Puts the files assistants and tools read from fixed paths at the project root, next to the .ai submodule:
# AGENTS.md, CLAUDE.md, .editorconfig, Copilot, Rider and Cursor rules, scripts/verify.sh, scripts/verify-editor.sh,
# the Claude Code hook, the Unity MCP config (.mcp.json), and the .ai/unity package (prefab validator, Editor reporters).
#
# Usage, from the project root (the folder that holds Assets and .ai):
#   bash .ai/templates/scripts/install.sh            creates the files that are missing, keeps the rest
#   bash .ai/templates/scripts/install.sh --update   also refreshes copies nobody changed after updating .ai
#   add --verify to run scripts/verify.sh at the end without asking, or --no-verify to skip it
#
# It also installs the prebuilt analyzers in Assets/Client/Analyzers, creating Assets/Client/Client.asmdef and
# Client.cs when Assets/Client doesn't exist yet. AGENTS.md, CLAUDE.md, .claude/settings.json and .mcp.json are never replaced.
set -u

UPDATE=false
VERIFY=ask
for arg in "$@"; do
    case "$arg" in
        --update) UPDATE=true ;;
        --verify) VERIFY=yes ;;
        --no-verify) VERIFY=no ;;
        -h|--help) sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Unknown option: $arg (use --update, --verify, --no-verify or --help)"; exit 2 ;;
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

created=(); updated=(); kept=(); customized=()

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

# copy <destination relative to root> <source file> [executable]
# A copied template: created when missing. --update refreshes it when it's an unedited earlier version of the
# template, and keeps it when someone changed it, so project customizations survive updates.
copy() {
    local dest="$ROOT/$1"
    if [ -e "$dest" ]; then
        if [ "$UPDATE" = false ] || cmp -s "$2" "$dest"; then
            kept+=("$1")
            return
        fi
        if ! is_unedited_copy "$dest" "$2"; then
            customized+=("$1")
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
copy "scripts/verify-editor.sh" "$TEMPLATES/scripts/verify-editor.sh" executable
copy ".claude/hooks/verify-on-stop.sh" "$TEMPLATES/claude/hooks/verify-on-stop.sh" executable

# The Editor reporters, which write compile and test results to Logs/verify/ for the hook, used to be copied to
# Assets/Editor/UnityArchitecture. They're in the .ai/unity package now. Remove the old copies nobody edited.
OLD_EDITOR_TOOLS="Assets/Editor/UnityArchitecture"
removed=()
for old in EditorCompileReporter.cs UnityArchitecture.Editor.asmdef Tests/EditorTestReporter.cs Tests/UnityArchitecture.Editor.TestReporter.asmdef; do
    path="$ROOT/$OLD_EDITOR_TOOLS/$old"
    [ -e "$path" ] || continue
    if is_unedited_copy "$path" "$AI_DIR/templates/unity/Editor/UnityArchitecture/$old"; then
        rm -f "$path" "$path.meta"
        removed+=("$OLD_EDITOR_TOOLS/$old")
    else
        customized+=("$OLD_EDITOR_TOOLS/$old (now in the .ai/unity package: delete this copy after merging your changes)")
    fi
done
for folder in "$OLD_EDITOR_TOOLS/Tests" "$OLD_EDITOR_TOOLS"; do
    if [ -d "$ROOT/$folder" ] && [ -z "$(ls -A "$ROOT/$folder")" ]; then
        rmdir "$ROOT/$folder" && rm -f "$ROOT/$folder.meta"
    fi
done

# Registers the Unity MCP server (MCP for Unity, by Coplay) for Claude Code, on its default local address.
# It runs only on this machine and only while the Editor is open with the package installed.
if [ -e "$ROOT/.mcp.json" ]; then
    kept+=(".mcp.json")
    if ! grep -q '"unityMCP"' "$ROOT/.mcp.json"; then
        MCP_NOTE="Your .mcp.json was kept and has no unityMCP server. Add the one in .ai/templates/mcp.json to use a Unity MCP server."
    fi
else
    cp "$TEMPLATES/mcp.json" "$ROOT/.mcp.json"
    created+=(".mcp.json")
fi

# The rules' Editor tools (the prefab validator) are a local package in .ai/unity, so they stay on the same
# version as the rules. It's listed in testables so Unity runs its tests, including the check of Assets/Client.
MANIFEST="$ROOT/Packages/manifest.json"
ARCHITECTURE_PACKAGE="com.sgonzalezrozo.unity-architecture"
add_architecture_package() {
    local temporary="$MANIFEST.tmp"
    awk -v name="$ARCHITECTURE_PACKAGE" '
        { print }
        /"dependencies"[[:space:]]*:[[:space:]]*\{/ && !dependency { print "    \"" name "\": \"file:../.ai/unity\","; dependency = 1 }
        /"testables"[[:space:]]*:[[:space:]]*\[/ && !testable { print "    \"" name "\","; testable = 1 }
    ' "$MANIFEST" > "$temporary" || return 1
    if ! grep -q '"testables"' "$temporary"; then
        awk -v name="$ARCHITECTURE_PACKAGE" 'NR == 1 { print; print "  \"testables\": [\n    \"" name "\"\n  ],"; next } { print }' "$temporary" > "$temporary.2" && mv "$temporary.2" "$temporary"
    fi
    mv "$temporary" "$MANIFEST"
}
if [ -f "$MANIFEST" ] && ! grep -q "\"$ARCHITECTURE_PACKAGE\"" "$MANIFEST"; then
    if add_architecture_package; then
        updated+=("Packages/manifest.json (adds $ARCHITECTURE_PACKAGE from .ai/unity)")
    else
        MANIFEST_NOTE="Couldn't add $ARCHITECTURE_PACKAGE to Packages/manifest.json. Add \"$ARCHITECTURE_PACKAGE\": \"file:../.ai/unity\" to dependencies and to testables."
    fi
fi

if [ -e "$ROOT/.claude/settings.json" ]; then
    kept+=(".claude/settings.json")
    if ! grep -q "verify-on-stop.sh" "$ROOT/.claude/settings.json"; then
        SETTINGS_NOTE="Your .claude/settings.json was kept and has no verify hook. Add the Stop hook and the allowed commands from .ai/templates/claude/settings.json to it."
    fi
else
    mkdir -p "$ROOT/.claude"
    cp "$TEMPLATES/claude/settings.json" "$ROOT/.claude/settings.json"
    created+=(".claude/settings.json")
fi

# The analyzers turn the mechanical rules into compile errors. They check only the assembly named Client, so a new
# project gets Assets/Client/Client.asmdef with Client.cs, a note that keeps Unity from warning about an assembly
# definition with no scripts. When Assets/Client already has code but no Client.asmdef, it's left alone.
ANALYZER="UnityArchitecture.Analyzers"
CLIENT="Assets/Client"
if [ ! -e "$ROOT/$CLIENT/Client.asmdef" ] && [ -z "$(ls -A "$ROOT/$CLIENT" 2>/dev/null)" ]; then
    own "$CLIENT/Client.asmdef" '{
    "name": "Client",
    "rootNamespace": "",
    "references": [
        "UnityEngine.UI",
        "Unity.TextMeshPro"
    ],
    "includePlatforms": [],
    "excludePlatforms": [],
    "allowUnsafeCode": false,
    "overrideReferences": false,
    "precompiledReferences": [],
    "autoReferenced": true,
    "defineConstraints": [],
    "versionDefines": [],
    "noEngineReferences": false
}'
    own "$CLIENT/Client.cs" '// The Client assembly (Client.asmdef) holds this project'"'"'s own code. The architecture analyzers in
// Analyzers/ check only this assembly, so third-party code elsewhere in Assets isn'"'"'t checked.'
fi
if [ -e "$ROOT/$CLIENT/Client.asmdef" ]; then
    copy "$CLIENT/Analyzers/$ANALYZER.dll" "$AI_DIR/analyzers/prebuilt/$ANALYZER.dll"
    copy "$CLIENT/Analyzers/$ANALYZER.dll.meta" "$AI_DIR/analyzers/dll.meta.template"
else
    ANALYZER_NOTE="Analyzers not installed: $CLIENT has code but no Client.asmdef. The analyzers check only the assembly named Client, so add $CLIENT/Client.asmdef and run this again. See .ai/architecture/FEATURE_STRUCTURE.md."
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
print_list "Updated from .ai:" ${updated[@]+"${updated[@]}"}
print_list "Removed (moved to the .ai/unity package):" ${removed[@]+"${removed[@]}"}
print_list "Changed in this project, kept (compare with .ai/templates and merge what you want by hand):" ${customized[@]+"${customized[@]}"}
if [ "$UPDATE" = true ]; then
    print_list "Already up to date, or yours to edit:" ${kept[@]+"${kept[@]}"}
else
    print_list "Already there, kept (--update refreshes the copied templates):" ${kept[@]+"${kept[@]}"}
fi
for note in "${SETTINGS_NOTE:-}" "${MCP_NOTE:-}" "${ANALYZER_NOTE:-}" "${MANIFEST_NOTE:-}"; do
    if [ -n "$note" ]; then
        echo
        echo "$note"
    fi
done

# A first batch-mode run imports the whole project, which can take longer than the hook waits.
# Running it once now makes the hook's checks quick.
changed=$(( ${#created[@]} + ${#updated[@]} ))
if [ "$VERIFY" = ask ] && [ "$changed" -gt 0 ] && [ -t 0 ] && [ -t 1 ]; then
    echo
    echo "Run scripts/verify.sh now? It compiles the project once in batch mode, so the hook is quick later."
    printf "Close the project in Unity first. It can take a few minutes. [y/N] "
    read -r answer
    case "$answer" in y|Y|yes|Yes) VERIFY=yes ;; esac
fi
if [ "$VERIFY" = yes ]; then
    echo
    "$ROOT/scripts/verify.sh"
    echo "verify.sh exit code: $? (0 passed, 1 failed, 2 couldn't run)"
fi

echo
echo "Next:"
echo "  1. Commit these files and .ai in your project."
echo "  2. In Rider, open .aiassistant/rules/project.md and set the rule's type to Always."
echo "  3. Write rules that only apply to this project in AGENTS.md."
echo "  4. To work with the Editor open, install MCP for Unity"
echo "     (Package Manager > Add package from git URL: https://github.com/CoplayDev/unity-mcp.git?path=/MCPForUnity)."
echo "     In Window > MCP for Unity: choose HTTP Local, click Start Server, and turn on the Testing and"
echo "     Scripting Extensions tool groups. .mcp.json already registers the server for Claude Code."
echo "  5. Ask Claude for a feature. With the project closed in Unity, the hook verifies in batch mode;"
echo "     with it open, it reads the Editor's results."
echo "  Step by step: .ai/docs/INSTALLATION.md. Prompts that work: .ai/docs/USAGE.md."
