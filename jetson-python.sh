#!/bin/bash
set -e

# ======================================================================
# jetson-python.sh
#
# Launch the fprime-python JetsonDeployment from build-artifacts/python.
# ======================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

PYTHON="$PROJECT_ROOT/fprime-venv/bin/python"
PYTHON_ARTIFACT_DIR="$PROJECT_ROOT/build-artifacts/python"
FSW_MAIN="$PYTHON_ARTIFACT_DIR/fsw_main.py"

ARENA_SDK_LIB="$PROJECT_ROOT/lib/ArenaSDK/lib"
ARENA_SDK_FFMPEG="$PROJECT_ROOT/lib/ArenaSDK/ffmpeg"
ARENA_SDK_GENICAM="$PROJECT_ROOT/lib/ArenaSDK/GenICam/library/lib/Linux64_ARM"

export LD_LIBRARY_PATH="$ARENA_SDK_LIB:$ARENA_SDK_FFMPEG:$ARENA_SDK_GENICAM:${LD_LIBRARY_PATH}"
export PYTHONPATH="$PYTHON_ARTIFACT_DIR:${PYTHONPATH}"

echo "========================================"
echo " JetsonDeployment fprime-python launcher"
echo " Project:   $PROJECT_ROOT"
echo " Python:    $PYTHON"
echo " Artifacts: $PYTHON_ARTIFACT_DIR"
echo " Main:      $FSW_MAIN"
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

mkdir -p "$PROJECT_ROOT/Images"

cd "$PYTHON_ARTIFACT_DIR"

echo "Launching fsw_main.py..."
exec "$PYTHON" "$FSW_MAIN"