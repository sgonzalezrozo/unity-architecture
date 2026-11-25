#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOGGER="$ROOT/templates/claude/hooks/log-timing.sh"
REPORT="$ROOT/templates/scripts/timing-report.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

PROJECT="$TMP/project"
mkdir -p "$PROJECT/.ai/architecture/mvc" "$PROJECT/Logs/ai/packs" "$PROJECT/Assets/Client/Test" "$PROJECT/scripts"
cp "$REPORT" "$PROJECT/scripts/timing-report.sh"
chmod +x "$PROJECT/scripts/timing-report.sh"

log_event() {
    printf '%s\n' "$1" | CLAUDE_PROJECT_DIR="$PROJECT" AGENT_TIMING_SUMMARY=0 "$LOGGER"
}

log_event '{"session_id":"timing-test","hook_event_name":"PostToolUse","tool_name":"Bash","command":"cd \".ai/architecture\" && cat \"mvc/views.md\""}'
log_event "{\"session_id\":\"timing-test\",\"hook_event_name\":\"PostToolUse\",\"tool_name\":\"Bash\",\"command\":\"cat $PROJECT/.ai/architecture/mvc/models.md\"}"
log_event '{"session_id":"timing-test","hook_event_name":"PostToolUse","tool_name":"Bash","command":"cat > Assets/Client/Test/Thing.cs <<EOF"}'
log_event "{\"session_id\":\"timing-test\",\"hook_event_name\":\"PostToolUse\",\"tool_name\":\"Read\",\"file_path\":\"$PROJECT/.ai/architecture/mvc/controllers.md\"}"

LOG="$PROJECT/Logs/agent-timing/timing-test.tsv"
awk -F '\t' '
    NR == 1 && ($14 != "read_count" || NF != 14) { exit 1 }
    NR == 2 && ($6 != "Bash" || $7 != ".ai/architecture/mvc/views.md" || $14 != 1) { exit 1 }
    NR == 3 && ($7 != ".ai/architecture/mvc/models.md" || $14 != 1) { exit 1 }
    NR == 4 && ($7 != "write:Assets/Client/Test/Thing.cs" || $14 != 0) { exit 1 }
    NR == 5 && ($6 != "Read" || $7 != ".ai/architecture/mvc/controllers.md" || $14 != 1) { exit 1 }
    END { if (NR != 5) exit 1 }
' "$LOG" || {
    echo "Timing logger did not attribute the sample reads and write correctly." >&2
    exit 1
}

# Bash keeps its directory between calls: a relative read starts from the cwd the hook reports.
log_event "{\"session_id\":\"edge\",\"hook_event_name\":\"PostToolUse\",\"tool_name\":\"Bash\",\"cwd\":\"$PROJECT/.ai/architecture\",\"tool_input\":{\"command\":\"cat mvc/views.md\"}}"
# A heredoc body is data: a comparison in a script isn't a write, and a .md named in it isn't a read.
log_event '{"session_id":"edge","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"python3 - <<EOF\nif a > b: print(1)\nprint(\"see AGENTS.md\")\nEOF"}}'
# A large heredoc stays fast and is logged once, as its destination.
BIG_BODY="$(awk 'BEGIN { for (i = 0; i < 900; i++) printf "x = 1 if a > b else 2\\n" }')"
EDGE_START="$(date +%s)"
log_event "{\"session_id\":\"edge\",\"hook_event_name\":\"PostToolUse\",\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"cat > Assets/Client/Test/Big.cs <<EOF\\n${BIG_BODY}EOF\"}}"
EDGE_SECONDS=$(( $(date +%s) - EDGE_START ))

awk -F '\t' '
    NR == 2 && ($7 != ".ai/architecture/mvc/views.md" || $14 != 1) { exit 1 }
    NR == 3 && ($7 != "" || $14 != 0) { exit 1 }
    NR == 4 && $7 != "write:Assets/Client/Test/Big.cs" { exit 1 }
    END { if (NR != 4) exit 1 }
' "$PROJECT/Logs/agent-timing/edge.tsv" || {
    echo "Timing logger mishandled the cwd, a heredoc body or a large heredoc:" >&2
    cat "$PROJECT/Logs/agent-timing/edge.tsv" >&2
    exit 1
}
[ "$EDGE_SECONDS" -le 2 ] || {
    echo "Timing logger took ${EDGE_SECONDS}s on a large heredoc (limit 2s)." >&2
    exit 1
}

