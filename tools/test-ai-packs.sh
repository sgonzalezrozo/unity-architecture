#!/usr/bin/env bash
# Tests templates/scripts/ai-packs.sh and ai-facts.sh in throwaway projects: forks resolve to the profile's branch,
# package documentation and symbols are traced to their source, packs regenerate only when an input changes, and
# project facts report localization as separate facts. Usage: bash tools/test-ai-packs.sh
set -u

REPO="$(cd "$(dirname "$0")/.." && pwd)"
PACKS="$REPO/templates/scripts/ai-packs.sh"
FACTS="$REPO/templates/scripts/ai-facts.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
FAILURES=0

check() {
    if eval "$2"; then
        echo "ok    $1"
    else
        echo "FAIL  $1"
        FAILURES=$((FAILURES + 1))
    fi
}

command -v jq > /dev/null 2>&1 || { echo "skip  jq not installed"; exit 0; }

# A project with the repository as .ai, and UI Scroller as a local package with only part of its documentation.
make_project() {
    local project="$1" profile="$2"
    mkdir -p "$project/Logs/ai" "$project/Packages" "$project/scroller/Documentation~"
    ln -s "$REPO" "$project/.ai"
    printf '%s\n' "$profile" > "$project/Logs/ai/profile.json"
    printf '{ "dependencies": { "com.sgonzalezrozo.ui-scroller": "file:../scroller" } }\n' > "$project/Packages/manifest.json"
    printf '# UI Scroller rules\n\n## Build a list\n\nUse `Scroller<T>` and `ISlot<T>`.\n' > "$project/scroller/Documentation~/agent-rules.md"
    printf '# API\n\n## Sources and slots\n\n`SectionedSource<TItem, THeader>`, `ListSource<T>`, `AddSection`, `ISectionedSourceProvider`.\n\n## Overridable\n\nNot in the pack.\n' > "$project/scroller/Documentation~/api-reference.md"
    printf '# Layouts\n\n## Bento\n\nCall `SetBentoLayout`.\n\n## Sections and headers\n\n`SectionedScroller<TItem, THeader>` with a `SectionedSource<TItem, THeader>`: `AddSection`, `ISectionedSourceProvider`. See [examples](examples.md#bento-sections).\n\n## Expandable slots\n\nNot in the pack.\n' > "$project/scroller/Documentation~/layouts.md"
}

ALL='{ "capabilities": { "fastIoC": true, "uiScroller": true, "screenSystem": false, "uiFoundations": false }, "forks": { "container": "fast-ioc", "list": "ui-scroller", "navigation": "no-screen-system", "input": "no-ui-foundations" } }'
NONE='{ "capabilities": { "fastIoC": false, "uiScroller": false, "screenSystem": false, "uiFoundations": false }, "forks": { "container": "no-container", "list": "no-ui-scroller", "navigation": "no-screen-system", "input": "no-ui-foundations" } }'

WITH="$TMP/with"
make_project "$WITH" "$ALL"
(cd "$WITH" && bash "$PACKS" > /dev/null 2>&1)
LIST="$WITH/Logs/ai/packs/ui-list.md"
check "the list pack holds the profile's branch" "grep -q 'source: .ai/architecture/branches/ui-scroller/lists.md' '$LIST'"
check "and not the other branch" "! grep -q 'no-ui-scroller' '$LIST'"
check "no fork block is left" "! grep -q '^> \*\*Fork' '$WITH'/Logs/ai/packs/*.md"
check "a package section keeps its source and checksum" "grep -q 'source: package scroller/Documentation~/layouts.md#sections-and-headers · cksum [0-9]' '$LIST'"
check "only the named section of a package doc is copied" "! grep -q 'Not in the pack' '$LIST'"
check "a documented symbol cites its section" "grep -q '| \`SectionedSource<TItem, THeader>\` | package scroller/Documentation~/api-reference.md#sources-and-slots |' '$LIST'"
check "a symbol missing from its section is flagged" "grep -q '| \`SkipEmptySections\` | not found in its source' '$LIST'"
check "a missing package doc is listed under Not included" "grep -q 'data-and-sizes.md not found' '$LIST'"
check "relative links point from the project root" "grep -q '](.ai/architecture/' '$WITH/Logs/ai/packs/new-feature.md'"
check "a missing package (Fast IoC) is listed, not invented" "grep -q 'package for fastIoC not found' '$WITH/Logs/ai/packs/new-feature.md'"
check "the index lists every pack" "[ \"\$(grep -c '^| \`Logs/ai/packs/' '$WITH/Logs/ai/packs/index.md')\" = \"\$(jq '.packs | length' '$REPO/packs.json')\" ]"

