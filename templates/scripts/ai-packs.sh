#!/usr/bin/env bash
# Writes the task packs (OPT-07): one file per kind of task in Logs/ai/packs/, with every rule section that task needs,
# each fork already resolved to the project's branch, and the verified package documentation the packs name. The
# sources and the symbols are chosen by hand in .ai/packs.json; nothing is inferred. Every section keeps its source
# and checksum, and a pack is rewritten only when packs.json, the profile, the manifest or one of its sources changes.
#
# Usage, from the project root:
#   scripts/ai-packs.sh            writes the packs when they're out of date
#   scripts/ai-packs.sh --force    rewrites them
#   scripts/ai-packs.sh --index    also prints the short index (what the SessionStart hook shows)
#   scripts/ai-packs.sh --check    for the rules' maintainers, from the .ai repository root: checks packs.json
# Needs jq. Without it, it says so and exits 0: agents then use the Load column of AGENTS.md.
set -u

MODE=generate
FORCE=false
INDEX=false
for arg in "$@"; do
    case "$arg" in
        --force) FORCE=true ;;
        --index) INDEX=true ;;
        --check) MODE=check ;;
        -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
        *) echo "Unknown option: $arg (use --force, --index, --check or --help)" >&2; exit 2 ;;
    esac
done

if ! command -v jq > /dev/null 2>&1; then
    echo "ai-packs.sh: jq not found, so no task packs were written. Install jq, or use the Load column of AGENTS.md." >&2
    exit 0
fi

ROOT="$(pwd -P)"
if [ "$MODE" = check ]; then
    AI_DIR="$ROOT"
else
    AI_DIR="${AI_PACKS_AI_DIR:-$ROOT/.ai}"
fi
PACKS_JSON="$AI_DIR/packs.json"
CAPABILITIES="$AI_DIR/capabilities.json"
PROFILE_JSON="${AI_PACKS_PROFILE:-$ROOT/Logs/ai/profile.json}"
MANIFEST="$ROOT/Packages/manifest.json"
OUT="${AI_PACKS_OUT:-$ROOT/Logs/ai/packs}"
[ -f "$PACKS_JSON" ] || { echo "ai-packs.sh: $PACKS_JSON not found." >&2; exit 0; }

# --- Resolving entries -----------------------------------------------------------------------------------------------

# The folder of a capability's package: a file: path in the manifest, or Unity's package cache.
package_root() {
    local capability="$1" name value cached
    for name in $(jq -r --arg id "$capability" '.capabilities[] | select(.id == $id) | .packages[]' "$CAPABILITIES"); do
        value="$(jq -r --arg name "$name" '.dependencies[$name] // empty' "$MANIFEST" 2>/dev/null)"
        case "$value" in
            file:*)
                (cd "$ROOT/Packages/${value#file:}" 2>/dev/null && pwd -P) && return 0 ;;
        esac
        for cached in "$ROOT"/Library/PackageCache/"$name"@*; do
            [ -d "$cached" ] && { printf '%s' "$cached"; return 0; }
        done
        [ -n "${AI_PACKS_PACKAGES:-}" ] && [ -d "$AI_PACKS_PACKAGES/$name" ] && { printf '%s' "$AI_PACKS_PACKAGES/$name"; return 0; }
    done
    return 1
}

capability_is_true() {
    [ "$(jq -r --arg id "$1" '.capabilities[$id] // false' "$PROFILE_JSON" 2>/dev/null)" = true ]
}