FIXTURE="$TMP/report.tsv"
{
    printf '%s\n' \
        $'timestamp\tevent\tprompt_id\ttool_use_id\tagent_id\ttool_name\tfile_path\tload_reason\tduration_ms\tcontext_tokens\tmodel\tsource\tagent_type\tread_count' \
        $'2026-01-01T00:00:00Z\tUserPromptSubmit\t\t\t\t\t\t\t\t\t\t\t\t'
    printf '%s\t%s\t\t%s\t\t%s\t%s\t\t\t\t\t\t\t%s\n' \
        '2026-01-01T00:00:10Z' PostToolUse p1 Bash .ai/architecture/mvc/views.md 1 \
        '2026-01-01T00:00:20Z' PostToolUse p2 Bash Logs/ai/packs/new-feature.md 1 \
        '2026-01-01T00:00:30Z' PostToolUse p3 Read .ai/architecture/mvc/models.md 1 \
        '2026-01-01T00:01:00Z' PostToolUse p4 Bash write:Assets/Client/Test/Thing.cs 0
    printf '%s\n' $'2026-01-01T00:01:05Z\tStop\t\t\t\t\t\t\t\t\t\t\t\t'
} > "$FIXTURE"

SUMMARY="$("$REPORT" --last "$FIXTURE")"
grep -Fq 'Read pack new-feature' <<< "$SUMMARY"
grep -Fq 'Write other code' <<< "$SUMMARY"
grep -Fq 'before-first-write: 1m00s, 3 calls, 3 rule docs' <<< "$SUMMARY" || {
    echo "Timing report did not produce the expected before-first-write metric:" >&2
    printf '%s\n' "$SUMMARY" >&2
    exit 1
}

OLD_FIXTURE="$TMP/report-old.tsv"
awk -F '\t' 'BEGIN { OFS = "\t" } { if (NF > 13) NF = 13; print }' "$FIXTURE" > "$OLD_FIXTURE"
OLD_SUMMARY="$("$REPORT" --last "$OLD_FIXTURE")"
grep -Fq 'before-first-write: 1m00s, 3 calls, 0 rule docs' <<< "$OLD_SUMMARY" || {
    echo "Timing report did not accept a pre-read_count timing log." >&2
    printf '%s\n' "$OLD_SUMMARY" >&2
    exit 1
}

# A second UserPromptSubmit inside a turn (a message sent while the agent works) doesn't start a new turn.
MID_FIXTURE="$TMP/report-mid.tsv"
{
    printf '%s\n' \
        $'timestamp\tevent\tprompt_id\ttool_use_id\tagent_id\ttool_name\tfile_path\tload_reason\tduration_ms\tcontext_tokens\tmodel\tsource\tagent_type\tread_count' \
        $'2026-01-01T00:00:00Z\tUserPromptSubmit\t\t\t\t\t\t\t\t\t\t\t\t' \
        $'2026-01-01T00:00:10Z\tPostToolUse\t\tp1\t\tBash\t.ai/architecture/mvc/views.md\t\t\t\t\t\t\t1' \
        $'2026-01-01T00:00:20Z\tUserPromptSubmit\t\t\t\t\t\t\t\t\t\t\t\t' \
        $'2026-01-01T00:00:30Z\tPostToolUse\t\tp2\t\tBash\twrite:Assets/Client/Test/Thing.cs\t\t\t\t\t\t\t0' \
        $'2026-01-01T00:00:40Z\tStop\t\t\t\t\t\t\t\t\t\t\t\t'
} > "$MID_FIXTURE"
MID_SUMMARY="$("$REPORT" --last "$MID_FIXTURE")"
grep -Fq 'Total                  0m 40s' <<< "$MID_SUMMARY" && grep -Fq 'before-first-write: 0m30s, 1 calls, 1 rule docs' <<< "$MID_SUMMARY" || {
    echo "Timing report split a turn at a message sent during it:" >&2
    printf '%s\n' "$MID_SUMMARY" >&2
    exit 1
}

