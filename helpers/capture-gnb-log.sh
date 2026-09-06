#!/usr/bin/env bash
set -euo pipefail


OUT_DIR="$1"
GNB_LOG="$2"

DURATION="${DURATION:-60}"
OBSERVATION_PADDING="${OBSERVATION_PADDING:-5}"

OBSERVATION_DURATION="$((DURATION + OBSERVATION_PADDING))"

mkdir -p "$OUT_DIR"

printf '%s\n' "$GNB_LOG" > "$OUT_DIR/gnb_log_source.txt"
date +%s.%N > "$OUT_DIR/gnb_capture_start_time.txt"

set +e

timeout "$OBSERVATION_DURATION" stdbuf -oL tail -n 0 -F "$GNB_LOG" \
  > "$OUT_DIR/gnb.log" \
  2> "$OUT_DIR/gnb_capture.err"

CAPTURE_EXIT_CODE=$?

set -e

date +%s.%N > "$OUT_DIR/gnb_capture_end_time.txt"

if [ "$CAPTURE_EXIT_CODE" -ne 0 ] &&
   [ "$CAPTURE_EXIT_CODE" -ne 124 ]; then
  echo "ERROR: gNB log capture failed with status $CAPTURE_EXIT_CODE" >&2
  exit "$CAPTURE_EXIT_CODE"
fi

if [ ! -s "$OUT_DIR/gnb.log" ]; then
  echo "WARNING: no new gNB log lines were captured" >&2
fi

echo "gNB log saved in: $OUT_DIR/gnb.log"