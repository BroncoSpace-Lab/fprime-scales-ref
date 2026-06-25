#!/bin/bash
set -e

# ======================================================================
# jetson-python.sh
#
# Launch the fprime-python JetsonDeployment from build-artifacts/python.
#
# Default comm setup:
#   Jetson listens on 0.0.0.0:50000
#   GDS connects with:
#     fprime-gds ... --ip-client --ip-address <JETSON_IP> --ip-port 50000
# ======================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

PYTHON="$PROJECT_ROOT/fprime-venv/bin/python"
PYTHON_ARTIFACT_DIR="$PROJECT_ROOT/build-artifacts/python"
FSW_MAIN="$PYTHON_ARTIFACT_DIR/fsw_main.py"

ARENA_SDK_LIB="$PROJECT_ROOT/lib/ArenaSDK/lib"
ARENA_SDK_FFMPEG="$PROJECT_ROOT/lib/ArenaSDK/ffmpeg"
ARENA_SDK_GENICAM="$PROJECT_ROOT/lib/ArenaSDK/GenICam/library/lib/Linux64_ARM"

DEFAULT_HOSTNAME="0.0.0.0"
DEFAULT_PORT="50000"

export FPRIME_SCALES_ROOT="$PROJECT_ROOT"

export LD_LIBRARY_PATH="$ARENA_SDK_LIB:$ARENA_SDK_FFMPEG:$ARENA_SDK_GENICAM:${LD_LIBRARY_PATH:-}"

export PYTHONPATH="$PYTHON_ARTIFACT_DIR:$PROJECT_ROOT:$PROJECT_ROOT/Components/MLComponent:$PROJECT_ROOT/Components/MLComponent/Scales-ML/resnet:${PYTHONPATH:-}"

export PYTHONUNBUFFERED=1

mkdir -p "$PROJECT_ROOT/Images"

echo "========================================"
echo " JetsonDeployment fprime-python launcher"
echo " Project:   $PROJECT_ROOT"
echo " Python:    $PYTHON"
echo " Artifacts: $PYTHON_ARTIFACT_DIR"
echo " Main:      $FSW_MAIN"
echo " Default:   --hostname $DEFAULT_HOSTNAME --port $DEFAULT_PORT"
echo "========================================"
echo ""

if [ ! -x "$PYTHON" ]; then
    echo "ERROR: Python interpreter not found or not executable:"
    echo "  $PYTHON"
    exit 1
fi

if [ ! -d "$PYTHON_ARTIFACT_DIR" ]; then
    echo "ERROR: Python artifact directory not found:"
    echo "  $PYTHON_ARTIFACT_DIR"
    echo "Build first:"
    echo "  fprime-util build JetsonDeployment"
    exit 1
fi

if [ ! -f "$FSW_MAIN" ]; then
    echo "ERROR: fsw_main.py not found:"
    echo "  $FSW_MAIN"
    exit 1
fi

if ! ls "$PYTHON_ARTIFACT_DIR"/fprime_py*.so >/dev/null 2>&1; then
    echo "ERROR: generated fprime_py shared object not found in:"
    echo "  $PYTHON_ARTIFACT_DIR"
    exit 1
fi

cd "$PYTHON_ARTIFACT_DIR"

echo "Launching fsw_main.py..."

if [ "$#" -eq 0 ]; then
    exec stdbuf -oL -eL "$PYTHON" -u "$FSW_MAIN" \
        --hostname "$DEFAULT_HOSTNAME" \
        --port "$DEFAULT_PORT"
else
    exec stdbuf -oL -eL "$PYTHON" -u "$FSW_MAIN" "$@"
fi