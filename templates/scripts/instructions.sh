#!/usr/bin/env bash
# Sourced by install.sh. Where a file the install would write already exists and differs, the install asks what to do
# with it, one file at a time (ask_collision). instructions <destination relative to the project root> <template> writes
# an assistant's instruction file (AGENTS.md, CLAUDE.md, Copilot, Cursor, Rider):
#   add:     the rules go in a block between two markers at the end of the file, and a later install replaces only that
#            block. The file's text is kept.
#   replace: the file is backed up to <file>.bak and written from the template.
#   skip:    the file is left as it is.
# Without a terminal nothing is asked: a file that can take the block gets --add-instructions' default (add), unless
# --replace-instructions, and a static file (.editorconfig) is skipped. The arrays created, kept, added, replaced and
# customized are the install summary's, and install.sh declares them.
INSTRUCTIONS_MODE="${INSTRUCTIONS_MODE:-add}"
BLOCK_BEGIN='<!-- ai-agent-rules:begin: managed by .ai/templates/scripts/install.sh; write your own rules outside this block -->'
BLOCK_END='<!-- ai-agent-rules:end -->'

# ask_collision <path relative to the root> <can take the rules as a block: yes|no>. Sets COLLISION to add, replace or skip.
ask_collision() {
    local path="$1" can_block="$2" warning="${3:-}" answer
    if [ -t 0 ] && [ -t 1 ]; then
        echo
        echo "$path already exists and differs from the rules."
        [ -n "$warning" ] && echo "  Warning: $warning"
        if [ "$can_block" = yes ]; then
            printf '  [a] add the rules in a block (your text is kept)   [r] replace (backup as %s.bak)   [s] skip (default): ' "$path"
        else
            printf '  [r] replace (backup as %s.bak)   [s] skip (default): ' "$path"
        fi
        read -r answer
        case "$answer" in
            a|A) if [ "$can_block" = yes ]; then COLLISION=add; else COLLISION=skip; fi ;;
            r|R) COLLISION=replace ;;
            *) COLLISION=skip ;;
        esac
    elif [ "$can_block" = yes ]; then
        if [ "$INSTRUCTIONS_MODE" = replace ]; then COLLISION=replace; else COLLISION=add; fi
    else
        COLLISION=skip
    fi
}

instructions() {
    local dest="$ROOT/$1" template="$2" body_file
    body_file="$(mktemp)"
    cat "$template" > "$body_file"
    if [ ! -e "$dest" ]; then
        mkdir -p "$(dirname "$dest")"
        cp "$body_file" "$dest"
        created+=("$1")
    elif cmp -s "$body_file" "$dest"; then
        kept+=("$1")
    else
        ask_collision "$1" yes "Replacing removes everything in this file that isn't the rules, such as your project's own rules. The old file is kept as $1.bak. To keep your text and add the rules, choose [a]."
        if [ "$COLLISION" = replace ]; then
            cp "$dest" "$dest.bak"
            cp "$body_file" "$dest"
            replaced+=("$1 (previous kept as $1.bak)")
            rm -f "$body_file"
            return
        elif [ "$COLLISION" = skip ]; then
            customized+=("$1")
            rm -f "$body_file"
            return
        fi
        python3 - "$dest" "$BLOCK_BEGIN" "$BLOCK_END" "$body_file" <<'PYEOF'
import sys
path, begin, end, body_path = sys.argv[1:5]
text = open(path, encoding="utf-8").read()
body = open(body_path, encoding="utf-8").read().rstrip("\n")
block = f"{begin}\n{body}\n{end}"
if begin in text and end in text:
    head, rest = text.split(begin, 1)
    _, tail = rest.split(end, 1)
    new = head + block + tail
else:
    new = text.rstrip("\n") + "\n\n" + block + "\n"
open(path, "w", encoding="utf-8").write(new)
PYEOF
        added+=("$1")
    fi
    rm -f "$body_file"
}
