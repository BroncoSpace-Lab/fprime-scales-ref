#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
IP_ADDRESS="${1:-10.3.2.10}"

cd "${SCRIPT_DIR}"
exec fprime-gds -n \
  --dictionary GDSDictionary.xml \
  --communication-selection ip \
  --framing-selection fprime \
  --ip-client \
  --ip-address "${IP_ADDRESS}" \
  --ip-port 50000 \
  --keepalive-interval 0
