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
set -euo pipefail

MODE=all
if [ "${1:-}" = --last ]; then
    MODE=last
    shift
fi
LOG="${1:-$(ls -t Logs/agent-timing/*.tsv 2>/dev/null | head -1)}"
[ -n "$LOG" ] && [ -f "$LOG" ] || { echo "No timing log found in Logs/agent-timing/." >&2; exit 1; }

# The last prompt starts at the last UserPromptSubmit row.
FIRST_ROW=2
if [ "$MODE" = last ]; then
    FIRST_ROW="$(awk -F'\t' '$2 == "UserPromptSubmit" { row = NR } END { print row ? row : 2 }' "$LOG")"
fi

awk -F'\t' -v first="$FIRST_ROW" -v mode="$MODE" '
function epoch(ts,   cmd, out) {
    cmd = "date -j -u -f %Y-%m-%dT%H:%M:%SZ " ts " +%s 2>/dev/null || date -u -d " ts " +%s"
    cmd | getline out; close(cmd); return out + 0
}
function label(tool, path) {
    if (tool == "Skill") return "Skill " path
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
NR < first { next }
{
    t = epoch($1)
    if (start == "") { start = t; done = t }
    if ($2 == "PostToolUse" || $2 == "PostToolUseFailure" || $2 == "Verification") {
        name = label($6, $7); took = t - done; done = t
        if (mode == "all") printf "%5ds  +%3ds  %s\n", t - start, took, name
        stage(name, took)
    } else if ($2 == "UserPromptSubmit") {
        if (mode == "all") printf "%5ds         --- prompt ---\n", t - start
        done = t
    } else if ($2 == "Stop") {
        took = t - done; done = t
        if (mode == "all") printf "%5ds  +%3ds  Final answer\n", t - start, took
        stage("Final answer", took)
    }
    last = t
}
END {
    total = last - start
    if (mode == "all") print ""
    printf "Timing: %dm %02ds\n", int(total / 60), total % 60
    for (i = 1; i <= count; i++) {
        suffix = calls[i] > 1 ? " (" calls[i] " calls)" : ""
        printf "%5ds  %s%s\n", seconds[i], names[i], suffix
    }
}' "$LOG"
