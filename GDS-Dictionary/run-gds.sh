#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

IP_ADDRESS="${1:-10.3.2.10}"
IP_PORT="${2:-50000}"
DICTIONARY="${SCRIPT_DIR}/GDSDictionary.json"

cd "${SCRIPT_DIR}"

exec fprime-gds -n \
  --dictionary "${DICTIONARY}" \
  --communication-selection ip \
  --framing-selection space-packet-space-data-link \
  --scid 0x44 \
  --vcid 1 \
  --frame-size 1024 \
  --ip-client \
  --ip-address "${IP_ADDRESS}" \
  --ip-port "${IP_PORT}" \
  --keepalive-interval 0