# A write through a variable resolves; a write to Logs/ is still planning, not the first write.
log_event '{"session_id":"vars","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"printf x > Logs/verify/test-scope\nD=Assets/Client/Test\ncat > $D/A.cs <<EOF\nx\nEOF"}}'
grep -Fq 'write:Assets/Client/Test/A.cs' "$PROJECT/Logs/agent-timing/vars.tsv" || {
    echo "Timing logger did not resolve a write through a shell variable." >&2
    exit 1
}
PLAN_FIXTURE="$TMP/report-plan.tsv"
{
    printf '%s\n' \
        $'timestamp\tevent\tprompt_id\ttool_use_id\tagent_id\ttool_name\tfile_path\tload_reason\tduration_ms\tcontext_tokens\tmodel\tsource\tagent_type\tread_count' \
        $'2026-01-01T00:00:00Z\tUserPromptSubmit\t\t\t\t\t\t\t\t\t\t\t\t' \
        $'2026-01-01T00:00:10Z\tPostToolUse\t\tp1\t\tBash\twrite:Logs/verify/test-scope\t\t\t\t\t\t\t0' \
        $'2026-01-01T00:00:30Z\tPostToolUse\t\tp2\t\tWrite\tAssets/Client/Test/A.cs\t\t\t\t\t\t\t0' \
        $'2026-01-01T00:00:40Z\tStop\t\t\t\t\t\t\t\t\t\t\t\t'
} > "$PLAN_FIXTURE"
grep -Fq 'before-first-write: 0m30s, 1 calls, 0 rule docs' <<< "$("$REPORT" --last "$PLAN_FIXTURE")" || {
    echo "Timing report counted a write outside Assets/ as the first write." >&2
    exit 1
}

# After a pack, package files and rule files are reads the packs did not cover; package reads outside the project
# are logged as pkg:<package>/<path>.
OUTSIDE_FIXTURE="$TMP/report-outside.tsv"
{
    printf '%s\n' \
        $'timestamp\tevent\tprompt_id\ttool_use_id\tagent_id\ttool_name\tfile_path\tload_reason\tduration_ms\tcontext_tokens\tmodel\tsource\tagent_type\tread_count' \
        $'2026-01-01T00:00:00Z\tUserPromptSubmit\t\t\t\t\t\t\t\t\t\t\t\t' \
        $'2026-01-01T00:00:05Z\tPostToolUse\t\tp1\t\tRead\tLogs/ai/packs/ui-list.md\t\t\t\t\t\t\t1' \
        $'2026-01-01T00:00:10Z\tPostToolUse\t\tp2\t\tBash\tpkg:unity-ui-scroller/Runtime/SectionedSource.cs\t\t\t\t\t\t\t0' \
        $'2026-01-01T00:00:15Z\tPostToolUse\t\tp3\t\tBash\t.ai/architecture/examples/03_FILTERED_LIST_INVENTORY.md\t\t\t\t\t\t\t1' \
        $'2026-01-01T00:00:20Z\tStop\t\t\t\t\t\t\t\t\t\t\t\t'
} > "$OUTSIDE_FIXTURE"
OUTSIDE_SUMMARY="$("$REPORT" --last "$OUTSIDE_FIXTURE")"
grep -Fq 'Read package source' <<< "$OUTSIDE_SUMMARY" &&
grep -Fq 'outside-packs: 2 calls (pkg:unity-ui-scroller/Runtime/SectionedSource.cs, .ai/architecture/examples/03_FILTERED_LIST_INVENTORY.md)' <<< "$OUTSIDE_SUMMARY" || {
    echo "Timing report did not flag the reads outside the packs:" >&2
    printf '%s\n' "$OUTSIDE_SUMMARY" >&2
    exit 1
}
PACKAGE_ROOT="$TMP/Packages/unity-ui-scroller/Runtime"
mkdir -p "$PACKAGE_ROOT" && touch "$PACKAGE_ROOT/ISlot.cs"
log_event "{\"session_id\":\"pkg\",\"hook_event_name\":\"PostToolUse\",\"tool_name\":\"Bash\",\"cwd\":\"$PROJECT\",\"tool_input\":{\"command\":\"cd $TMP; S=Packages/unity-ui-scroller/Runtime; grep -n public \$S/ISlot.cs\"}}"
grep -Fq 'pkg:unity-ui-scroller/Runtime/ISlot.cs' "$PROJECT/Logs/agent-timing/pkg.tsv" || {
    echo "Timing logger did not record a package read outside the project." >&2
    exit 1
}

