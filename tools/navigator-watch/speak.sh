#!/usr/bin/env bash
# navigator-watch: Path B — voice → immediate injection into a cmux pane.
#
# Records audio, transcribes it locally, and sends the transcript straight into
# the target cmux pane (no idle-waiting — Claude Code's own input queueing
# handles "agent is mid-turn"; hit Escape yourself for a hard interrupt).
#
# Two modes:
#   start   begin recording to a temp wav, write recorder PID to a state file
#   stop    stop recording, transcribe, send transcript into the pane
#   toggle  start if idle, stop if recording  (convenient for a single hotkey)
#
# Bind these to a hotkey via Hammerspoon (see hammerspoon/init.lua).
#
# Requirements: bash, node (cmux.js), and:
#   - a recorder: `sox` (rec) or `ffmpeg`
#   - a transcriber: `whisper-cpp`/`whisper-cli`, `mlx_whisper`, or `whisper`
#
# Config via env or flags:
#   --surface <id>     cmux surface id                  (required)
#   --session <name>   cmux session name                (default: main)
#   --socket <path>    explicit cmux socket path        (default: derived)
#   --model <path>     whisper model path/name          (whisper.cpp needs a path)
#
# Example:
#   ./speak.sh --surface 4 toggle

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CMUX="node $HERE/cmux.js"

SURFACE=""
SESSION="main"
SOCKET=""
MODEL="${NAVIGATOR_WHISPER_MODEL:-}"
STATE_DIR="${TMPDIR:-/tmp}/navigator-speak"
WAV="$STATE_DIR/rec.wav"
PIDF="$STATE_DIR/rec.pid"
mkdir -p "$STATE_DIR"

MODE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --surface) SURFACE="$2"; shift 2;;
    --session) SESSION="$2"; shift 2;;
    --socket) SOCKET="$2"; shift 2;;
    --model) MODEL="$2"; shift 2;;
    start|stop|toggle) MODE="$1"; shift;;
    *) echo "unknown arg: $1" >&2; exit 2;;
  esac
done

cmux_args=(--session "$SESSION")
[[ -n "$SOCKET" ]] && cmux_args+=(--socket "$SOCKET")

is_recording() { [[ -f "$PIDF" ]] && kill -0 "$(cat "$PIDF")" 2>/dev/null; }

start_rec() {
  is_recording && { echo "already recording" >&2; return 0; }
  if command -v rec >/dev/null; then
    rec -q -c 1 -r 16000 "$WAV" >/dev/null 2>&1 &
  elif command -v ffmpeg >/dev/null; then
    # macOS avfoundation default mic; adjust device index if needed.
    ffmpeg -y -f avfoundation -i ":0" -ac 1 -ar 16000 "$WAV" >/dev/null 2>&1 &
  else
    echo "error: need 'sox' (rec) or 'ffmpeg' to record" >&2; exit 2
  fi
  echo $! > "$PIDF"
}

transcribe() {
  # Print transcript text to stdout. Try transcribers in order of preference.
  rm -f "$STATE_DIR/rec.txt"   # avoid reading a stale transcript if this run fails
  if command -v whisper-cli >/dev/null && [[ -n "$MODEL" ]]; then
    whisper-cli -m "$MODEL" -f "$WAV" -nt 2>/dev/null | tr '\n' ' '
  elif command -v whisper-cpp >/dev/null && [[ -n "$MODEL" ]]; then
    whisper-cpp -m "$MODEL" -f "$WAV" -nt 2>/dev/null | tr '\n' ' '
  elif command -v mlx_whisper >/dev/null; then
    mlx_whisper --output-format txt --output-dir "$STATE_DIR" "$WAV" >/dev/null 2>&1
    cat "$STATE_DIR/rec.txt" 2>/dev/null | tr '\n' ' '
  elif command -v whisper >/dev/null; then
    whisper "$WAV" --output_format txt --output_dir "$STATE_DIR" >/dev/null 2>&1
    cat "$STATE_DIR/rec.txt" 2>/dev/null | tr '\n' ' '
  else
    echo "error: no transcriber found (whisper-cli/whisper-cpp/mlx_whisper/whisper)" >&2
    exit 2
  fi
}

stop_rec() {
  is_recording || { echo "not recording" >&2; return 0; }
  # SIGINT (not TERM) so sox/ffmpeg finalize the WAV header/trailer cleanly.
  kill -INT "$(cat "$PIDF")" 2>/dev/null || true
  sleep 0.4
  rm -f "$PIDF"

  [[ -n "$SURFACE" ]] || { echo "error: --surface required to send" >&2; exit 2; }
  local text
  text="$(transcribe | sed 's/^ *//; s/ *$//')"
  [[ -z "$text" ]] && { echo "empty transcript, nothing sent" >&2; return 0; }
  # Paste (multi-line safe), then submit with a separate Enter.
  $CMUX "${cmux_args[@]}" send --surface "$SURFACE" --paste --text "$text"
  $CMUX "${cmux_args[@]}" send-key --surface "$SURFACE" --keys enter
  echo "sent: $text" >&2
}

case "$MODE" in
  start) start_rec;;
  stop) stop_rec;;
  toggle) if is_recording; then stop_rec; else start_rec; fi;;
  *) echo "usage: speak.sh [--surface id] start|stop|toggle" >&2; exit 2;;
esac