# Prints "file<TAB>anchor<TAB>label" for an entry, "skip<TAB>reason" when the profile leaves it out, or
# "missing<TAB>reason" when it should be there and isn't.
resolve_entry() {
    local entry="$1" path anchor="" fork file branch capability doc root
    case "$entry" in *"#"*) anchor="${entry#*#}"; entry="${entry%%#*}" ;; esac
    case "$entry" in
        fork:*)
            fork="${entry#fork:}"; file="${fork#*/}"; fork="${fork%%/*}"
            branch="$(jq -r --arg fork "$fork" '.forks[$fork] // empty' "$PROFILE_JSON" 2>/dev/null)"
            [ -n "$branch" ] || { printf 'missing\tno branch for fork %s in the profile\n' "$fork"; return; }
            path="architecture/branches/$branch/$file"
            [ -f "$AI_DIR/$path" ] || { printf 'skip\tbranch %s has no %s\n' "$branch" "$file"; return; }
            printf '%s\t%s\t%s\n' "$AI_DIR/$path" "$anchor" ".ai/$path"
            ;;
        package:*)
            capability="${entry#package:}"; doc="${capability#*/}"; capability="${capability%%/*}"
            capability_is_true "$capability" || { printf 'skip\tcapability %s is false\n' "$capability"; return; }
            root="$(package_root "$capability")" || { printf 'missing\tpackage for %s not found\n' "$capability"; return; }
            [ -f "$root/$doc" ] || { printf 'missing\t%s not found in %s\n' "$doc" "$(basename "$root")"; return; }
            printf '%s\t%s\t%s\n' "$root/$doc" "$anchor" "package $(basename "$root")/$doc"
            ;;
        *)
            [ -f "$AI_DIR/$entry" ] || { printf 'missing\t%s not found\n' "$entry"; return; }
            printf '%s\t%s\t%s\n' "$AI_DIR/$entry" "$anchor" ".ai/$entry"
            ;;
    esac
}

# GitHub's anchor for each heading outside code fences, the same as tools/lint-rules.sh.
anchors_of() {
    awk '/^[[:space:]]*```/ { fenced = !fenced; next }
        !fenced && /^#+ / {
            sub(/^#+ +/, ""); text = tolower($0)
            gsub(/[^a-z0-9 _-]/, "", text); gsub(/ /, "-", text); print text
        }' "$1"
}

# The section under an anchor (to the next heading of the same or a higher level), or the whole file.
extract() {
    local file="$1" anchor="$2"
    awk -v anchor="$anchor" '
        function slug(line,   text) {
            sub(/^#+ +/, "", line); text = tolower(line)
            gsub(/[^a-z0-9 _-]/, "", text); gsub(/ /, "-", text); return text
        }
        /^[[:space:]]*```/ { fenced = !fenced }
        {
            if (anchor == "") { print; next }
            if (!fenced && /^#+ /) {
                level = match($0, /[^#]/) - 1
                if (inside && level <= start_level) exit
                if (!inside && slug($0) == anchor) { inside = 1; start_level = level }
            }
            if (inside) print
        }' "$file"
}

# Drops what a resolved pack doesn't need (fork blocks, the "read this branch only when" line) and rewrites relative
# links so they point to the project root, where the agent works.
transform() {
    local source_dir="$1" source_label="$2"
    awk -v dir="$source_dir" -v self="$source_label" '
        function normalize(path,   parts, count, i, out, n) {
            count = split(path, parts, "/"); n = 0
            for (i = 1; i <= count; i++) {
                if (parts[i] == "" || parts[i] == ".") continue
                if (parts[i] == ".." && n > 0 && out[n] != "..") { n--; continue }
                out[++n] = parts[i]
            }
            absolute = substr(path, 1, 1) == "/"
            path = ""
            for (i = 1; i <= n; i++) path = path (i > 1 ? "/" : "") out[i]
            return (absolute ? "/" : "") path
        }
        /^> \*\*Fork `/ { dropping = 1; next }
        dropping && /^>/ { next }
        { dropping = 0 }
        /^Branch `[^`]+` of the `[^`]+` fork/ { next }
        {
            line = $0; result = ""
            while (match(line, /\]\([^)]+\)/)) {
                target = substr(line, RSTART + 2, RLENGTH - 3)
                if (target ~ /^#/) target = self target
                else if (target !~ /^(https?:|mailto:|\/)/) {
                    anchor = ""
                    if (index(target, "#")) { anchor = substr(target, index(target, "#")); target = substr(target, 1, index(target, "#") - 1) }
                    target = normalize(dir "/" target) anchor
                }
                result = result substr(line, 1, RSTART + 1) target ")"
                line = substr(line, RSTART + RLENGTH)
            }
            print result line
        }'
}

