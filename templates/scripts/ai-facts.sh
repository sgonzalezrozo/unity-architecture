#!/usr/bin/env bash
# Writes Logs/ai/project-facts.md: what an agent otherwise looks up in the project on every task (scenes, existing
# installers, the Client assembly's references, the features, localization). Every fact names the file it was read
# from. Nothing is inferred: a package that's installed is reported as installed, not as configured or used.
# It reads the files on every run, which is quick, and rewrites the file only when a fact changed.
#
# Usage, from the project root:
#   scripts/ai-facts.sh           writes the facts when they changed
#   scripts/ai-facts.sh --print   also prints them (what the SessionStart hook shows)
set -u

PRINT=false
for arg in "$@"; do
    case "$arg" in
        --print) PRINT=true ;;
        -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
        *) echo "Unknown option: $arg (use --print or --help)" >&2; exit 2 ;;
    esac
done

OUT_DIR="${AI_FACTS_OUT:-Logs/ai}"
OUT="$OUT_DIR/project-facts.md"
BUILD_SETTINGS="ProjectSettings/EditorBuildSettings.asset"
MANIFEST="Packages/manifest.json"
CLIENT_ASMDEF="Assets/Client/Client.asmdef"

manifest_has() {
    grep -q "\"$1\"[[:space:]]*:" "$MANIFEST" 2>/dev/null
}

scenes_in_build() {
    [ -f "$BUILD_SETTINGS" ] || { echo "- Build Settings: not found (source: $BUILD_SETTINGS)"; return; }
    awk '
        /^  m_Scenes:/ { inside = 1; next }
        inside && /^  [a-zA-Z]/ { inside = 0 }
        inside && /enabled:/ { enabled = $NF }
        inside && /path:/ {
            path = $2; name = path; sub(/.*\//, "", name); sub(/\.unity$/, "", name)
            if (enabled == 1) enabledList = enabledList (enabledList ? ", " : "") "`" name "`"
        }
        END { printf "- Scenes enabled in Build Settings: %s (source: ProjectSettings/EditorBuildSettings.asset)\n", enabledList ? enabledList : "none" }
    ' "$BUILD_SETTINGS"
}

installers() {
    local found
    found="$(grep -rn --include='*.cs' '\[MonoInstaller(' Assets 2>/dev/null | sort)"
    if [ -z "$found" ]; then
        echo "- Fast IoC installers: none in Assets (source: grep of [MonoInstaller( in Assets)"
        return
    fi
    echo "- Fast IoC installers (source: each file):"
    printf '%s\n' "$found" | awk -F: '{
        line = $0; sub(/^[^:]*:[^:]*:/, "", line); sub(/^[[:space:]]+/, "", line)
        printf "  - `%s` (source: %s:%s)\n", line, $1, $2
    }'
}

client_references() {
    [ -f "$CLIENT_ASMDEF" ] || { echo "- Client assembly: no $CLIENT_ASMDEF"; return; }
    local references
    if command -v jq > /dev/null 2>&1; then
        references="$(jq -r '.references | map("`" + . + "`") | join(", ")' "$CLIENT_ASMDEF" 2>/dev/null)"
    else
        references="$(tr -d '\n' < "$CLIENT_ASMDEF" | sed -n 's/.*"references"[^[]*\[\([^]]*\)\].*/\1/p' | tr -d ' "' | sed 's/,/, /g')"
    fi
    echo "- Client.asmdef references: ${references:-none} (source: $CLIENT_ASMDEF)"
}

features() {
    local folder name notes
    [ -d Assets/Client ] || return
    echo "- Features in Assets/Client (source: the folders):"
    for folder in Assets/Client/*/; do
        name="$(basename "$folder")"
        case "$name" in Analyzers|Tests|Shared) continue ;; esac
        notes=""
        [ -n "$(find "$folder" -path '*/Tests/*.cs' 2>/dev/null | head -1)" ] && notes+=", tests"
        [ -n "$(find "$folder" -name '*.Tests.asmdef' 2>/dev/null | head -1)" ] && notes+=", test assembly"
        [ -n "$(find "$folder" -path '*/Services/*Installer.cs' 2>/dev/null | head -1)" ] && notes+=", installer"
        [ -f "$folder/IMPLEMENTATION.md" ] && notes+=", IMPLEMENTATION.md"
        echo "  - \`$name\`${notes:+ (${notes#, })}"
    done
}

existing_files() {
    local folder name files
    [ -d Assets/Client ] || return
    echo "- Existing screens and prefabs per feature (source: the folders; the agent doesn't create, move or delete them, TASK-06):"
    for folder in Assets/Client/*/; do
        name="$(basename "$folder")"
        case "$name" in Analyzers|Tests|Shared) continue ;; esac
        files="$(cd "$folder" && find . \( -name '*.asset' -o -name '*.prefab' \) ! -name '*.meta' | sed 's|^\./||' | sort | paste -sd, - | sed 's/,/, /g')"
        [ -n "$files" ] && echo "  - \`$name\`: $files"
    done
}

localization() {
    local installed=no configured=no used=0
    manifest_has com.unity.localization && installed=yes
    grep -q 'com.unity.localization.settings:' "$BUILD_SETTINGS" 2>/dev/null && configured=yes
    used="$(grep -rl --include='*.cs' 'UnityEngine.Localization' Assets/Client 2>/dev/null | wc -l | tr -d ' ')"
    echo "- Unity Localization:"
    echo "  - package installed: $installed (source: $MANIFEST)"
    echo "  - settings asset configured: $configured (source: m_configObjects in $BUILD_SETTINGS)"
    echo "  - Client code that uses it: $used files (source: grep of UnityEngine.Localization in Assets/Client)"
    echo "  - Whether that counts as the project's localization system: csharp/style.md (Writing code)."
}

forget_helper() {
    if manifest_has com.sgonzalezrozo.core; then
        echo "- Forget helper (async-and-errors): ToolsCore.TaskExtensions.Forget in the Tools Core package (source: $MANIFEST)"
    else
        echo "- Forget helper (async-and-errors): Tools Core package not installed, so no Forget helper (source: $MANIFEST)"
    fi
}

screen_ids() {
    local file names
    file="$(grep -rl --include='*.cs' 'class ScreenIds' Assets 2>/dev/null | head -1)"
    if [ -z "$file" ]; then
        echo "- Screen ids (ScreenIds, SCR-12): no ScreenIds class in Assets: a screen that doesn't exist yet is an open question (source: grep of class ScreenIds in Assets)"
        return
    fi
    names="$(grep -oE '(const|readonly) +string +[A-Za-z0-9_]+' "$file" | awk '{ print "`" $NF "`" }' | paste -sd, - | sed 's/,/, /g')"
    echo "- Screen ids (ScreenIds, SCR-12): ${names:-none} (source: $file)"
}

test_framework() {
    local installed=no
    manifest_has com.unity.test-framework && installed=yes
    echo "- Unity Test Framework installed: $installed (source: $MANIFEST)"
}

facts="$(
    printf '# Project facts\n\n'
    printf 'Generated by `scripts/ai-facts.sh` from the files each line names; do not edit. Read at session start: check the\n'
    printf 'source again before relying on a fact the current task may have changed.\n\n'
    scenes_in_build
    installers
    client_references
    features
    existing_files
    localization
    forget_helper
    screen_ids
    test_framework
)"

mkdir -p "$OUT_DIR"
if [ "$(cat "$OUT" 2>/dev/null)" != "$facts" ]; then
    printf '%s\n' "$facts" > "$OUT"
fi
[ "$PRINT" = true ] && printf '\n%s\n' "$facts"
exit 0
