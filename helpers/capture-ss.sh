#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="$1"
UE_IP="$2"

DURATION="${DURATION:-60}"
OBSERVATION_PADDING="${OBSERVATION_PADDING:-5}"
SS_INTERVAL="${SS_INTERVAL:-0.1}"

EXTDN_CONTAINER="${EXTDN_CONTAINER:-oai-ext-dn}"

OBSERVATION_DURATION="$((DURATION + OBSERVATION_PADDING))"

mkdir -p "$OUT_DIR"

set +e

docker exec "$EXTDN_CONTAINER" \
  timeout "$OBSERVATION_DURATION" \
  sh -c '
    ue_ip="$1"
    interval="$2"

    while true; do
      timestamp="$(date +%s.%N)"

      printf "timestamp_epoch=%s\n" "$timestamp"
      ss -tin dst "$ue_ip" || true
      printf "\n"

      sleep "$interval"
    done
  ' sh "$UE_IP" "$SS_INTERVAL" \
  > "$OUT_DIR/ss_tcp.log" \
  2> "$OUT_DIR/ss_tcp.err"

SS_EXIT_CODE=$?

set -e

if [ "$SS_EXIT_CODE" -ne 0 ] && [ "$SS_EXIT_CODE" -ne 124 ]; then
  echo "ERROR: ss observer failed with status $SS_EXIT_CODE" >&2
  exit "$SS_EXIT_CODE"
fi

echo "TCP observations saved in: $OUT_DIR/ss_tcp.log"