relative_dir() {
    local dir
    dir="$(cd "$(dirname "$1")" && pwd -P)"
    case "$dir/" in
        "$ROOT/"*) printf '%s' "${dir#"$ROOT"/}" ;;
        *) printf '%s' "$dir" ;;
    esac
}

checksum() {
    cksum < "$1" | awk '{ print $1 }'
}

pack_ids() {
    jq -r '.packs[].id' "$PACKS_JSON"
}

entries_of() {
    jq -r --arg id "$1" '.packs[] | select(.id == $id) | .entries[]' "$PACKS_JSON"
}

symbols_of() {
    jq -r --arg id "$1" '.packs[] | select(.id == $id) | (.symbols // {}) | to_entries[] | "\(.key)\t\(.value)"' "$PACKS_JSON"
}

# True when the symbol's name (generic parameters left out) appears in the section its entry resolves to.
symbol_documented() {
    local symbol="$1" entry="$2" resolved file anchor name
    resolved="$(resolve_entry "$entry")"
    file="$(printf '%s' "$resolved" | cut -f1)"
    anchor="$(printf '%s' "$resolved" | cut -f2)"
    [ -f "$file" ] || return 2
    name="${symbol%%<*}"
    extract "$file" "$anchor" | grep -Fq "$name"
}

# --- Writing the packs ----------------------------------------------------------------------------------------------

input_hash() {
    local id entry resolved file
    {
        cat "$PACKS_JSON" "$PROFILE_JSON" 2>/dev/null
        cat "$MANIFEST" 2>/dev/null
        for id in $(pack_ids); do
            while IFS= read -r entry; do
                resolved="$(resolve_entry "$entry")"
                file="$(printf '%s' "$resolved" | cut -f1)"
                printf '%s\n' "$resolved"
                [ -f "$file" ] && cat "$file"
            done < <(entries_of "$id")
        done
    } | cksum | awk '{ print $1 "-" $2 }'
}

# The source files a pack includes, as the agent would open them (.ai/... or the package doc path).
included_sources() {
    local entry resolved kind label list=""
    while IFS= read -r entry; do
        resolved="$(resolve_entry "$entry")"
        kind="$(printf '%s' "$resolved" | cut -f1)"
        case "$kind" in skip|missing) continue ;; esac
        label="$(printf '%s' "$resolved" | cut -f3)"
        case " $list " in *" \`$label\`,"*) continue ;; esac
        list="$list \`$label\`,"
    done < <(entries_of "$1")
    list="${list%,}"
    printf '%s' "${list# }"
}

write_pack() {
    local id="$1" when entry resolved kind file anchor label notes="" symbol symbol_entry rows="" tmp
    when="$(jq -r --arg id "$id" '.packs[] | select(.id == $id) | .when' "$PACKS_JSON")"
    tmp="$OUT/$id.md.tmp"
    while IFS="$(printf '\t')" read -r symbol symbol_entry; do
        [ -n "$symbol" ] || continue
        if symbol_documented "$symbol" "$symbol_entry"; then
            resolved="$(resolve_entry "$symbol_entry")"
            anchor="$(printf '%s' "$resolved" | cut -f2)"
            rows+="| \`$symbol\` | $(printf '%s' "$resolved" | cut -f3)${anchor:+#$anchor} |"$'\n'
        elif [ $? -eq 2 ]; then
            continue
        else
            rows+="| \`$symbol\` | not found in its source: verify it in the package before use |"$'\n'
        fi
    done < <(symbols_of "$id")
    {
        printf '# Pack: %s\n\n' "$id"
        printf '%s. Generated by `scripts/ai-packs.sh` from `.ai/packs.json`; do not edit.\n\n' "$when"
        printf 'Profile: %s.\n\n' "$(jq -r '.forks | to_entries | map("\(.key) \(.value)") | join(", ")' "$PROFILE_JSON")"
        printf 'This is everything this task needs besides AGENTS.md. Open a source file only when something is missing here, and say which in the report (`OPT-07`). Links are relative to the project root.\n\n'
        printf 'Already in this pack, so never open them again: %s.\n\n' "$(included_sources "$id")"
        if [ -n "$rows" ]; then
            printf '## Verified symbols\n\nUse these as documented in the section named. Anything else from a package: read its documentation first (API policy in AGENTS.md).\n\n| Symbol | Documented in |\n|---|---|\n%s\n' "$rows"
        fi
    } > "$tmp"
    while IFS= read -r entry; do
        resolved="$(resolve_entry "$entry")"
        kind="$(printf '%s' "$resolved" | cut -f1)"
        case "$kind" in
            skip) continue ;;
            missing) notes+="- \`$entry\`: $(printf '%s' "$resolved" | cut -f2)"$'\n'; continue ;;
        esac
        file="$kind"
        anchor="$(printf '%s' "$resolved" | cut -f2)"
        label="$(printf '%s' "$resolved" | cut -f3)"
        {
            printf '\n<!-- source: %s%s · cksum %s -->\n\n' "$label" "${anchor:+#$anchor}" "$(checksum "$file")"
            extract "$file" "$anchor" | transform "$(relative_dir "$file")" "$label"
        } >> "$tmp"
    done < <(entries_of "$id")
    if [ -n "$notes" ]; then
        printf '\n## Not included\n\nThese sources were not found. Read them yourself if the task needs them:\n\n%s' "$notes" >> "$tmp"
    fi
    mv "$tmp" "$OUT/$id.md"
}

