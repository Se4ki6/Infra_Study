#!/usr/bin/env bash
set -euo pipefail

pid_file=.otel-order-api.pid

if [[ -f "$pid_file" ]]; then
    old_pid=$(cat "$pid_file")
    if kill -0 "$old_pid" 2>/dev/null; then
        echo "API already running with PID $old_pid" >&2
        exit 1
    fi
    rm -f "$pid_file"
fi

setsid "$@" &
api_pid=$!
echo "$api_pid" > "$pid_file"

cleanup() {
    kill -TERM -- "-$api_pid" 2>/dev/null || true
    wait "$api_pid" 2>/dev/null || true
    if [[ "$(cat "$pid_file" 2>/dev/null || true)" == "$api_pid" ]]; then
        rm -f "$pid_file"
    fi
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
wait "$api_pid"
