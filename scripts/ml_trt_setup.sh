#!/usr/bin/env bash
# TensorRT cache: MODEL=resnet|yolo  SCALES_TRT_PYTHON=/usr/bin/python3  make ml-trt-setup
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

MODEL="${MODEL:-resnet}"
PY="${SCALES_TRT_PYTHON:-${TRT_PYTHON:-/usr/bin/python3}}"
FP16="${TRT_FP16:-1}"
BUILD="$ROOT/build-python-fprime-aarch64-linux"

case "$MODEL" in
  resnet) ADAPTER="resnet.inference.trt_adapter"; NAME="${SCALES_TRT_MODEL:-microsoft/resnet-18}" ;;
  yolo)   ADAPTER="yolo.inference.trt_adapter";   NAME="${SCALES_YOLO_WEIGHTS:-yolov8n.pt}" ;;
  *) echo "MODEL must be resnet or yolo"; exit 2 ;;
esac

echo "=== ML TRT setup ($MODEL) ==="
command -v "$PY" >/dev/null || { echo "missing $PY — set SCALES_TRT_PYTHON"; exit 2; }
"$PY" -c "import tensorrt" 2>/dev/null || { echo "tensorrt not in $PY"; exit 3; }

bash "$ROOT/scripts/jetson-python.sh"
[[ -d "$BUILD/scales_trt" ]] || { echo "missing $BUILD/scales_trt"; exit 2; }

export SCALES_TRT_PYTHON="$PY" TRT_FP16="$FP16"
echo "Building engine (YOLO can take 10+ min)..."
(cd "$BUILD" && "$PY" -m scales_trt.worker prepare --adapter "$ADAPTER" --model "$NAME" --fp16 "$FP16")

cat <<EOF

Done. GDS:
  SET_ML_PATH "$MODEL.inference.tensorrt"
  SET_INFERENCE_PATH "<your image folder>"
  MULTI_INFERENCE

PyTorch YOLO (no TRT): SET_ML_PATH "yolo.inference.pytorch"
Long build status: export TRT_BUILD_HEARTBEAT_S=60
EOF
