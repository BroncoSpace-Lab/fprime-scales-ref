#!/usr/bin/env bash
# Copy ML packages into build-python-fprime-aarch64-linux
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

OUT="./build-python-fprime-aarch64-linux"
AUTO="./build-fprime-automatic-aarch64-linux"
ML="./Components/MLComponent/Scales-ML"

mkdir -p "$OUT"
rm -rf "${OUT:?}"/*

find ./Components/ -name "*Component.py" -exec cp -t "$OUT" {} +
cp "$ML/resnet/resnet_cifar100.py" "$OUT"/
cp -r "$ML/resnet" "$ML/yolo" "$ML/scales_trt" "$OUT"/
cp "$AUTO/fprime_pybind.py" "$OUT"/
cp "$AUTO/lib/aarch64-linux/libpython_extension.so" "$OUT"/

cd "$OUT"
mv libpython_extension.so python_extension.so
ln -sf python_extension.so Fw.so
ln -sf python_extension.so Components.so

echo "OK: $OUT"