# A pack larger than maxBytes doesn't fit in one read: the agent's file tool cuts it, and it reads it again in parts.
too_large() {
    local max
    max="$(jq -r '.maxBytes // 0' "$PACKS_JSON")"
    [ "$max" -gt 0 ] && [ "$(wc -c < "$1" | tr -d ' ')" -gt "$max" ]
}

write_index() {
    local id when lines
    {
        printf '# Task packs\n\nRead the pack of your task in one call (`OPT-07`). Generated by `scripts/ai-packs.sh`.\n\n| Pack | Lines | When |\n|---|---|---|\n'
        for id in $(pack_ids); do
            when="$(jq -r --arg id "$id" '.packs[] | select(.id == $id) | .when' "$PACKS_JSON")"
            lines="$(wc -l < "$OUT/$id.md" | tr -d ' ')"
            printf '| `Logs/ai/packs/%s.md` | %s | %s |\n' "$id" "$lines" "$when"
            too_large "$OUT/$id.md" && echo "ai-packs.sh: $id.md is larger than maxBytes; split it in packs.json." >&2
        done
    } > "$OUT/index.md"
}

print_index() {
    local id when lines
    printf '\nTask packs (read the one for your task in a single call, OPT-07):\n'
    for id in $(pack_ids); do
        [ -f "$OUT/$id.md" ] || continue
        when="$(jq -r --arg id "$id" '.packs[] | select(.id == $id) | .when' "$PACKS_JSON")"
        lines="$(wc -l < "$OUT/$id.md" | tr -d ' ')"
        printf -- '- Logs/ai/packs/%s.md (%s lines): %s\n' "$id" "$lines" "$when"
    done
}

generate() {
    [ -f "$PROFILE_JSON" ] || { echo "ai-packs.sh: no profile at $PROFILE_JSON. Run scripts/ai-profile.sh first." >&2; return 0; }
    local hash id
    hash="$(input_hash)"
    if [ "$FORCE" = false ] && [ "$(cat "$OUT/packs.hash" 2>/dev/null)" = "$hash" ]; then
        return 0
    fi
    mkdir -p "$OUT"
    for id in $(pack_ids); do
        write_pack "$id"
    done
    write_index
    echo "$hash" > "$OUT/packs.hash"
}

# --- Checking packs.json (maintainers) ------------------------------------------------------------------------------

