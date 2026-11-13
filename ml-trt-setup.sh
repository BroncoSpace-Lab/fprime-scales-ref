#!/usr/bin/env bash

# Hi its luca, im trying to write this myself. Kill me.
# This is a one time setup script that builds a TensorRT engine for a single model, 
# in this case its resnet (default) or YOLO. Default is ResNet, or YOLO can be selected
# Checks that you are the same user that jetson-deployment.service runs as
# Checks that the Jetson's system Python has tensorrt, GPU enabled torch, numpy, 
# Pillow and the exporter for the model (transformers for ResNet and ultralytics for YOLO)
# Exports the model to ONNX and then compiles it into a TensorRT engine saved in ~/.scales_trt_cache
# Runs a test inference on test-imagery/ to prove the engine works.
# After a JetPack/TensorRT update or a model change, delete ~/.scales_trt_cache first; existing engines are reused, not rebuilt.

# Run on the Jetson as the jetson-deployment service user. Don't use sudo.
# make ml-trt-setup builds resnet
# make ml-trt-setup MODEL=yolo builds YOLO

set -euo pipefail # Strict mode: -e stop on any failed command, -u error on unset variables, -o pipefail fail a pipe if any part fails.

# helper function(s)
die() { #function called die that prints an error message and stops the whole script with an error code 
    echo "ERROR: $*" >&2; # $* means all the arguments, >&2 sends the output to std error. Every program has this standard
    exit 1; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" # Sets the absolute path of the folder containing this script (the repo root)
ML="$ROOT/Components/MLComponent/Scales-ML"

MODEL="${MODEL:-resnet}" # Set shell variable MODEL to MODEL, if it isnt set use default resnet
# Python that runs TensorRT: SCALES_TRT_PYTHON if set, else the ml-venv made by
# `make jetson-setup` (Python 3.10 + NVIDIA's CUDA torch + JetPack TensorRT),
# else JetPack's system Python.
if [ -n "${SCALES_TRT_PYTHON:-}" ]; then
    PY="$SCALES_TRT_PYTHON"
elif [ -x "$ROOT/ml-venv/bin/python" ]; then
    PY="$ROOT/ml-venv/bin/python"
else
    PY=/usr/bin/python3
fi
export SCALES_TRT_PYTHON="$PY"   # Export SCALES_TRT_PYTHON as a global variable to the Shell Variable PY; # pass the same Python to programs this script starts
export TRT_FP16="${TRT_FP16:-1}" # Engine precision: 1 = FP16 (default), 0 = FP32. Read by the Python worker, remember export passes to child processes
export TRT_BUILD_HEARTBEAT_S="${TRT_BUILD_HEARTBEAT_S:-60}"

case "$MODEL" in
    resnet)
        NAME="${SCALES_TRT_MODEL:-microsoft/resnet-18}"
        EXPORT_DEP="transformers"
        ;;
    yolo)
        NAME="${SCALES_YOLO_WEIGHTS:-yolov8n.pt}"
        EXPORT_DEP="ultralytics"
        if [ -f "$NAME" ]; then # checks if $NAME exists, -f checks if it is a file since $NAME expands to one
            NAME="$(realpath "$NAME")"; #sets NAME equal to the return output of the realpath of $NAME
        fi
        ;;
    *)
        die "MODEL must be 'resnet' or 'yolo' (got '$MODEL')"
        # die message outputting whats allowed and what was the input
        ;;
esac #end of case like if and fi

SERVICE="jetson-deployment.service"
if [ "$(systemctl show -p LoadState --value "$SERVICE" 2>/dev/null)" = "loaded" ]; then
    SERVICE_USER="$(systemctl show -p User --value "$SERVICE")"
    SERVICE_USER="${SERVICE_USER:-root}"
    if [ "$SERVICE_USER" != "$(id -un)" ]; then
        die "$SERVICE runs as '$SERVICE_USER' but you are '$(id -un)'. Run as '$SERVICE_USER' without sudo."
    fi
fi

# check if the directory exists and was pulled
[ -d "$ML/scales_trt" ] || die "Scales-ML not found at $ML (run: git submodule update --init)" # -d means is a directory, || if -d returns false, or with die "..."

# checks if python is installed in the system
command -v "$PY" >/dev/null || die "$PY not found. Run 'make jetson-setup' first."

# checks if the prefix is the venv version of python3 or the actual system version
PY_PREFIX="$("$PY" -c 'import sys; print(sys.prefix)')"
[ "$PY_PREFIX" != "$ROOT/fprime-venv" ] || die "$PY is F Prime's fprime-venv, which can't load TensorRT. Use JetPack's system Python (/usr/bin/python3)."

# checks pip dependencies for tensorrt torch numpy and PIL
for mod in tensorrt torch numpy PIL "$EXPORT_DEP"; do
    "$PY" -c "import $mod" 2>/dev/null || die "'$mod' is not importable by $PY"
done

# let user know that CUDA deps are not installed, torch must be able to use the GPU
"$PY" -c "import torch, sys; sys.exit(0 if torch.cuda.is_available() else 1)" \
    || die "torch in $PY cannot use the GPU. Run 'make jetson-setup' (installs JetPack, cuDSS and NVIDIA's Jetson torch into ml-venv)."

# Let Python find scales_trt/, resnet/ and yolo/ inside Scales-ML.
# :+ appends ":<old value>" only if PYTHONPATH already had one.
export PYTHONPATH="$ML${PYTHONPATH:+:$PYTHONPATH}"

# Work inside the engine cache so downloads and exports (e.g. yolov8n.pt,
# the .onnx file) land there instead of in the repo.
CACHE="$HOME/.scales_trt_cache"
mkdir -p "$CACHE"
cd "$CACHE"

# Build the engine: export the model to ONNX, then compile it with TensorRT.
# Any step whose output already exists in the cache is skipped.
# Precision comes from TRT_FP16 (the worker ignores its --fp16 flag).
echo "=== Building TensorRT engine: $MODEL ($NAME), FP16=$TRT_FP16 ==="
echo "This can take several minutes (YOLO: 10+)."
"$PY" -m scales_trt.worker prepare --adapter "$MODEL.inference.trt_adapter" --model "$NAME"

# Smoke test: run the same entry point F Prime calls, on the sample images.
# If it fails, set -e stops the script before the "Done" message.
echo "=== Test run on $ROOT/test-imagery ==="
"$PY" -m "$MODEL.inference.tensorrt" "$ROOT/test-imagery"

cat <<EOF

Done. In the GDS:
  SET_ML_PATH        "$MODEL.inference.tensorrt"
  SET_INFERENCE_PATH "<image folder>"
  MULTI_INFERENCE
EOF


