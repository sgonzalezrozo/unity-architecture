#!/usr/bin/env bash
# Checks the rules mechanically (DET-04), for the maintainers of this repository:
#   1. Every rule ID is defined once: one table row "| `ID` |" in AGENTS.md or architecture/.
#   2. Every fork block names a fork from capabilities.json, lists exactly its branches, and links files that exist.
#   3. Every branch of every fork has a folder with at least one file in architecture/branches/.
#   4. Every relative link in the Markdown files resolves, anchors included.
#   5. No <!-- if: --> markers in the rules: those are for the Rules Guide's docs; the rules use forks.
#   6. Every "source" in the Rules Guide's knowledge.json points to a file that exists.
#   7. packs.json: entries resolve in every branch, symbols cite their pack, every rule file is in a pack (ai-packs.sh).
# Usage: bash tools/lint-rules.sh. Exit code 0 when everything passes, 1 otherwise.
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 2
TABLE="capabilities.json"
FAILURES=0
FORKS_FILE="$(mktemp)"
SOURCES_FILE="$(mktemp)"
trap 'rm -f "$FORKS_FILE" "$SOURCES_FILE"' EXIT

fail() {
    echo "FAIL  $1"
    FAILURES=$((FAILURES + 1))
}

# The Markdown files that carry rules or link to them. The changelog quotes old links on purpose.
markdown_files() {
    find . -name '*.md' -not -path './.git/*' -not -path '*/KnowledgeDocs~/*' -not -name CHANGELOG.md | sed 's|^\./||' | sort
}

rule_files() {
    { echo AGENTS.md; find architecture -name '*.md' -not -name DEVELOPER_OVERVIEW.md -not -path 'architecture/examples/*'; } | sort
}

# Lines outside fenced code blocks, as "<line number><TAB><text>".
unfenced() {
    awk '/^[[:space:]]*```/ { fenced = !fenced; next } !fenced { print FNR "\t" $0 }' "$1"
}

# GitHub's anchor for a heading: lower case, no punctuation, spaces to hyphens.
anchors_of() {
    unfenced "$1" | cut -f2- | awk '/^#+ / {
        sub(/^#+ +/, ""); text = tolower($0)
        gsub(/[^a-z0-9 _-]/, "", text); gsub(/ /, "-", text); print text
    }'
}

# 1. Rule IDs defined once.
duplicates="$(rule_files | while IFS= read -r file; do
    grep -o '^| `[A-Z][A-Z]*-[0-9][0-9]*` |' "$file" | sed "s/^| \`\([^\`]*\)\` |/\1/; s|$|	$file|"
done | sort | awk -F'\t' '{ count[$1]++; where[$1] = where[$1] " " $2 } END { for (id in count) if (count[id] > 1) print id ":" where[id] }')"
if [ -n "$duplicates" ]; then
    while IFS= read -r line; do fail "rule ID defined more than once: $line"; done <<< "$duplicates"
else
    echo "ok    every rule ID is defined once"
fi

# Each fork of the table as "id branch branch ...".
fork_branches() {
    grep '"branches"' "$TABLE" | sed 's/.*"id": *"\([^"]*\)".*"branches": *\[\([^]]*\)\].*/\1 \2/' \
        | tr -d '",' | awk '{ printf "%s", $1; for (i = 2; i <= NF; i++) { split($i, part, ":"); printf " %s", part[2] } print "" }'
}

# 2. Fork blocks.
forks_checked=0
while IFS= read -r file; do
    unfenced "$file" | awk -F'\t' -v file="$file" '
        $2 ~ /^> \*\*Fork `/ { fork = $2; sub(/^> \*\*Fork `/, "", fork); sub(/`.*/, "", fork); line = $1; next }
        fork != "" && $2 ~ /^> - `/ {
            branch = $2; sub(/^> - `/, "", branch); sub(/`.*/, "", branch)
            rest = $2
            while (match(rest, /\]\([^)]*\)/)) {
                print file "\t" line "\t" fork "\t" branch "\t" substr(rest, RSTART + 2, RLENGTH - 3)
                rest = substr(rest, RSTART + RLENGTH)
            }
            next
        }
        { fork = "" }'
