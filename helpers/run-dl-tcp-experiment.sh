#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <gnb-log-path>" >&2
  exit 2
fi

GNB_LOG="$1"

DURATION="${DURATION:-60}"
IPERF_INTERVAL="${IPERF_INTERVAL:-0.1}"
IPERF_PORT="${IPERF_PORT:-5201}"
SS_INTERVAL="${SS_INTERVAL:-0.1}"
OBSERVATION_PADDING="${OBSERVATION_PADDING:-5}"

UE_CONTAINER="${UE_CONTAINER:-rfsim5g-oai-nr-ue1}"
EXTDN_CONTAINER="${EXTDN_CONTAINER:-oai-ext-dn}"
UPF_CONTAINER="${UPF_CONTAINER:-oai-upf-slice1}"
UE_INTERFACE="${UE_INTERFACE:-oaitun_ue1}"

ROOT="${ROOT:-/mydata/experiment_runs}"
LABEL="${LABEL:-dl_tcp_$(date +%Y%m%d_%H%M%S)}"
RUN_DIR="$ROOT/$LABEL"

HELPERS_DIR="$(
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &&
  pwd
)"

SS_PID=""
GNB_CAPTURE_PID=""

cleanup() {
  local exit_code=$?
  local pid

  for pid in "$SS_PID" "$GNB_CAPTURE_PID"; do
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || true
      wait "$pid" 2>/dev/null || true
    fi
  done

  return "$exit_code"
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

if [ ! -r "$GNB_LOG" ]; then
  echo "ERROR: gNB log is not readable: $GNB_LOG" >&2
  exit 1
fi

UE_IP="$(
  docker exec "$UE_CONTAINER" \
    ip -4 -o addr show dev "$UE_INTERFACE" 2>/dev/null |
    awk '{
      split($4, address, "/")
      print address[1]
      exit
    }' ||
    true
)"

if [ -z "$UE_IP" ]; then
  echo "ERROR: could not discover the UE IP" >&2
  exit 1
fi

mkdir -p "$RUN_DIR"

{
  echo "status=running"
  echo "hostname=$(hostname)"
  echo "started_at=$(date --iso-8601=seconds)"
  echo "duration=$DURATION"
  echo "iperf_interval=$IPERF_INTERVAL"
  echo "iperf_port=$IPERF_PORT"
  echo "ss_interval=$SS_INTERVAL"
  echo "observation_padding=$OBSERVATION_PADDING"
  echo "ue_ip=$UE_IP"
  echo "ue_container=$UE_CONTAINER"
  echo "extdn_container=$EXTDN_CONTAINER"
  echo "upf_container=$UPF_CONTAINER"
  echo "gnb_log_source=$GNB_LOG"
} > "$RUN_DIR/metadata.txt"

UE_CONTAINER="$UE_CONTAINER" \
EXTDN_CONTAINER="$EXTDN_CONTAINER" \
UPF_CONTAINER="$UPF_CONTAINER" \
  "$HELPERS_DIR/capture-state.sh" \
  "$RUN_DIR/state_before"

DURATION="$DURATION" \
OBSERVATION_PADDING="$OBSERVATION_PADDING" \
SS_INTERVAL="$SS_INTERVAL" \
EXTDN_CONTAINER="$EXTDN_CONTAINER" \
  "$HELPERS_DIR/capture-ss.sh" \
  "$RUN_DIR/tcp" \
  "$UE_IP" \
  > "$RUN_DIR/capture_ss.out" \
  2> "$RUN_DIR/capture_ss.err" &

SS_PID=$!

DURATION="$DURATION" \
OBSERVATION_PADDING="$OBSERVATION_PADDING" \
  "$HELPERS_DIR/capture-gnb-log.sh" \
  "$RUN_DIR/gnb" \
  "$GNB_LOG" \
  > "$RUN_DIR/capture_gnb.out" \
  2> "$RUN_DIR/capture_gnb.err" &

GNB_CAPTURE_PID=$!

sleep 1

set +e

DURATION="$DURATION" \
IPERF_INTERVAL="$IPERF_INTERVAL" \
IPERF_PORT="$IPERF_PORT" \
UE_CONTAINER="$UE_CONTAINER" \
EXTDN_CONTAINER="$EXTDN_CONTAINER" \
  "$HELPERS_DIR/run-iperf3-downlink.sh" \
  "$RUN_DIR/iperf3" \
  "$UE_IP" \
  > "$RUN_DIR/run_iperf3.out" \
  2> "$RUN_DIR/run_iperf3.err"

IPERF_EXIT_CODE=$?

wait "$SS_PID"
SS_EXIT_CODE=$?
SS_PID=""

wait "$GNB_CAPTURE_PID"
GNB_CAPTURE_EXIT_CODE=$?
GNB_CAPTURE_PID=""

set -e

set +e

UE_CONTAINER="$UE_CONTAINER" \
EXTDN_CONTAINER="$EXTDN_CONTAINER" \
UPF_CONTAINER="$UPF_CONTAINER" \
  "$HELPERS_DIR/capture-state.sh" \
  "$RUN_DIR/state_after"

STATE_AFTER_EXIT_CODE=$?

set -e

if [ "$IPERF_EXIT_CODE" -eq 0 ] &&
   [ "$SS_EXIT_CODE" -eq 0 ] &&
   [ "$GNB_CAPTURE_EXIT_CODE" -eq 0 ] &&
   [ "$STATE_AFTER_EXIT_CODE" -eq 0 ]; then
  STATUS="complete"
else
  STATUS="failed"
fi

{
  echo "status=$STATUS"
  echo "finished_at=$(date --iso-8601=seconds)"
  echo "iperf_exit_code=$IPERF_EXIT_CODE"
  echo "ss_exit_code=$SS_EXIT_CODE"
  echo "gnb_capture_exit_code=$GNB_CAPTURE_EXIT_CODE"
  echo "state_after_exit_code=$STATE_AFTER_EXIT_CODE"
} > "$RUN_DIR/result.txt"

echo "Experiment status: $STATUS"
echo "Experiment directory: $RUN_DIR"

if [ "$STATUS" != "complete" ]; then
  exit 1
fi