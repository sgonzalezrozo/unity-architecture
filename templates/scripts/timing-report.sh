#!/usr/bin/env bash
# Turns a Claude Code timing log (Logs/agent-timing/{session}.tsv, written by .claude/hooks/log-timing.sh) into
# stages: consecutive steps of the same kind (reading MVC rules, writing a Model, compiling...) merged into one line
# with the seconds they took. A step's seconds run from the end of the step before it, so they include the time the
# model spent deciding on it, not only the tool's own run.
#
# Usage, from the project root:
#   scripts/timing-report.sh                       every prompt of the most recent session, step by step
#   scripts/timing-report.sh <session.tsv>         the same for a given log
#   scripts/timing-report.sh --last [session.tsv]  only the last prompt, as stages (what the Stop hook shows)
#   add --transcript <session.jsonl> to also show the models, API calls and tokens from the session's transcript
#   add --line for one short line (what the Stop hook shows on screen, where long messages are cut)
set -euo pipefail

MODE=all
TRANSCRIPT=""
LINE=false
while [ $# -gt 0 ]; do
    case "$1" in
        --last) MODE=last; shift ;;
        --transcript) TRANSCRIPT="${2:-}"; shift 2 ;;
        --line) LINE=true; shift ;;
        *) break ;;
    esac
done
LOG="${1:-$(ls -t Logs/agent-timing/*.tsv 2>/dev/null | head -1)}"
[ -n "$LOG" ] && [ -f "$LOG" ] || { echo "No timing log found in Logs/agent-timing/." >&2; exit 1; }

# The last turn starts at the first UserPromptSubmit after the Stop that ended the turn before it. A turn can log
# more than one UserPromptSubmit (a message sent while the agent works, a hook's feedback), so the last one isn't it.
FIRST_ROW=2
if [ "$MODE" = last ]; then
    FIRST_ROW="$(awk -F'\t' '
        $2 == "Stop" { previous = last; last = NR; ended = 1 }
        $2 != "Stop" && $2 != "Verification" && NR > 1 { ended = 0 }
        { kind[NR] = $2 }
        END {
            boundary = ended ? previous : last
            for (row = boundary + 1; row <= NR; row++)
                if (kind[row] == "UserPromptSubmit") { print row; exit }
            print 2
        }' "$LOG")"
fi

