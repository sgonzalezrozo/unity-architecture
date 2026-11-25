#!/usr/bin/env bash
set -u

ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
ROOT="$(cd "$ROOT" && pwd -P)" || {
    echo "Could not resolve project directory: $ROOT" >&2
    exit 1
}
INPUT="$(cat)"
LOG_DIR="$ROOT/Logs/agent-timing"

HAS_JQ=false
command -v jq > /dev/null 2>&1 && HAS_JQ=true

# The first string value of a key anywhere in the hook input. jq when it's there: the pure-Bash fallback decodes one
# character at a time, which takes seconds on a large command such as a heredoc.
json_string() {
    local key="$1"
    if [ "$HAS_JQ" = true ]; then
        printf '%s' "$INPUT" | jq -r --arg key "$key" \
            'first(.. | objects | select(has($key)) | .[$key] | strings) // empty' 2>/dev/null
        return
    fi
    local pattern='(^|[{,])[[:space:]]*"'$key'"[[:space:]]*:[[:space:]]*"((\\.|[^"\\])*)"'
    if [[ "$INPUT" =~ $pattern ]]; then
        local raw="${BASH_REMATCH[2]}"
        local value=""
        local char escape
        while [ -n "$raw" ]; do
            char="${raw:0:1}"
            raw="${raw:1}"
            if [ "$char" = '\' ] && [ -n "$raw" ]; then
                escape="${raw:0:1}"
                raw="${raw:1}"
                case "$escape" in
                    '"') value+='"' ;;
                    '\') value+='\' ;;
                    '/') value+='/' ;;
                    n) value+=$'\n' ;;
                    r) value+=$'\r' ;;
                    t) value+=$'\t' ;;
                    *) value+="\\$escape" ;;
                esac
            else
                value+="$char"
            fi
        done
        printf '%s' "$value"
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
READ_COUNT=0
if [ "$TOOL_NAME" = Bash ]; then
    SHELL_COMMAND="$(json_string command)"
    PATH_TOKENS="$(printf '%s\n' "$SHELL_COMMAND" | awk '
        function clean(value,   name) {
            gsub(/^["\047(<]+|["\047);,]+$/, "", value)
            # Simple variables the command set earlier (D=Assets/Client/X; cat > $D/A.cs).
            for (name in vars) {
                gsub("\\$\\{" name "\\}", vars[name], value)
                gsub("\\$" name "/", vars[name] "/", value)
                if (value == "$" name) value = vars[name]
            }
            return value
        }
        function emit(kind, value) {
            if (seen[kind "\t" value]++) return
            print kind "\t" value
        }
        # A heredoc body is data (a script, a file being written), not part of the command: skip it.
        skipping != "" {
            line = $0
            sub(/^[[:space:]]+/, "", line)
            if (line == skipping) skipping = ""
            next
        }
        {
            count = split($0, tokens, /[[:space:]]+/)
            for (i = 1; i <= count; i++) {
                if (tokens[i] ~ /^<<-?/) {
                    delimiter = tokens[i]
                    sub(/^<<-?/, "", delimiter)
                    if (delimiter == "" && i < count) delimiter = tokens[++i]
                    gsub(/["\047]/, "", delimiter)
                    if (delimiter != "") pending = delimiter
                    continue
                }
                if (tokens[i] ~ /^[A-Za-z_][A-Za-z0-9_]*=[^=(]/) {
                    name = tokens[i]; sub(/=.*/, "", name)
                    value = tokens[i]; sub(/^[^=]*=/, "", value)
                    vars[name] = clean(value)
                    continue
                }
                token = clean(tokens[i])
                if (token == "cd" && i < count) {
                    print "cd\t" clean(tokens[++i])
                    continue
                }
                if (token == ">" || token == ">>") {
                    if (i < count) emit("write", clean(tokens[++i]))
                    continue
                }
                if (token ~ /^>{1,2}[^>]/) {
                    sub(/^>{1,2}/, "", token)
                    emit("write", token)
                    continue
                }
                if (token == "tee") {
                    j = i + 1
                    while (j <= count && tokens[j] ~ /^-/) j++
                    if (j <= count) emit("write", clean(tokens[j]))
                    continue
                }
                if (token ~ /^-/) continue
                if (token ~ /\.(md|cs)$/) emit("read", token)
            }
            if (pending != "") { skipping = pending; pending = "" }
        }')"
    # Bash keeps its directory between calls, so a relative path starts from the cwd the hook reports. Paths are
    # followed as absolute paths, so a cd out of the project (into a local package) is still understood.
    CURRENT_ABS="$ROOT"
    HOOK_CWD="$(json_string cwd)"
    if [ -n "$HOOK_CWD" ]; then
        CURRENT_ABS="$(cd "$HOOK_CWD" 2>/dev/null && pwd -P)" || CURRENT_ABS="$ROOT"
    fi
    DOC_PATHS=""
    PACKAGE_PATHS=""
    WRITE_PATHS=""
    absolute_directory() {
        local path="$1" base="$2"
        [[ "$path" = /* ]] || path="$base/$path"
        (cd "$path" 2>/dev/null && pwd -P)
    }
    absolute_file() {
        local path="$1" base="$2" directory
        [[ "$path" = /* ]] || path="$base/$path"
        directory="$(cd "$(dirname "$path")" 2>/dev/null && pwd -P)" || return 1
        printf '%s/%s' "$directory" "$(basename "$path")"
    }
    # A path inside the project, relative to it; a package file as pkg:<package>/<path in it>; nothing else.
    classify() {
        local path="$1" rest
        case "$path" in
            "$ROOT"/*) printf '%s' "${path#"$ROOT"/}"; return 0 ;;
            */Library/PackageCache/*@*/*)
                rest="${path#*/Library/PackageCache/}"
                printf 'pkg:%s/%s' "${rest%%@*}" "${rest#*/}"; return 0 ;;
            */Packages/*/*)
                rest="${path##*/Packages/}"
                printf 'pkg:%s' "$rest"; return 0 ;;
        esac
        return 1
    }
    while IFS="$(printf '\t')" read -r kind path; do
        [ -n "$path" ] || continue
        case "$kind" in
            cd)
                CURRENT_ABS="$(absolute_directory "$path" "$CURRENT_ABS" || absolute_directory "$path" "$ROOT")" ||
                    CURRENT_ABS="/nonexistent"
                ;;
            read)
                resolved="$(absolute_file "$path" "$CURRENT_ABS")" || continue
                resolved="$(classify "$resolved")" || continue
                case "$resolved" in
                    .ai/*.md|Logs/ai/packs/*.md|.claude/*.md) DOC_PATHS+="$resolved"$'\n' ;;
                    pkg:*) PACKAGE_PATHS+="$resolved"$'\n' ;;
                esac
                ;;
            write)
                resolved="$(absolute_file "$path" "$CURRENT_ABS")" || continue
                resolved="$(classify "$resolved")" || continue
                case "$resolved" in pkg:*) continue ;; esac
                WRITE_PATHS+="write:$resolved"$'\n'
                ;;
        esac
    done <<< "$PATH_TOKENS"
    if [ -n "$DOC_PATHS" ]; then
        DOC_PATHS="$(printf '%s' "$DOC_PATHS" | sort -u)"
        READ_COUNT="$(printf '%s\n' "$DOC_PATHS" | wc -l | tr -d '[:space:]')"
    fi
    [ -z "$PACKAGE_PATHS" ] || PACKAGE_PATHS="$(printf '%s' "$PACKAGE_PATHS" | sort -u)"
    if [ -n "$DOC_PATHS$PACKAGE_PATHS$WRITE_PATHS" ]; then
        FILE_PATH="$(printf '%s\n%s\n%s\n' "$DOC_PATHS" "$PACKAGE_PATHS" "$WRITE_PATHS" | sed '/^$/d' | paste -sd ';' -)"
    fi
elif [ "$TOOL_NAME" = Read ]; then
    if [[ "$FILE_PATH" = /* ]]; then
        READ_DIRECTORY="$(cd "$(dirname "$FILE_PATH")" 2>/dev/null && pwd -P)" || READ_DIRECTORY=""
        if [ -n "$READ_DIRECTORY" ]; then
            case "$READ_DIRECTORY/" in
                "$ROOT/"*)
                    if [ "$READ_DIRECTORY" = "$ROOT" ]; then
                        FILE_PATH="$(basename "$FILE_PATH")"
                    else
                        FILE_PATH="${READ_DIRECTORY#"$ROOT"/}/$(basename "$FILE_PATH")"
                    fi
                    ;;
                */Library/PackageCache/*@*/*)
                    READ_REST="${READ_DIRECTORY#*/Library/PackageCache/}/$(basename "$FILE_PATH")"
                    FILE_PATH="pkg:${READ_REST%%@*}/${READ_REST#*/}"
                    ;;
                */Packages/*/*)
                    FILE_PATH="pkg:${READ_DIRECTORY##*/Packages/}/$(basename "$FILE_PATH")"
                    ;;
            esac
        fi
    fi
    case "$FILE_PATH" in
        .ai/*.md|Logs/ai/packs/*.md|.claude/*.md) READ_COUNT=1 ;;
    esac
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

# The start of a turn, for the Stop hook's feature check (it checks only what changed after it). A message sent during
# the turn keeps the first mark; verify-on-stop removes it when the turn ends.
if [ "$EVENT" = UserPromptSubmit ] && [ -d "$ROOT/Logs" ]; then
    mkdir -p "$ROOT/Logs/verify"
    [ -e "$ROOT/Logs/verify/turn-$SESSION_ID" ] || date +%s > "$ROOT/Logs/verify/turn-$SESSION_ID"
fi

LOG_FILE="$LOG_DIR/$SESSION_ID.tsv"
if [ ! -e "$LOG_FILE" ]; then
    if ! (set -o noclobber; printf 'timestamp\tevent\tprompt_id\ttool_use_id\tagent_id\ttool_name\tfile_path\tload_reason\tduration_ms\tcontext_tokens\tmodel\tsource\tagent_type\tread_count\n' > "$LOG_FILE") 2>/dev/null; then
        [ -e "$LOG_FILE" ] || {
            echo "Could not create timing log: $LOG_FILE" >&2
            exit 1
        }
    fi
fi

printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
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
    "$(field "$AGENT_TYPE")" \
    "$(field "$READ_COUNT")" >> "$LOG_FILE" || {
        echo "Could not append timing event to: $LOG_FILE" >&2
        exit 1
    }

# At the end of each prompt, show one line with its times, models and tokens on screen (a Stop hook's systemMessage;
# the app cuts long messages). scripts/timing-report.sh --last prints the stages. Set
# AGENT_TIMING_SUMMARY=0 in the environment, or in .claude/settings.json "env", to turn it off.
REPORT="$ROOT/scripts/timing-report.sh"
if [ "$EVENT" = Stop ] && [ "${AGENT_TIMING_SUMMARY:-1}" != 0 ] && [ -x "$REPORT" ]; then
    TRANSCRIPT="$(json_string transcript_path)"
    SUMMARY="$(cd "$ROOT" && "$REPORT" --last --line ${TRANSCRIPT:+--transcript "$TRANSCRIPT"} "$LOG_FILE" 2>/dev/null)" || exit 0
    SUMMARY="${SUMMARY//\\/\\\\}"
    SUMMARY="${SUMMARY//\"/\\\"}"
    SUMMARY="${SUMMARY//$'\t'/ }"
    SUMMARY="${SUMMARY//$'\n'/\\n}"
    printf '{"systemMessage": "%s"}\n' "$SUMMARY"
fi