done < <(markdown_files) > "$FORKS_FILE"
while IFS=$'\t' read -r file line fork branch target; do
    [ -e "$(dirname "$file")/$target" ] || fail "$file:$line: fork $fork, branch $branch links $target, which doesn't exist"
done < "$FORKS_FILE"
while IFS=$'\t' read -r file line fork; do
    expected="$(fork_branches | awk -v f="$fork" '$1 == f { $1 = ""; print substr($0, 2) }' | tr ' ' '\n' | sort | tr '\n' ' ')"
    if [ -z "$expected" ]; then
        fail "$file:$line: fork $fork isn't in $TABLE"
        continue
    fi
    listed="$(awk -F'\t' -v f="$file" -v l="$line" '$1 == f && $2 == l { print $4 }' "$FORKS_FILE" | sort -u | tr '\n' ' ')"
    [ "$listed" = "$expected" ] || fail "$file:$line: fork $fork lists [$listed], $TABLE has [$expected]"
    forks_checked=$((forks_checked + 1))
done < <(cut -f1-3 "$FORKS_FILE" | sort -u)
echo "ok    $forks_checked fork blocks checked"

# 3. Branch folders.
while read -r fork branches; do
    for branch in $branches; do
        [ -n "$(ls "architecture/branches/$branch" 2>/dev/null)" ] || fail "fork $fork: no files in architecture/branches/$branch"
    done
done < <(fork_branches)
echo "ok    every branch has a folder"

# 4. Relative links and anchors.
links_checked=0
while IFS= read -r file; do
    while IFS=$'\t' read -r line target; do
        path="${target%%#*}"
        anchor=""
        [ "$path" != "$target" ] && anchor="${target#*#}"
        resolved="$file"
        [ -n "$path" ] && resolved="$(dirname "$file")/$path"
        links_checked=$((links_checked + 1))
        if [ ! -e "$resolved" ]; then
            fail "$file:$line: broken link $target"
        elif [ -n "$anchor" ] && [ -f "$resolved" ] && ! anchors_of "$resolved" | grep -qxF "$anchor"; then
            fail "$file:$line: no anchor #$anchor in $resolved"
        fi
    done < <(unfenced "$file" | awk -F'\t' '{
        rest = $2
        while (match(rest, /\]\([^) ]+\)/)) {
            target = substr(rest, RSTART + 2, RLENGTH - 3); rest = substr(rest, RSTART + RLENGTH)
            if (target !~ /^(https?:|mailto:|doc:)/) print $1 "\t" target
        }
    }')
done < <(markdown_files)
echo "ok    $links_checked relative links checked"

# 5. No Rules Guide markers in the rules.
markers="$(rule_files | xargs grep -n '<!-- *if' 2>/dev/null)"
[ -z "$markers" ] && echo "ok    no conditional markers in the rules" || fail "conditional markers in the rules: $markers"

# 6. Rules Guide sources.
for catalog in unity/KnowledgeDocs~/knowledge.json unity/KnowledgeDocs~/es/knowledge.json; do
    grep -o '"source": *"[^"]*"' "$catalog" | sed 's/.*"\([^"]*\)"$/\1/' | sort -u | while IFS= read -r source; do
        case "$source" in package:*|enforcement:*) continue ;; esac  # another repository's file
        [ -e "${source%%#*}" ] || echo "FAIL  $catalog: source $source doesn't exist"
    done
done | tee "$SOURCES_FILE"
[ -s "$SOURCES_FILE" ] && FAILURES=$((FAILURES + $(wc -l < "$SOURCES_FILE"))) || echo "ok    every Rules Guide source exists"

# 7. Task packs: every entry resolves in every branch, symbols cite their pack, every rule file is in a pack, sizes fit.
if command -v jq > /dev/null 2>&1; then
    PACK_OUTPUT="$(bash templates/scripts/ai-packs.sh --check)"
    printf '%s\n' "$PACK_OUTPUT"
    FAILURES=$((FAILURES + $(printf '%s\n' "$PACK_OUTPUT" | grep -c '^FAIL')))
else
    echo "skip  task packs: jq not installed"
fi

echo
[ "$FAILURES" -eq 0 ] && echo "All checks passed." || echo "$FAILURES problem(s)."
exit $(( FAILURES > 0 ))
