#!/usr/bin/env bash
# Tests templates/scripts/ai-profile.sh on throwaway projects: the forks it resolves, its cache, and that a change to the
# manifest or to a checked path regenerates the profile. Run it from anywhere: bash tools/test-ai-profile.sh
set -u

AI_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
FAILURES=0

# project <name> <manifest dependencies JSON>: a project with .ai linked and scripts/ai-profile.sh copied.
project() {
    local dir="$WORK/$1"
    mkdir -p "$dir/Packages" "$dir/scripts"
    ln -s "$AI_DIR" "$dir/.ai"
    cp "$AI_DIR/templates/scripts/ai-profile.sh" "$dir/scripts/ai-profile.sh"
    printf '{\n  "dependencies": {\n%s\n  }\n}\n' "$2" > "$dir/Packages/manifest.json"
    echo "$dir"
}

expect() {
    local description="$1" file="$2" pattern="$3"
    if grep -q -- "$pattern" "$file"; then
        echo "ok    $description"
    else
        echo "FAIL  $description: no '$pattern' in $(basename "$file")"
        FAILURES=$((FAILURES + 1))
    fi
}

full="$(project full '    "com.sgonzalezrozo.fast-ioc": "1.0.0",
    "com.sgonzalezrozo.ui-scroller": "1.0.0",
    "com.sgonzalezrozo.screen-system": "1.0.0",
    "com.sgonzalezrozo.ui-foundations": "1.0.0"')"
bash "$full/scripts/ai-profile.sh" > /dev/null
expect "fastIoC resolves container to fast-ioc" "$full/Logs/ai/profile.json" '"container": "fast-ioc"'
expect "uiScroller resolves list to ui-scroller" "$full/Logs/ai/profile.json" '"list": "ui-scroller"'
expect "screenSystem resolves navigation" "$full/Logs/ai/profile.json" '"navigation": "screen-system"'
expect "uiFoundations resolves input" "$full/Logs/ai/profile.json" '"input": "ui-foundations"'
expect "generationStatus follows fastIoC" "$full/Logs/ai/profile.json" '"generationStatus": true'
expect "profile.md names the branch folder" "$full/Logs/ai/profile.md" '.ai/architecture/branches/fast-ioc/'

plain="$(project plain '    "com.unity.ugui": "2.0.0"')"
bash "$plain/scripts/ai-profile.sh" > /dev/null
expect "no packages resolves container to no-container" "$plain/Logs/ai/profile.json" '"container": "no-container"'
expect "no packages resolves list to no-ui-scroller" "$plain/Logs/ai/profile.json" '"list": "no-ui-scroller"'
expect "false capabilities are listed" "$plain/Logs/ai/profile.md" '`fastIoC`'

zenject="$(project zenject '    "com.unity.ugui": "2.0.0"')"
mkdir -p "$zenject/Assets/Plugins/Zenject"
bash "$zenject/scripts/ai-profile.sh" > /dev/null
expect "a Zenject folder resolves container to other-container" "$zenject/Logs/ai/profile.json" '"container": "other-container"'

both="$(project both '    "com.sgonzalezrozo.fast-ioc": "1.0.0",
    "jp.hadashikick.vcontainer": "1.0.0"')"
bash "$both/scripts/ai-profile.sh" > /dev/null
expect "fastIoC wins over another container (table order)" "$both/Logs/ai/profile.json" '"container": "fast-ioc"'

# Cache: an unchanged project keeps the same files; a manifest change regenerates them.
before="$(cat "$plain/Logs/ai/profile.hash")"
touch -t 200001010000 "$plain/Logs/ai/profile.json"
bash "$plain/scripts/ai-profile.sh" > /dev/null
if [ "$(find "$plain/Logs/ai/profile.json" -newermt '2001-01-01' 2>/dev/null)" = "" ]; then
    echo "ok    an unchanged project isn't regenerated"
else
    echo "FAIL  an unchanged project was regenerated"; FAILURES=$((FAILURES + 1))
fi
sed -i.bak 's/"com.unity.ugui": "2.0.0"/"com.unity.ugui": "2.0.0", "com.sgonzalezrozo.ui-scroller": "1.0.0"/' "$plain/Packages/manifest.json"
bash "$plain/scripts/ai-profile.sh" > /dev/null
expect "a manifest change regenerates the profile" "$plain/Logs/ai/profile.json" '"list": "ui-scroller"'
[ "$(cat "$plain/Logs/ai/profile.hash")" != "$before" ] && echo "ok    the hash changed" || { echo "FAIL  the hash didn't change"; FAILURES=$((FAILURES + 1)); }

mkdir -p "$plain/scripts" && touch "$plain/scripts/verify.sh"
bash "$plain/scripts/ai-profile.sh" > /dev/null
expect "a new checked path regenerates the profile" "$plain/Logs/ai/profile.json" '"verifyScript": true'

output="$(bash "$plain/scripts/ai-profile.sh" --print)"
case "$output" in *"# Project profile"*) echo "ok    --print prints the profile" ;; *) echo "FAIL  --print printed nothing"; FAILURES=$((FAILURES + 1)) ;; esac

echo
[ "$FAILURES" -eq 0 ] && echo "All passed." || echo "$FAILURES failed."
exit $(( FAILURES > 0 ))
