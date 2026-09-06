#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="$1"

UE_CONTAINER="${UE_CONTAINER:-rfsim5g-oai-nr-ue1}"
EXTDN_CONTAINER="${EXTDN_CONTAINER:-oai-ext-dn}"
UPF_CONTAINER="${UPF_CONTAINER:-oai-upf-slice1}"

mkdir -p "$OUT_DIR"

{
  echo "hostname=$(hostname)"
  echo "captured_at=$(date --iso-8601=seconds)"
  echo "ue_container=$UE_CONTAINER"
  echo "extdn_container=$EXTDN_CONTAINER"
  echo "upf_container=$UPF_CONTAINER"
} > "$OUT_DIR/metadata.txt"

pgrep -af 'nr-softmodem|nr-uesoftmodem|iperf3' \
  > "$OUT_DIR/processes.txt" \
  || true

docker exec "$UE_CONTAINER" \
  ip -4 addr show oaitun_ue1 \
  > "$OUT_DIR/ue_address.txt" 2>&1 \
  || true

docker exec "$UPF_CONTAINER" \
  ip -s link show tun0 \
  > "$OUT_DIR/upf_tun0.txt" 2>&1 \
  || true

docker exec "$UPF_CONTAINER" \
  tc -s qdisc show dev tun0 \
  > "$OUT_DIR/upf_tun0_qdisc.txt" 2>&1 \
  || true

echo "State captured in: $OUT_DIR"