SUMMARY="$(awk -F'\t' -v first="$FIRST_ROW" -v mode="$MODE" '
function epoch(ts,   cmd, out) {
    cmd = "date -j -u -f %Y-%m-%dT%H:%M:%SZ " ts " +%s 2>/dev/null || date -u -d " ts " +%s"
    cmd | getline out; close(cmd); return out + 0
}
function label(tool, path,   n, paths, i, candidate) {
    if (tool == "Skill") return "Skill " path
    n = split(path, paths, ";")
    for (i = 1; i <= n; i++) {
        candidate = paths[i]
        if (candidate ~ /^write:/) {
            sub(/^write:/, "", candidate)
            path = candidate
            break
        }
        if (candidate ~ /^Logs\/ai\/packs\/.*\.md$/) {
            sub(/^Logs\/ai\/packs\//, "", candidate)
            sub(/\.md$/, "", candidate)
            return "Read pack " candidate
        }
    }
    for (i = 1; i <= n; i++) {
        if (paths[i] ~ /^pkg:.*\.cs$/) return "Read package source"
        if (paths[i] ~ /^pkg:/) return "Read package docs"
    }
    if (path ~ /\.ai\/AGENTS|AGENTS\.md|CLAUDE\.md/) return "Read the entry rules"
    if (path ~ /workflow\/planning|AGENT_WORKFLOW/) return "Read planning rules"
    if (path ~ /mvc\/|MVC\.md/) return "Read MVC rules"
    if (path ~ /fast-ioc|other-container|no-container|DEPENDENCY_INJECTION/) return "Read DI rules"
    if (path ~ /ui-scroller|ui\/lists/) return "Read list rules"
    if (path ~ /ui\/|UI_PATTERNS|ui-foundations/) return "Read UI rules"
    if (path ~ /FEATURE_STRUCTURE|PREFABS|prefab-handoff/) return "Read structure rules"
    if (path ~ /examples\//) return "Read examples"
    if (path ~ /csharp\/|CSHARP/) return "Read C# rules"
    if (path ~ /\.ai\//) return "Read other rules"
    if (path ~ /Installer\.cs$/) return "Write the installer"
    if (path ~ /Model\.cs$/) return "Write Models"
    if (path ~ /View\.cs$/) return "Write Views"
    if (path ~ /Controller\.cs$/) return "Write Controllers"
    if (path ~ /Tests\.cs$|\.asmdef$/) return "Write tests"
    if (path ~ /IMPLEMENTATION\.md$/) return "Write IMPLEMENTATION.md"
    if (path ~ /\.cs$|\.json$/) return "Write other code"
    if (path != "") return "Files"
    if (tool ~ /refresh_unity|read_console|verify/) return "Compile and check"
    if (tool ~ /run_tests|get_test_job/) return "Run tests"
    if (tool == "AskUserQuestion") return "Waiting for your answer"
    if (tool ~ /^mcp__ccd_/ || tool == "ToolSearch") return "App bookkeeping"
    if (tool == "Bash") return "Shell commands"
    if (tool ~ /^mcp__unityMCP__/) return "Unity Editor tools"
    return tool
}
# The first write of the task own files: anything under Assets/. Writing Logs/verify/test-scope or a scratch file is
# still part of planning.
function is_write(tool, path,   count, paths, i) {
    if (tool ~ /^(Write|Edit|NotebookEdit|MultiEdit)$/) return path ~ /^Assets\//
    count = split(path, paths, ";")
    for (i = 1; i <= count; i++) if (paths[i] ~ /^write:Assets\//) return 1
    return 0
}
function stage(name, took) {
    if (name == "App bookkeeping" && count > 0) {
        seconds[count] += took
        return
    }
    if (name == current) {
        seconds[count] += took; calls[count]++
        return
    }
    current = name; count++
    names[count] = name; seconds[count] = took; calls[count] = 1
}
# After the agent read a pack, a rule file under .ai/ or a package file is a read the packs did not cover (OPT-07).
function note_outside(path,   n, paths, i, found) {
    if (!packs_read) {
        if (path ~ /(^|;)Logs\/ai\/packs\/[^;]*\.md/) packs_read = 1
        return
    }
    n = split(path, paths, ";"); found = 0
    for (i = 1; i <= n; i++) {
        if (paths[i] ~ /^pkg:/ || (paths[i] ~ /^\.ai\/.*\.md$/)) {
            found = 1
            if (!(paths[i] in outside_seen)) { outside_seen[paths[i]] = 1; outside_list = outside_list (outside_list ? ", " : "") paths[i] }
        }
    }
    if (found) outside_calls++
}
NR < first { next }
{
    t = epoch($1)
    if (start == "") { start = t; done = t; prompt_start = t }
    if ($2 == "PostToolUse" || $2 == "PostToolUseFailure" || $2 == "Verification") {
        name = label($6, $7); took = t - done; done = t
        if (mode == "all") printf "%5ds  +%3ds  %s\n", t - start, took, name
        stage(name, took)
        if ($2 == "PostToolUse") note_outside($7)
        if ($2 == "PostToolUse" || $2 == "PostToolUseFailure") {
            if (!first_write_found) {
                if ($2 == "PostToolUse" && is_write($6, $7)) {
                    first_write_found = 1
                    before_write_seconds = t - prompt_start
                } else {
                    before_write_calls++
                    before_write_docs += $14 + 0
                }
            }
        }
    } else if ($2 == "UserPromptSubmit" && open_turn) {
        # A message or hook feedback inside a turn that has not stopped: the turn and its metrics go on.
        if (mode == "all") printf "%5ds         --- message during the turn ---\n", t - start
    } else if ($2 == "UserPromptSubmit") {
        if (mode == "all") printf "%5ds         --- prompt ---\n", t - start
        open_turn = 1
        done = t
        prompt_start = t
        first_write_found = 0
        before_write_seconds = 0
        before_write_calls = 0
        before_write_docs = 0
        packs_read = 0; outside_calls = 0; outside_list = ""; delete outside_seen
    } else if ($2 == "Stop") {
        open_turn = 0
        took = t - done; done = t
        if (mode == "all") printf "%5ds  +%3ds  Final answer\n", t - start, took
        stage("Final answer", took)
    }
    last = t
}
END {
    total = last - start
    if (mode == "all") print ""
    print "Turn summary"
    printf "  %-22s %dm %02ds\n", "Total", int(total / 60), total % 60
    if (first_write_found)
        printf "  %-22s %dm %02ds\n", "To the first file", int(before_write_seconds / 60), before_write_seconds % 60
    else
        printf "  %-22s %s\n", "To the first file", "not reached"
    printf "  %-22s %d\n", "Calls before writing", before_write_calls
    printf "  %-22s %d\n", "Rule docs read", before_write_docs
    if (packs_read) printf "  %-22s %d calls%s\n", "Outside packs", outside_calls, outside_list ? " (" outside_list ")" : ""
    print "Stages"
    for (i = 1; i <= count; i++) {
        suffix = calls[i] > 1 ? " (" calls[i] " calls)" : ""
        printf "  %4ds  %s%s\n", seconds[i], names[i], suffix
    }
    if (first_write_found) {
        printf "before-first-write: %dm%02ds, %d calls, %d rule docs\n", \
            int(before_write_seconds / 60), before_write_seconds % 60, before_write_calls, before_write_docs
    } else {
        printf "before-first-write: not reached, %d calls, %d rule docs\n", before_write_calls, before_write_docs
    }
    if (packs_read) printf "outside-packs: %d calls%s\n", outside_calls, outside_list ? " (" outside_list ")" : ""
}' "$LOG")"

# The models, API calls and tokens of the same turn, from the session transcript and its subagents' transcripts (one
# entry per streamed block, so messages are counted once by id). Only with jq and a transcript.
MODEL_LINES=""
if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ] && command -v jq > /dev/null 2>&1; then
    SINCE="$(awk -F'\t' -v row="$FIRST_ROW" 'NR == row { print $1 }' "$LOG")"
    TRANSCRIPTS=("$TRANSCRIPT")
    for subagent in "${TRANSCRIPT%.jsonl}"/subagents/*.jsonl; do
        [ -f "$subagent" ] && TRANSCRIPTS+=("$subagent")
    done
    # The cost is an estimate at the API list prices in .ai/model-prices.json (TIMING_PRICES to use another file).
    PRICES="${TIMING_PRICES:-.ai/model-prices.json}"
    PRICES_JSON="$(cat "$PRICES" 2>/dev/null || echo null)"
    MODEL_LINES="$(jq -rs --arg since "$SINCE" --argjson prices "$PRICES_JSON" '
        def usd: (. * 100 | round) as $c | "$\($c / 100 | floor).\($c % 100 | tostring | if length < 2 then "0" + . else . end)";
        def cost: .message as $m | ($m.usage) as $u | ($prices.models[$m.model] // null) as $r
            | if $prices == null or $r == null then null else
                (($u.input_tokens // 0) + ($u.cache_read_input_tokens // 0) + ($u.cache_creation_input_tokens // 0)) as $all
                | (if $r.longContext != null and $all > $r.longContext.aboveInputTokens then $r.longContext else $r end) as $q
                | ($u.cache_creation.ephemeral_1h_input_tokens // 0) as $write1h
                | ((($u.cache_creation_input_tokens // 0) - $write1h) | if . < 0 then 0 else . end) as $write5m
                | ((($u.input_tokens // 0) * $q.input) + (($u.cache_read_input_tokens // 0) * $q.cacheRead)
                   + ($write5m * $q.input * $prices.cacheWriteMultiplier["5m"]) + ($write1h * $q.input * $prices.cacheWriteMultiplier["1h"])
                   + (($u.output_tokens // 0) * $q.output)) / 1000000
              end;
        def short: if . >= 1000000 then "\(. / 100000 | floor / 10)M" elif . >= 1000 then "\(. / 100 | floor / 10)k" else "\(.)" end;
        [ .[] | select(.type == "assistant" and .message.usage != null)
              | select((.timestamp // "" | sub("\\.[0-9]+Z$"; "Z")) >= $since) ]
        | group_by(.message.id) | map(.[-1])
        | if length == 0 then empty else
            "  \("Model" | . + (" " * (22 - length))) \(group_by(.message.model) | map("\(.[0].message.model) (\(length) calls)") | join(", "))",
            "  \("API calls" | . + (" " * (22 - length))) \(length)",
            "  \("Tokens in / out" | . + (" " * (22 - length))) \(map(.message.usage | (.input_tokens // 0) + (.cache_read_input_tokens // 0) + (.cache_creation_input_tokens // 0)) | add | short) / \(map(.message.usage.output_tokens // 0) | add | short) (cache read \(map(.message.usage.cache_read_input_tokens // 0) | add | short))",
            ( group_by(.message.model) | map({ model: .[0].message.model, cost: (map(cost) | if any(. == null) then null else add end) }) ) as $byModel
            | if $prices == null then empty
              else "  \("Cost (list prices)" | . + (" " * (22 - length))) \($byModel | map(select(.cost != null) | .cost) | add // 0 | usd) (\($byModel | map(if .cost == null then "\(.model) unpriced" else "\(.model) \(.cost | usd)" end) | join(", ")))"
              end
          end' "${TRANSCRIPTS[@]}" 2>/dev/null || true)"
fi
if [ "$LINE" = true ]; then
    printf '%s\n%s\n' "$MODEL_LINES" "$SUMMARY" | awk '
        function value(line) { sub(/^  [^ ].{21} /, "", line); return line }
        /^  Model /                { model = value($0) }
        /^  Tokens in \/ out /     { tokens = value($0); sub(/ \(cache.*/, "", tokens) }
        /^  Total /                { total = value($0) }
        /^  To the first file /    { first = value($0) }
        /^  Calls before writing / { calls = value($0) }
        /^  Rule docs read /       { docs = value($0) }
        /^  Outside packs /        {
            outside = value($0); files = outside
            sub(/ calls.*/, "", outside)
            if (sub(/^[^(]*\(/, "", files)) {
                sub(/\)$/, "", files)
                n = split(files, list, /, /); names = ""
                for (i = 1; i <= n && i <= 3; i++) { name = list[i]; sub(/.*\//, "", name); names = names (i > 1 ? ", " : "") name }
                if (n > 3) names = names ", +" (n - 3)
                if (names != "") outside = outside " (" names ")"
            }
        }
        /^  Cost \(list prices\) /  { cost = value($0); sub(/ \(.*/, "", cost) }
        END {
            line = "Timing: " total " · first file " first " after " calls " calls (" docs " rule docs)"
            if (outside != "") line = line " · outside packs " outside
            if (model != "") line = line " · " model
            if (tokens != "") line = line " · tokens " tokens
            if (cost != "") line = line " · ~" cost
            print line " · details: scripts/timing-report.sh --last"
        }'
    exit 0
fi
printf '%s\n' "$SUMMARY" | awk '{ print } /^Turn summary$/ { exit }'
if [ -n "$MODEL_LINES" ]; then printf '%s\n' "$MODEL_LINES"; fi
printf '%s\n' "$SUMMARY" | awk 'found { print } /^Turn summary$/ { found = 1 }'
