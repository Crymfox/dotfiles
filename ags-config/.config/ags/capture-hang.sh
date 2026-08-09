#!/usr/bin/env bash
# Capture diagnostics from a hanging AGS process.
# No gdb/ptrace needed - only reads /proc entries.
# Usage: ./capture-hang.sh [output-file]

OUT="${1:-/tmp/ags-hang-capture.txt}"
PID_FILE="/tmp/ags-capture-pid.txt"
echo "$$" > "$PID_FILE"

{
  echo "=== AGS Hang Capture ==="
  echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
  echo ""

  # Find Gjs PID first (the actual JS engine, not the CLI parent)
  PID=$(pgrep -f "gjs.*ags.js" | head -1)
  if [ -z "$PID" ]; then
    # Fallback: try the ags run parent
    PID=$(pgrep -f "ags run" | head -1)
  fi

  if [ -z "$PID" ]; then
    echo "ERROR: No AGS process found."
    exit 1
  fi

  echo "AGS PID: $PID"
  echo "Process state: $(cat /proc/$PID/status 2>/dev/null | grep -E "^State:" | head -1)"
  echo "Threads: $(cat /proc/$PID/status 2>/dev/null | grep -E "^Threads:" | head -1)"
  echo ""

  # Kernel stacks for each thread (zero overhead, always works)
  echo "=============================================="
  echo "Kernel stacks (all threads)"
  echo "=============================================="
  for tid in $(ls /proc/$PID/task/ 2>/dev/null); do
    comm=$(cat /proc/$PID/task/$tid/comm 2>/dev/null)
    echo "--- Thread $tid ($comm) ---"
    cat /proc/$PID/task/$tid/stack 2>/dev/null
    echo ""
  done

  # wchan - what the process is waiting on
  echo "=============================================="
  echo "wchan (what kernel function blocked on)"
  echo "=============================================="
  cat /proc/$PID/wchan 2>/dev/null
  echo ""

  # Open file descriptors
  echo "=============================================="
  echo "Open FDs (unix sockets, pipes)"
  echo "=============================================="
  ls -la /proc/$PID/fd/ 2>/dev/null | head -30

  # Memory maps related to libwayland, libgtk
  echo ""
  echo "=============================================="
  echo "Wayland/GTK state from maps"
  echo "=============================================="
  grep -E "libwayland|libgtk|libgdk" /proc/$PID/maps 2>/dev/null | head -10

  echo ""
  echo "=== End capture ==="
} > "$OUT"

echo "Saved to: $OUT"
echo "Also check: /tmp/ags.log"
