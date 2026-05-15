#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SERVER_DIR="$ROOT/tic-tac-toe/server"
CLIENT_DIR="$ROOT/tic-tac-toe/client"
PID_FILE="$SCRIPT_DIR/.rust-ttt.pid"
SERVER_BIN="$SERVER_DIR/target/debug/tic-tac-toe-server"

start() {
    if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "Already running (PID $(cat "$PID_FILE"))" >&2
        exit 1
    fi

    echo "Building client..."
    (cd "$CLIENT_DIR" && npm install --silent && npm run build)

    echo "Building server..."
    (cd "$SERVER_DIR" && cargo build)

    echo "Starting server..."
    (cd "$SERVER_DIR" && "$SERVER_BIN") &
    echo $! > "$PID_FILE"
    echo "Started (PID $(cat "$PID_FILE")). Open http://localhost:3000"
}

stop() {
    if [[ ! -f "$PID_FILE" ]]; then
        echo "Not running"
        return 0
    fi
    local pid
    pid=$(cat "$PID_FILE")
    if kill -0 "$pid" 2>/dev/null; then
        kill "$pid"
        echo "Stopped (PID $pid)"
    else
        echo "Not running (stale PID file)"
    fi
    rm -f "$PID_FILE"
}

case "${1:-start}" in
    start) start ;;
    stop) stop ;;
    *) echo "Usage: $0 {start|stop}" >&2; exit 1 ;;
esac
