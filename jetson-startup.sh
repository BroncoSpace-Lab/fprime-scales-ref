#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

PYTHON="$PROJECT_ROOT/fprime-venv/bin/python"
PYTHON_ARTIFACT_DIR="$PROJECT_ROOT/build-artifacts/python"
FSW_MAIN="$PYTHON_ARTIFACT_DIR/fsw_main.py"

ARENA_SDK_LIB="$PROJECT_ROOT/lib/ArenaSDK/lib"
ARENA_SDK_FFMPEG="$PROJECT_ROOT/lib/ArenaSDK/ffmpeg"
ARENA_SDK_GENICAM="$PROJECT_ROOT/lib/ArenaSDK/GenICam/library/lib/Linux64_ARM"

export FPRIME_SCALES_ROOT="$PROJECT_ROOT"

export LD_LIBRARY_PATH="$ARENA_SDK_LIB:$ARENA_SDK_FFMPEG:$ARENA_SDK_GENICAM:${LD_LIBRARY_PATH}"

export PYTHONPATH="$PYTHON_ARTIFACT_DIR:$PROJECT_ROOT:$PROJECT_ROOT/Components/MLComponent:$PROJECT_ROOT/Components/MLComponent/Scales-ML:${PYTHONPATH}"

# GPU inference runs in a child process under ml-venv (Python 3.10 + NVIDIA's
# CUDA torch + JetPack TensorRT), created by `make jetson-setup`. F´ itself
# runs in fprime-venv (Python 3.12), for which no Jetson CUDA torch exists.
ML_VENV_PYTHON="$PROJECT_ROOT/ml-venv/bin/python"
if [ -x "$ML_VENV_PYTHON" ]; then
    export SCALES_TRT_PYTHON="${SCALES_TRT_PYTHON:-$ML_VENV_PYTHON}"
else
    echo "WARNING: $ML_VENV_PYTHON not found; ML inference will fail. Run 'make jetson-setup'."
fi
# Model weights are cached by `make jetson-setup`; never block on the network in flight.
export HF_HUB_OFFLINE="${HF_HUB_OFFLINE:-1}"
if [ -f "$HOME/.scales_trt_cache/yolov8n.pt" ]; then
    export SCALES_YOLO_WEIGHTS="${SCALES_YOLO_WEIGHTS:-$HOME/.scales_trt_cache/yolov8n.pt}"
fi


# Force Python and native stdout/stderr to appear immediately in systemd logs.
export PYTHONUNBUFFERED=1

mkdir -p "$PROJECT_ROOT/Images"

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

cd "$PYTHON_ARTIFACT_DIR"

echo "PWD=$(pwd)"
echo "FPRIME_SCALES_ROOT=$FPRIME_SCALES_ROOT"
echo "LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
echo "PYTHONPATH=$PYTHONPATH"
echo "Python version:"
"$PYTHON" --version
echo ""

echo "Launching fsw_main.py..."

# stdbuf makes C/C++ stdout/stderr line-buffered, which helps F Prime/native logs
# show up immediately in journalctl instead of being delayed.
exec stdbuf -oL -eL "$PYTHON" -u "$FSW_MAIN"

# To view the FSW live through systemd:
# journalctl -u jetson-deployment.service -f -l --no-pager