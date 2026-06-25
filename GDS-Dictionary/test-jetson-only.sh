#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

IP_ADDRESS="10.3.2.12"
IP_PORT="50000"
DICTIONARY="${SCRIPT_DIR}/JetsonDeploymentTopologyDictionary.json"

cd "${SCRIPT_DIR}"

exec fprime-gds -n \
  --dictionary "${DICTIONARY}" \
  --communication-selection ip \
  --framing-selection fprime \
  --ip-client \
  --ip-address "${IP_ADDRESS}" \
  --ip-port "${IP_PORT}"