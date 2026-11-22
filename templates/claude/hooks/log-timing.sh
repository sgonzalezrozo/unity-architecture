#!/usr/bin/env bash
set -u

ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
INPUT="$(cat)"
LOG_DIR="$ROOT/Logs/agent-timing"

json_string() {
    local key="$1"
    local pattern="(^|[{,])[[:space:]]*\"$key\"[[:space:]]*:[[:space:]]*\"([^\"]*)\""
    if [[ "$INPUT" =~ $pattern ]]; then
        printf '%s' "${BASH_REMATCH[2]}"
    fi
}

json_number() {
    local key="$1"
    local pattern="(^|[{,])[[:space:]]*\"$key\"[[:space:]]*:[[:space:]]*([0-9]+)"
    if [[ "$INPUT" =~ $pattern ]]; then
        printf '%s' "${BASH_REMATCH[2]}"
    fi
}

field() {
    local value="$1"
    value="${value//$'\t'/ }"
    value="${value//$'\r'/ }"
    value="${value//$'\n'/ }"
    printf '%s' "$value"
}

SESSION_ID="$(json_string session_id)"
SESSION_ID="$(printf '%s' "$SESSION_ID" | tr -cd '[:alnum:]_-')"
[ -n "$SESSION_ID" ] || SESSION_ID="unknown"

EVENT="${TIMING_EVENT:-$(json_string hook_event_name)}"
PROMPT_ID="$(json_string prompt_id)"
TOOL_USE_ID="$(json_string tool_use_id)"
AGENT_ID="$(json_string agent_id)"
TOOL_NAME="${TIMING_TOOL_NAME:-$(json_string tool_name)}"
FILE_PATH="$(json_string file_path)"
[ -n "$FILE_PATH" ] || FILE_PATH="$(json_string filePath)"
[ -n "$FILE_PATH" ] || FILE_PATH="$(json_string skill)"
# Agents often read the rules with cat or sed through Bash. Record which rule documents a command names (only paths
# under .ai/ or .claude/skills/, never the rest of the command), so the report can tell what each step read.
if [ -z "$FILE_PATH" ] && [ "$TOOL_NAME" = Bash ]; then
    FILE_PATH="$(printf '%s' "$INPUT" | grep -oE '(\.ai|\.claude/skills)/[A-Za-z0-9_./~-]+\.md' | sort -u | paste -sd ';' -)"
fi
LOAD_REASON="$(json_string load_reason)"
DURATION_MS="${TIMING_DURATION_MS:-$(json_number duration_ms)}"
CONTEXT_TOKENS="$(json_number context_tokens)"
MODEL="$(json_string model)"
SOURCE="$(json_string source)"
AGENT_TYPE="$(json_string agent_type)"
TIMESTAMP="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

case "$FILE_PATH" in
    "$ROOT"/*) FILE_PATH="${FILE_PATH#"$ROOT"/}" ;;
    "$HOME"/*) FILE_PATH="~/${FILE_PATH#"$HOME"/}" ;;
    /*) FILE_PATH="<external>/$(basename "$FILE_PATH")" ;;
esac

mkdir -p "$LOG_DIR" || {
    echo "Could not create timing log directory: $LOG_DIR" >&2
    exit 1
}

LOG_FILE="$LOG_DIR/$SESSION_ID.tsv"
if [ ! -e "$LOG_FILE" ]; then
    if ! (set -o noclobber; printf 'timestamp\tevent\tprompt_id\ttool_use_id\tagent_id\ttool_name\tfile_path\tload_reason\tduration_ms\tcontext_tokens\tmodel\tsource\tagent_type\n' > "$LOG_FILE") 2>/dev/null; then
        [ -e "$LOG_FILE" ] || {
            echo "Could not create timing log: $LOG_FILE" >&2
            exit 1
        }
    fi
fi

printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$(field "$TIMESTAMP")" \
    "$(field "$EVENT")" \
    "$(field "$PROMPT_ID")" \
    "$(field "$TOOL_USE_ID")" \
    "$(field "$AGENT_ID")" \
    "$(field "$TOOL_NAME")" \
    "$(field "$FILE_PATH")" \
    "$(field "$LOAD_REASON")" \
    "$(field "$DURATION_MS")" \
    "$(field "$CONTEXT_TOKENS")" \
    "$(field "$MODEL")" \
    "$(field "$SOURCE")" \
    "$(field "$AGENT_TYPE")" >> "$LOG_FILE" || {
        echo "Could not append timing event to: $LOG_FILE" >&2
        exit 1
    }

# At the end of each prompt, show its stages and their seconds on screen (a Stop hook's systemMessage). Set
# AGENT_TIMING_SUMMARY=0 in the environment, or in .claude/settings.json "env", to turn it off.
REPORT="$ROOT/scripts/timing-report.sh"
if [ "$EVENT" = Stop ] && [ "${AGENT_TIMING_SUMMARY:-1}" != 0 ] && [ -x "$REPORT" ]; then
    SUMMARY="$(cd "$ROOT" && "$REPORT" --last "$LOG_FILE" 2>/dev/null)" || exit 0
    SUMMARY="${SUMMARY//\\/\\\\}"
    SUMMARY="${SUMMARY//\"/\\\"}"
    SUMMARY="${SUMMARY//$'\t'/ }"
    SUMMARY="${SUMMARY//$'\n'/\\n}"
    printf '{"systemMessage": "%s"}\n' "$SUMMARY"
fi
