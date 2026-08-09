#!/usr/bin/env bash
# Deadman watchdog for AGS.
# Monitors heartbeat log and restarts AGS if frozen.
# Designed to survive suspend/resume by using file mtime (no D-Bus).
set -o pipefail

LOG_FILE="/tmp/ags.log"
STALE_SEC=30
CHECK_INTERVAL=5

log() {
  echo "[ags-watchdog] $(date '+%H:%M:%S') $*"
}

cleanup() {
  if [ -n "$AGS_PID" ] && kill -0 "$AGS_PID" 2>/dev/null; then
    ags quit 2>/dev/null || kill "$AGS_PID" 2>/dev/null
    sleep 1
    kill -0 "$AGS_PID" 2>/dev/null && kill -9 "$AGS_PID" 2>/dev/null
  fi
  exit 0
}
trap cleanup EXIT INT TERM

while true; do
  # Ensure the log file exists so we can stat it
  touch "$LOG_FILE"

  log "Starting AGS"
  ags run --log-file "$LOG_FILE" &
  AGS_PID=$!

  last_restart=$(date +%s)

  while kill -0 "$AGS_PID" 2>/dev/null; do
    sleep "$CHECK_INTERVAL"

    # Check how long since the log was last written to
    mtime=$(stat -c %Y "$LOG_FILE" 2>/dev/null || echo "0")
    now=$(date +%s)
    age=$((now - mtime))

    if [ "$age" -gt "$STALE_SEC" ]; then
      log "Log stale for ${age}s — AGS frozen, restarting"
      ags quit 2>/dev/null || kill "$AGS_PID" 2>/dev/null
      sleep 2
      kill -0 "$AGS_PID" 2>/dev/null && kill -9 "$AGS_PID" 2>/dev/null
      break
    fi
  done

  log "AGS exited (PID $AGS_PID), restarting in 1s"
  sleep 1
done