BEFORE="$(cksum < "$LIST")"
touch -t 200001010000 "$LIST"
(cd "$WITH" && bash "$PACKS" > /dev/null 2>&1)
check "nothing changed: the packs aren't rewritten" "[ \"\$(stat -f %m '$LIST' 2>/dev/null || stat -c %Y '$LIST')\" -lt 1000000000 ]"
printf '\n## Sections and headers extra\n' >> "$WITH/scroller/Documentation~/agent-rules.md"
(cd "$WITH" && bash "$PACKS" > /dev/null 2>&1)
check "a changed source rewrites the packs" "[ \"\$(cksum < '$LIST')\" != \"$BEFORE\" ]"

WITHOUT="$TMP/without"
make_project "$WITHOUT" "$NONE"
(cd "$WITHOUT" && bash "$PACKS" > /dev/null 2>&1)
check "without UI Scroller, the list pack holds no-ui-scroller" "grep -q 'source: .ai/architecture/branches/no-ui-scroller/lists.md' '$WITHOUT/Logs/ai/packs/ui-list.md'"
check "and no package documentation" "! grep -q 'source: package' '$WITHOUT/Logs/ai/packs/ui-list.md'"
check "a branch without the file is left out silently" "! grep -q 'installers.md' '$WITHOUT/Logs/ai/packs/new-feature.md'"

# Project facts.
FACTS_PROJECT="$TMP/facts"
mkdir -p "$FACTS_PROJECT/ProjectSettings" "$FACTS_PROJECT/Packages" "$FACTS_PROJECT/Assets/Client/Shop/Services" "$FACTS_PROJECT/Assets/Client/Shop/Tests"
cat > "$FACTS_PROJECT/ProjectSettings/EditorBuildSettings.asset" <<'EOF'
EditorBuildSettings:
  m_Scenes:
  - enabled: 1
    path: Assets/Scenes/Menu.unity
  - enabled: 0
    path: Assets/Scenes/Old.unity
  m_configObjects:
    com.unity.addressableassets: {fileID: 1}
EOF
printf '{ "dependencies": { "com.unity.localization": "1.5.9", "com.sgonzalezrozo.core": "file:../../Packages/unity-tools-core" } }\n' > "$FACTS_PROJECT/Packages/manifest.json"
printf '{ "name": "Client", "references": ["UIScroller", "FastIoC"] }\n' > "$FACTS_PROJECT/Assets/Client/Client.asmdef"
printf '[MonoInstaller("Menu", Priority = 200)]\npublic class ShopInstaller {}\n' > "$FACTS_PROJECT/Assets/Client/Shop/Services/ShopInstaller.cs"
printf 'class ShopModelTests {}\n' > "$FACTS_PROJECT/Assets/Client/Shop/Tests/ShopModelTests.cs"
(cd "$FACTS_PROJECT" && bash "$FACTS" > /dev/null)
FACTS_FILE="$FACTS_PROJECT/Logs/ai/project-facts.md"
check "facts: only enabled scenes" "grep -q 'Scenes enabled in Build Settings: \`Menu\` (source:' '$FACTS_FILE' && ! grep -q 'Old' '$FACTS_FILE'"
check "facts: installers with their file and line" "grep -q 'MonoInstaller(\"Menu\", Priority = 200)\]\` (source: Assets/Client/Shop/Services/ShopInstaller.cs:1)' '$FACTS_FILE'"
check "facts: Client references" "grep -q '\`UIScroller\`, \`FastIoC\` (source: Assets/Client/Client.asmdef)' '$FACTS_FILE'"
check "facts: a feature with tests and an installer" "grep -q '\`Shop\` (tests, installer)' '$FACTS_FILE'"
check "facts: localization installed is not configured" "grep -q 'package installed: yes' '$FACTS_FILE' && grep -q 'settings asset configured: no' '$FACTS_FILE'"
check "facts: localization use is counted, not assumed" "grep -q 'Client code that uses it: 0 files' '$FACTS_FILE'"
printf 'public static class ScreenIds\n{\n    public const string ShopOffer = "ShopOffer";\n    public static readonly string Menu = "Menu";\n}\n' > "$FACTS_PROJECT/Assets/Client/Shop/Services/ScreenIds.cs"
(cd "$FACTS_PROJECT" && bash "$FACTS" > /dev/null)
check "facts: the Forget helper is the Tools Core one" "grep -q 'Forget helper (async-and-errors): ToolsCore.TaskExtensions.Forget in the Tools Core package' '$FACTS_FILE'"
check "facts: screen ids are listed with their source" "grep -q 'Screen ids (ScreenIds, SCR-12): \`ShopOffer\`, \`Menu\` (source: Assets/Client/Shop/Services/ScreenIds.cs)' '$FACTS_FILE'"

echo
[ "$FAILURES" -eq 0 ] && echo "All passed." || echo "$FAILURES failed."
exit $(( FAILURES > 0 ))
