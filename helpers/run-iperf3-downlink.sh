#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="$1"
UE_IP="$2"

DURATION="${DURATION:-60}"
IPERF_INTERVAL="${IPERF_INTERVAL:-0.1}"
IPERF_PORT="${IPERF_PORT:-5201}"

UE_CONTAINER="${UE_CONTAINER:-rfsim5g-oai-nr-ue1}"
EXTDN_CONTAINER="${EXTDN_CONTAINER:-oai-ext-dn}"

mkdir -p "$OUT_DIR"

SERVER_PID=""

cleanup() {
  if [ -n "$SERVER_PID" ] && kill -0 "$SERVER_PID" 2>/dev/null; then
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
  fi
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

SERVER_TIMEOUT="$((DURATION + 15))"

docker exec "$UE_CONTAINER" \
  timeout "$SERVER_TIMEOUT" \
  iperf3 -s -1 -p "$IPERF_PORT" --json \
  > "$OUT_DIR/iperf3_server.json" \
  2> "$OUT_DIR/iperf3_server.err" &

SERVER_PID=$!

sleep 1

if ! kill -0 "$SERVER_PID" 2>/dev/null; then
  wait "$SERVER_PID" 2>/dev/null || true
  echo "ERROR: iperf3 server stopped before the client started" >&2
  exit 1
fi

date +%s.%N > "$OUT_DIR/iperf_start_time.txt"

set +e

docker exec "$EXTDN_CONTAINER" \
  iperf3 -c "$UE_IP" -p "$IPERF_PORT" -t "$DURATION" -i "$IPERF_INTERVAL" --json \
  > "$OUT_DIR/iperf3_client.json" \
  2> "$OUT_DIR/iperf3_client.err"

CLIENT_EXIT_CODE=$?

set -e

date +%s.%N > "$OUT_DIR/iperf_end_time.txt"

if [ "$CLIENT_EXIT_CODE" -ne 0 ]; then
  echo "ERROR: iperf3 client failed with status $CLIENT_EXIT_CODE" >&2
  exit "$CLIENT_EXIT_CODE"
fi

set +e
wait "$SERVER_PID"
SERVER_EXIT_CODE=$?
set -e

SERVER_PID=""

if [ "$SERVER_EXIT_CODE" -ne 0 ]; then
  echo "ERROR: iperf3 server failed with status $SERVER_EXIT_CODE" >&2
  exit "$SERVER_EXIT_CODE"
fi

echo "iperf3 results saved in: $OUT_DIR"