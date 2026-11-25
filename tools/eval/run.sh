#!/usr/bin/env bash
# Runs one request N times with Haiku, each in a fresh copy of the project, and keeps what matters for comparing runs:
# the plan, the files written, the checker, the compile, the tests run, the report sections, the reads and the cost.
# Each run gets a sandbox next to the project (the packages' relative paths resolve the same), deleted at the end
# unless --keep. Usage (from the project root):
#   bash .ai/tools/eval/run.sh <prompt-file> <answers-file> <runs> <out-dir> [--keep]
set -u
PROMPT="$1"; ANSWERS="$2"; RUNS="$3"; OUT="$4"; KEEP="${5:-}"
ROOT="$(pwd)"; PARENT="$(dirname "$ROOT")"; NAME="$(basename "$ROOT")"
MODEL="claude-haiku-5-5"
mkdir -p "$OUT"

for i in $(seq 1 "$RUNS"); do
    RUN_DIR="$OUT/run-$i"; rm -rf "$RUN_DIR"; mkdir -p "$RUN_DIR"
    SBX="$PARENT/$NAME-eval-$i"; rm -rf "$SBX"; mkdir -p "$SBX"
    rsync -a --exclude Library --exclude Temp --exclude Logs --exclude obj --exclude .git --exclude '.ai/.git' \
        --exclude Build --exclude UserSettings "$ROOT/" "$SBX/"
    (cd "$SBX" && git init -q && git add -A >/dev/null 2>&1 && git -c user.email=eval@local -c user.name=eval commit -qm baseline)
    (cd "$SBX" && bash scripts/ai-profile.sh >/dev/null 2>&1; bash scripts/ai-facts.sh; bash scripts/ai-packs.sh >/dev/null 2>&1)

    START=$(date +%s)
    # Stage 1: the request. Stage 2: answers to the questions the agent asks (scope, entry, plan approval).
    (cd "$SBX" && claude -p "$(cat "$PROMPT")" --model "$MODEL" --permission-mode auto --output-format json > "$RUN_DIR/stage1.json" 2> "$RUN_DIR/stage1.err")
    SID="$(python3 -c "import json,sys;print(json.load(open('$RUN_DIR/stage1.json')).get('session_id',''))" 2>/dev/null)"
    if [ -n "$SID" ] && [ -n "$ANSWERS" ]; then
        (cd "$SBX" && claude -p "$(cat "$ANSWERS")" --resume "$SID" --model "$MODEL" --permission-mode auto --output-format json > "$RUN_DIR/stage2.json" 2> "$RUN_DIR/stage2.err")
    fi
    echo "$(( $(date +%s) - START ))" > "$RUN_DIR/seconds.txt"

    # What the run left behind.
    cp "$SBX/Logs/ai/plan.md" "$RUN_DIR/plan.md" 2>/dev/null || true
    (cd "$SBX" && find Assets/Client -type f ! -name '*.meta' -newer "$SBX/.git/index" 2>/dev/null | sort > "$RUN_DIR/files.txt")
    (cd "$SBX" && git status --porcelain -- Assets | sort > "$RUN_DIR/git-status.txt")
    (cd "$SBX" && bash scripts/check-feature.sh Store > "$RUN_DIR/check.txt" 2>&1; echo "exit=$?" >> "$RUN_DIR/check.txt")
    cp "$SBX/Logs/verify/summary.json" "$RUN_DIR/verify-summary.json" 2>/dev/null || true
    TR="$HOME/.claude/projects/$(echo "$SBX" | sed 's|[/.]|-|g')"
    cat "$TR"/*.jsonl > "$RUN_DIR/transcript.jsonl" 2>/dev/null || true

    [ "$KEEP" = "--keep" ] || rm -rf "$SBX"
    echo "run $i done: $(cat "$RUN_DIR/seconds.txt")s -> $RUN_DIR"
done
