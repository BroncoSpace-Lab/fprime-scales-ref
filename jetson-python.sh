#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${FPRIME_SCALES_ROOT:-$SCRIPT_DIR}"
VENV_PYTHON="${FPRIME_PYTHON:-$PROJECT_ROOT/fprime-venv/bin/python}"
ARTIFACT_DIR="$PROJECT_ROOT/build-artifacts/python"
FSW_MAIN="$ARTIFACT_DIR/fsw_main.py"

ARENA_SDK_LIB="$PROJECT_ROOT/lib/ArenaSDK/lib"
ARENA_SDK_FFMPEG="$PROJECT_ROOT/lib/ArenaSDK/ffmpeg"
ARENA_SDK_GENICAM="$PROJECT_ROOT/lib/ArenaSDK/GenICam/library/lib/Linux64_ARM"

export FPRIME_SCALES_ROOT="$PROJECT_ROOT"
export LD_LIBRARY_PATH="$ARENA_SDK_LIB:$ARENA_SDK_FFMPEG:$ARENA_SDK_GENICAM:${LD_LIBRARY_PATH:-}"
export PYTHONPATH="$ARTIFACT_DIR:$PROJECT_ROOT:$PROJECT_ROOT/Components/MLComponent:$PROJECT_ROOT/Components/MLComponent/Scales-ML/resnet:${PYTHONPATH:-}"
export PYTHONUNBUFFERED=1

DEFAULT_HOSTNAME="0.0.0.0"
DEFAULT_PORT="50000"

HOSTNAME="$DEFAULT_HOSTNAME"
PORT="$DEFAULT_PORT"

POSITIONAL_HOSTNAME_SET=0
POSITIONAL_PORT_SET=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --hostname)
      if [ "$#" -lt 2 ]; then
        echo "ERROR: --hostname requires a value"
        exit 1
      fi
      HOSTNAME="$2"
      shift 2
      ;;
    --port)
      if [ "$#" -lt 2 ]; then
        echo "ERROR: --port requires a value"
        exit 1
      fi
      PORT="$2"
      shift 2
      ;;
    --help|-h)
      echo "Usage:"
      echo "  $0"
      echo "  $0 <listen-hostname> <listen-port>"
      echo "  $0 --hostname <listen-hostname> --port <listen-port>"
      echo
      echo "Default listen endpoint: ${DEFAULT_HOSTNAME}:${DEFAULT_PORT}"
      exit 0
      ;;
    --*)
      echo "ERROR: unknown option: $1"
      echo "Run $0 --help for usage."
      exit 1
      ;;
    *)
      if [ "$POSITIONAL_HOSTNAME_SET" -eq 0 ]; then
        HOSTNAME="$1"
        POSITIONAL_HOSTNAME_SET=1
      elif [ "$POSITIONAL_PORT_SET" -eq 0 ]; then
        PORT="$1"
        POSITIONAL_PORT_SET=1
      else
        echo "ERROR: unexpected extra argument: $1"
        echo "Run $0 --help for usage."
        exit 1
      fi
      shift
      ;;
  esac
done

if ! [[ "$PORT" =~ ^[0-9]+$ ]]; then
  echo "ERROR: port must be numeric: $PORT"
  exit 1
fi

LAUNCH_ARGS=(--hostname "$HOSTNAME" --port "$PORT")

child_pid=""
cleaned_up=0

cleanup() {
  if [ "$cleaned_up" -eq 1 ]; then
    return
  fi
  cleaned_up=1

  echo
  echo "[INFO] Shutting down JetsonDeployment..."

  if [ -n "${child_pid}" ]; then
    kill -TERM "-${child_pid}" >/dev/null 2>&1 || true
    sleep 1
    kill -KILL "-${child_pid}" >/dev/null 2>&1 || true
  fi

  echo "[INFO] Shutdown complete"
}

trap cleanup INT TERM

echo "========================================"
echo " JetsonDeployment fprime-python launcher"
echo " Project:   $PROJECT_ROOT"
echo " Python:    $VENV_PYTHON"
echo " Artifacts: $ARTIFACT_DIR"
echo " Main:      $FSW_MAIN"
echo " Listen:    --hostname $HOSTNAME --port $PORT"
echo " Startup:   ${LAUNCH_ARGS[*]}"
echo "========================================"
echo

if [ ! -x "$VENV_PYTHON" ]; then
  echo "ERROR: Python interpreter not found or not executable:"
  echo "  $VENV_PYTHON"
  exit 1
fi

if [ ! -f "$FSW_MAIN" ]; then
  echo "ERROR: fsw_main.py not found:"
  echo "  $FSW_MAIN"
  echo "Build first on the Jetson:"
  echo "  fprime-util generate aarch64-linux -f"
  echo "  make build-jetson"
  exit 1
fi

if ! ls "$ARTIFACT_DIR"/fprime_py*.so >/dev/null 2>&1; then
  echo "ERROR: generated fprime_py shared object not found in:"
  echo "  $ARTIFACT_DIR"
  exit 1
fi

cd "$ARTIFACT_DIR"

echo "Checking TCP port $PORT..."
if ss -ltn 2>/dev/null | grep -q ":${PORT} "; then
  echo "ERROR: TCP port $PORT is already in use."
  echo "Clean it manually with:"
  echo "  sudo fuser -k ${PORT}/tcp"
  exit 1
fi

echo "Launching fsw_main.py..."

setsid stdbuf -oL -eL "$VENV_PYTHON" -u "$FSW_MAIN" "${LAUNCH_ARGS[@]}" &

child_pid="$!"

wait "$child_pid"
status=$?

cleanup

exit "$status"