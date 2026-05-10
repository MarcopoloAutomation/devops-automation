#!/usr/bin/env bash
#log-watcher.sh - Watch a log file and send notifications
#License: MIT
#Author: Marek Lyszczarz
#Repo: devop-automation

set -euo pipefail

usage() {
    cat <<USAGE
Usage: $0 [OPTIONS] <logfile>

Options:
  -p <pattern>   Regex pattern to watch for  (default: ERROR)
  -t <title>     Notification title          (default: log-watcher)
  -n <lines>     Initial tail lines          (default: 0)
  -q             Quiet mode, notifications only
  -h             Show this help

Example:
  $0 -p "ERROR|WARN|FATAL" -n 20 /var/log/app.log
USAGE
}

PATTERN="ERROR"
TITLE="log-watcher"
TAIL_LINES=0
QUIET=false

while getopts ":p:t:n:qh" opt; do
    case "$opt" in
        p) PATTERN="$OPTARG" ;;
        t) TITLE="$OPTARG"   ;;
        n) TAIL_LINES="$OPTARG" ;;
        q) QUIET=true        ;;
        h) usage; exit 0     ;;
        :) echo "Error: -${OPTARG} requires an argument" >&2; exit 1 ;;
        *) usage; exit 1     ;;
    esac
done
shift $((OPTIND - 1))

[[ $# -ne 1 ]] && { usage; exit 1; }

LOGFILE="$1"

[[ ! -f "$LOGFILE" ]] && { echo "Error: file not found: $LOGFILE" >&2; exit 1; }

[[ "$TAIL_LINES" =~ ^[0-9]+$ ]] || { echo "Error: -n must be a non-negative integer" >&2; exit 1; }

notify() {
    local message="$1"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "$TITLE" "$message"
    fi
    [[ "$QUIET" == false ]] && printf '[%s] MATCH: %s\n' "$(date '+%H:%M:%S')" "$message"
}

[[ "$QUIET" == false ]] && printf 'Watching: %s | pattern: %s\n' "$LOGFILE" "$PATTERN"

tail -n "$TAIL_LINES" -F "$LOGFILE" 2>/dev/null \
    | grep --line-buffered -E "$PATTERN" \
    | while IFS= read -r line; do
        notify "$line"
    done
