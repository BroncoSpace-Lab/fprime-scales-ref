#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="/home/jpl-jetson/fprime-scales-ref"
VENV_PYTHON="$PROJECT_ROOT/fprime-venv/bin/python"
ARTIFACT_DIR="$PROJECT_ROOT/build-artifacts/python"
FSW_MAIN="$ARTIFACT_DIR/fsw_main.py"

DEFAULT_HOSTNAME="0.0.0.0"
DEFAULT_PORT="50000"

PORT_TO_CLEAN="$DEFAULT_PORT"

args=("$@")
for ((i = 0; i < ${#args[@]}; i++)); do
  if [ "${args[$i]}" = "--port" ] && [ $((i + 1)) -lt ${#args[@]} ]; then
    PORT_TO_CLEAN="${args[$((i + 1))]}"
  fi
done

child_pid=""

cleanup() {
  echo
  echo "[INFO] Shutting down JetsonDeployment..."

  if [ -n "${child_pid}" ]; then
    # Kill the whole process group created by setsid.
    kill -TERM "-${child_pid}" >/dev/null 2>&1 || true
    sleep 1
    kill -KILL "-${child_pid}" >/dev/null 2>&1 || true
  fi

  # Clean the TCP port after shutdown.
  if command -v fuser >/dev/null 2>&1; then
    sudo fuser -k "${PORT_TO_CLEAN}/tcp" >/dev/null 2>&1 || true
  fi

  echo "[INFO] Shutdown complete"
}

trap cleanup INT TERM EXIT

echo "========================================"
echo " JetsonDeployment fprime-python launcher"
echo " Project:   $PROJECT_ROOT"
echo " Python:    $VENV_PYTHON"
echo " Artifacts: $ARTIFACT_DIR"
echo " Main:      $FSW_MAIN"
echo " Default:   --hostname $DEFAULT_HOSTNAME --port $DEFAULT_PORT"
echo " Cleanup:   killing anything on TCP port $PORT_TO_CLEAN"
echo "========================================"
echo

cd "$ARTIFACT_DIR"

echo "Cleaning TCP port $PORT_TO_CLEAN..."
if command -v fuser >/dev/null 2>&1; then
  sudo fuser -k "${PORT_TO_CLEAN}/tcp" >/dev/null 2>&1 || true
else
  echo "[WARNING] fuser not found; skipping automatic port cleanup"
fi

sleep 1

echo "Launching fsw_main.py..."

if [ "$#" -eq 0 ]; then
  setsid stdbuf -oL -eL "$VENV_PYTHON" -u "$FSW_MAIN" \
    --hostname "$DEFAULT_HOSTNAME" \
    --port "$DEFAULT_PORT" &
else
  setsid stdbuf -oL -eL "$VENV_PYTHON" -u "$FSW_MAIN" "$@" &
fi

child_pid="$!"

wait "$child_pid"