check() {
    local failures=0 id entry path anchor fork file found branch capability symbol symbol_entry max lines tmp
    fail() { echo "FAIL  packs.json: $1"; failures=$((failures + 1)); }
    jq -e . "$PACKS_JSON" > /dev/null || { echo "FAIL  packs.json is not valid JSON"; return 1; }
    for id in $(pack_ids); do
        while IFS= read -r entry; do
            anchor=""; case "$entry" in *"#"*) anchor="${entry#*#}" ;; esac
            path="${entry%%#*}"
            case "$path" in
                fork:*)
                    fork="${path#fork:}"; file="${fork#*/}"; fork="${fork%%/*}"
                    jq -e --arg fork "$fork" '.forks[] | select(.id == $fork)' "$CAPABILITIES" > /dev/null || { fail "$id: unknown fork $fork"; continue; }
                    found=0
                    for branch in $(jq -r --arg fork "$fork" '.forks[] | select(.id == $fork) | .branches[] | sub("^[^:]*:"; "")' "$CAPABILITIES"); do
                        [ -f "architecture/branches/$branch/$file" ] || continue
                        found=1
                        [ -z "$anchor" ] || anchors_of "architecture/branches/$branch/$file" | grep -qx "$anchor" || fail "$id: no #$anchor in branches/$branch/$file"
                    done
                    [ "$found" = 1 ] || fail "$id: no branch of $fork has $file"
                    ;;
                package:*)
                    capability="${path#package:}"; capability="${capability%%/*}"
                    jq -e --arg id "$capability" '.capabilities[] | select(.id == $id)' "$CAPABILITIES" > /dev/null || fail "$id: unknown capability $capability"
                    ;;
                *)
                    [ -f "$path" ] || { fail "$id: $path not found"; continue; }
                    [ -z "$anchor" ] || anchors_of "$path" | grep -qx "$anchor" || fail "$id: no #$anchor in $path"
                    ;;
            esac
        done < <(entries_of "$id")
        while IFS="$(printf '\t')" read -r symbol symbol_entry; do
            [ -n "$symbol" ] || continue
            entries_of "$id" | grep -qxF "$symbol_entry" || fail "$id: symbol $symbol cites $symbol_entry, which isn't one of the pack's entries"
        done < <(symbols_of "$id")
    done
    # Every file that defines rules is in a pack, except the files always in context.
    for path in $(grep -rl '^| `[A-Z]*-[0-9]' architecture | sort); do
        jq -e --arg path "$path" '.alwaysInContext | index($path)' "$PACKS_JSON" > /dev/null && continue
        case "$path" in
            architecture/branches/*)
                file="${path#architecture/branches/*/}"
                jq -e --arg file "$file" '[.packs[].entries[] | select(startswith("fork:") and endswith("/" + $file))] | length > 0' "$PACKS_JSON" > /dev/null || fail "$path defines rules but no pack includes it"
                ;;
            *)
                jq -e --arg path "$path" '[.packs[].entries[] | select(. == $path or startswith($path + "#"))] | length > 0' "$PACKS_JSON" > /dev/null || fail "$path defines rules but no pack includes it"
                ;;
        esac
    done
    # Every pack fits, generated with every capability true and the first branch of each fork.
    max="$(jq -r '.maxLines' "$PACKS_JSON")"
    tmp="$(mktemp -d)"
    jq '{ capabilities: ([.capabilities[].id] | map({ (.): true }) | add), forks: ([.forks[] | { (.id): (.branches[0] | sub("^[^:]*:"; "")) }] | add) }' "$CAPABILITIES" > "$tmp/profile.json"
    (
        MODE=generate; FORCE=true; PROFILE_JSON="$tmp/profile.json"; OUT="$tmp/packs"; MANIFEST="$tmp/none.json"
        generate
    ) > /dev/null 2>&1
    for id in $(pack_ids); do
        lines="$(wc -l < "$tmp/packs/$id.md" 2>/dev/null | tr -d ' ')"
        [ -n "$lines" ] || { fail "$id: could not be generated"; continue; }
        [ "$lines" -le "$max" ] || fail "$id: $lines lines, more than maxLines $max"
        too_large "$tmp/packs/$id.md" && fail "$id: larger than maxBytes without its package documentation"
        grep -q '^> \*\*Fork `' "$tmp/packs/$id.md" && fail "$id: still has a fork block"
    done
    rm -rf "$tmp"
    if [ "$failures" -eq 0 ]; then
        echo "ok    packs.json: entries resolve, symbols cite their pack, every rule file is in a pack, sizes fit"
        return 0
    fi
    return 1
}

if [ "$MODE" = check ]; then
    check
    exit $?
fi
generate
[ "$INDEX" = true ] && print_index
exit 0