# The summary names the models, API calls and tokens of the turn, from the transcript and a subagent's transcript.
TRANSCRIPT="$TMP/session.jsonl"
mkdir -p "$TMP/session/subagents"
{
    printf '%s\n' '{"type":"assistant","timestamp":"2025-12-31T23:59:59.000Z","message":{"id":"old","model":"claude-opus-5-5","usage":{"input_tokens":1,"output_tokens":1}}}'
    printf '%s\n' '{"type":"assistant","timestamp":"2026-01-01T00:00:05.500Z","message":{"id":"m1","model":"claude-opus-5-5","usage":{"input_tokens":10,"cache_read_input_tokens":1500,"output_tokens":20}}}'
    printf '%s\n' '{"type":"assistant","timestamp":"2026-01-01T00:00:05.900Z","message":{"id":"m1","model":"claude-opus-5-5","usage":{"input_tokens":10,"cache_read_input_tokens":1500,"output_tokens":20}}}'
} > "$TRANSCRIPT"
printf '%s\n' '{"type":"assistant","timestamp":"2026-01-01T00:00:12.000Z","message":{"id":"s1","model":"claude-haiku-5-5","usage":{"input_tokens":500,"output_tokens":40}}}' > "$TMP/session/subagents/agent-1.jsonl"
MODEL_SUMMARY="$("$REPORT" --last --transcript "$TRANSCRIPT" "$OUTSIDE_FIXTURE")"
grep -Fq 'Model                  claude-haiku-5-5 (1 calls), claude-opus-5-5 (1 calls)' <<< "$MODEL_SUMMARY" &&
grep -Fq 'API calls              2' <<< "$MODEL_SUMMARY" &&
grep -Fq 'Tokens in / out        2k / 60 (cache read 1.5k)' <<< "$MODEL_SUMMARY" || {
    echo "Timing report did not summarize the models and tokens of the turn:" >&2
    printf '%s\n' "$MODEL_SUMMARY" >&2
    exit 1
}
[ "$(head -1 <<< "$MODEL_SUMMARY")" = "Turn summary" ] && sed -n 2p <<< "$MODEL_SUMMARY" | grep -q 'Model' || {
    echo "Timing report did not put the model right under Turn summary." >&2
    exit 1
}
# The Stop hook shows that summary on screen, with the transcript the event names.
cp "$OUTSIDE_FIXTURE" "$PROJECT/Logs/agent-timing/stop.tsv"
STOP_OUTPUT="$(printf '{"session_id":"stop","hook_event_name":"Stop","transcript_path":"%s"}' "$TRANSCRIPT" | CLAUDE_PROJECT_DIR="$PROJECT" "$LOGGER")"
jq -e '.systemMessage | test("^Timing: [0-9]+m [0-9]+s · first file not reached after 3 calls \\(2 rule docs\\) · outside packs 2 \\(SectionedSource.cs, 03_FILTERED_LIST_INVENTORY.md\\) · claude-haiku-5-5 \\(1 calls\\), claude-opus-5-5 \\(1 calls\\) · tokens 2k / 60 · details: ")' <<< "$STOP_OUTPUT" > /dev/null &&
jq -e '.systemMessage | test("\n") | not' <<< "$STOP_OUTPUT" > /dev/null || {
    echo "The Stop hook did not show the one-line summary with the models:" >&2
    printf '%s\n' "$STOP_OUTPUT" >&2
    exit 1
}

# The cost uses the list prices: a 1-hour cache write at 2x, Haiku's long-context rate above 100K input tokens, and an
# unknown model left unpriced.
COST_TRANSCRIPT="$TMP/cost.jsonl"
mkdir -p "$TMP/cost/subagents"
{
    printf '%s\n' '{"type":"assistant","timestamp":"2026-01-01T00:00:06.000Z","message":{"id":"c1","model":"claude-opus-5-5","usage":{"input_tokens":100000,"output_tokens":10000,"cache_creation_input_tokens":10000,"cache_creation":{"ephemeral_1h_input_tokens":10000,"ephemeral_5m_input_tokens":0}}}}'
    printf '%s\n' '{"type":"assistant","timestamp":"2026-01-01T00:00:07.000Z","message":{"id":"c2","model":"claude-haiku-5-5","usage":{"input_tokens":200000,"output_tokens":1000}}}'
    printf '%s\n' '{"type":"assistant","timestamp":"2026-01-01T00:00:08.000Z","message":{"id":"c3","model":"claude-future-9","usage":{"input_tokens":5,"output_tokens":5}}}'
} > "$COST_TRANSCRIPT"
COST_SUMMARY="$(TIMING_PRICES="$ROOT/model-prices.json" "$REPORT" --last --transcript "$COST_TRANSCRIPT" "$OUTSIDE_FIXTURE")"
grep -Fq 'Cost (list prices)     $0.78 (claude-future-9 unpriced, claude-haiku-5-5 $0.10, claude-opus-5-5 $0.68)' <<< "$COST_SUMMARY" || {
    echo "Timing report did not price the turn at the list prices:" >&2
    printf '%s\n' "$COST_SUMMARY" >&2
    exit 1
}
grep -Fq '~$0.78 · details' <<< "$(TIMING_PRICES="$ROOT/model-prices.json" "$REPORT" --last --line --transcript "$COST_TRANSCRIPT" "$OUTSIDE_FIXTURE")" || {
    echo "The one-line summary does not show the cost." >&2
    exit 1
}

echo "Timing tests passed."
