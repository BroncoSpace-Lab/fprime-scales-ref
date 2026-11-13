#!/usr/bin/env bash
# One-time (idempotent) GPU/ML setup for the Jetson. Called by `make jetson-setup`
# and `make ml-setup`; safe to re-run, every step checks before it changes anything.
#
#   1. Check the board runs JetPack 6.1+ (L4T R36.4+), the minimum for CUDA 12.6
#   2. apt: nvidia-jetpack (CUDA 12.6, cuDNN 9, TensorRT 10 + Python bindings), python3-venv/pip
#   3. cuDSS (Tegra build): torch links libcudss.so.0, which JetPack doesn't ship
#   4. ml-venv: Python 3.10 venv with NVIDIA's Jetson torch + JetPack's TensorRT
#   5. Pre-download model weights so flight inference never needs the network
#   6. Verify CUDA from the interpreter F´ will use (scales_trt.cuda_check)
#   7. Build TensorRT engines (ml-trt-setup.sh) for $ML_MODELS
#   8. Accuracy self-test on test-imagery/ (resnet.inference.selftest)
#
# Run as the user the jetson-deployment service runs as (NOT with sudo); it calls
# sudo itself for steps 2-3. Environment overrides:
#   ML_MODELS="resnet yolo"   TensorRT engines to build ("" to skip)
#   ML_SKIP_APT=1             don't touch apt (CI / already provisioned)
#   ML_RECREATE_VENV=1        delete and rebuild ml-venv

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ML="$ROOT/Components/MLComponent/Scales-ML"
VENV="$ROOT/ml-venv"
REQ="$ML/requirements-jetson.txt"
ML_MODELS="${ML_MODELS-resnet yolo}"

# Minimum supported L4T: R36.4 = JetPack 6.1/6.2 (CUDA 12.6). The Jetson torch
# wheels in requirements-jetson.txt are built for exactly this CUDA.
MIN_L4T_MAJOR=36
MIN_L4T_MINOR=4

CUDSS_VERSION="0.7.1.4"
CUDSS_ARCHIVE="libcudss-linux-aarch64-${CUDSS_VERSION}_cuda12-archive"
CUDSS_URL="https://developer.download.nvidia.com/compute/cudss/redist/libcudss/linux-aarch64/${CUDSS_ARCHIVE}.tar.xz"
CUDSS_SHA256="f283c31b6badf4a5277014295705eac8e6e28f27de30d746719ea1cef7a750b8"
CUDSS_PREFIX="/opt/nvidia/cudss-${CUDSS_VERSION}"

APT_PACKAGES=(nvidia-jetpack python3-venv python3-pip curl)

step() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
ok()   { printf '    \033[32mOK\033[0m %s\n' "$*"; }
die()  { printf '\n\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

[ "$(id -u)" -ne 0 ] || die "Run as the jetson-deployment service user, not root/sudo (ml-venv and model caches are per-user)."

# Keep sudo's credential cache warm for the whole run, so the user types the
# password once even though the JetPack download can outlast sudo's timeout.
SUDO_KEEPALIVE_PID=""
need_sudo() {
    if [ -z "$SUDO_KEEPALIVE_PID" ]; then
        echo "    (sudo is needed for system packages)"
        sudo -v
        ( while kill -0 "$$" 2>/dev/null; do sudo -n true 2>/dev/null; sleep 50; done ) &
        SUDO_KEEPALIVE_PID=$!
    fi
}
trap '[ -n "$SUDO_KEEPALIVE_PID" ] && kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT

# ---------------------------------------------------------------------------
step "1/8 Checking JetPack / L4T version (need R${MIN_L4T_MAJOR}.${MIN_L4T_MINOR}+ = JetPack 6.1+)"
[ -f /etc/nv_tegra_release ] || die "/etc/nv_tegra_release not found: this is not a Jetson (or L4T is not installed)."
L4T_MAJOR="$(sed -n 's/^# R\([0-9]*\) (release).*/\1/p' /etc/nv_tegra_release)"
L4T_REV="$(sed -n 's/.*REVISION: \([0-9.]*\),.*/\1/p' /etc/nv_tegra_release)"
L4T_MINOR="${L4T_REV%%.*}"
[ -n "$L4T_MAJOR" ] && [ -n "$L4T_MINOR" ] || die "Could not parse /etc/nv_tegra_release: $(head -1 /etc/nv_tegra_release)"
if [ "$L4T_MAJOR" -lt "$MIN_L4T_MAJOR" ] || { [ "$L4T_MAJOR" -eq "$MIN_L4T_MAJOR" ] && [ "$L4T_MINOR" -lt "$MIN_L4T_MINOR" ]; }; then
    die "L4T R${L4T_MAJOR}.${L4T_REV} is too old. CUDA inference needs JetPack 6.1+ (L4T R36.4+); the Orin Nano Super needs JetPack 6.2.
       The L4T version can only be changed by reflashing: use NVIDIA SDK Manager or the JetPack 6.2 SD-card image."
fi
if [ "$L4T_MAJOR" -gt "$MIN_L4T_MAJOR" ]; then
    die "L4T R${L4T_MAJOR} (JetPack 7+) is newer than this setup supports: requirements-jetson.txt pins torch wheels for JetPack 6 / CUDA 12.6."
fi
ok "L4T R${L4T_MAJOR}.${L4T_REV} ($(tr -d '\0' < /proc/device-tree/model 2>/dev/null || echo unknown board))"
SYS_PY_VER="$(/usr/bin/python3 -c 'import sys; print("%d.%d" % sys.version_info[:2])')"
[ "$SYS_PY_VER" = "3.10" ] || die "JetPack 6 system Python should be 3.10, found $SYS_PY_VER; the Jetson torch wheels are cp310."

# ---------------------------------------------------------------------------
step "2/8 JetPack SDK packages: ${APT_PACKAGES[*]}"
missing=()
for p in "${APT_PACKAGES[@]}"; do
    dpkg-query -W -f='${Status}' "$p" 2>/dev/null | grep -q "install ok installed" || missing+=("$p")
done
if [ "${#missing[@]}" -eq 0 ]; then
    ok "already installed ($(dpkg-query -W -f='${Version}' nvidia-jetpack))"
elif [ "${ML_SKIP_APT:-0}" = "1" ]; then
    die "Missing packages (${missing[*]}) and ML_SKIP_APT=1."
else
    need_sudo
    echo "    installing: ${missing[*]} (nvidia-jetpack is several GB; this can take 10-20 min)"
    sudo apt-get update
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${missing[@]}"
    ok "installed"
fi
[ -x /usr/local/cuda/bin/nvcc ] || die "/usr/local/cuda/bin/nvcc missing after nvidia-jetpack install."
/usr/bin/python3 -c "import tensorrt" 2>/dev/null || die "JetPack's TensorRT Python bindings (python3-libnvinfer) are not importable by /usr/bin/python3."
ok "CUDA $(/usr/local/cuda/bin/nvcc --version | sed -n 's/.*release \([0-9.]*\).*/\1/p'), TensorRT $(/usr/bin/python3 -c 'import tensorrt; print(tensorrt.__version__)')"

# ---------------------------------------------------------------------------
step "3/8 cuDSS ${CUDSS_VERSION} (Tegra build, needed by the Jetson torch wheel)"
if ldconfig -p | grep -q "libcudss.so.0 "; then
    ok "libcudss.so.0 already on the loader path"
else
    need_sudo
    tmp="$(mktemp -d)"
    curl -fL --retry 3 -o "$tmp/cudss.tar.xz" "$CUDSS_URL"
    echo "$CUDSS_SHA256  $tmp/cudss.tar.xz" | sha256sum -c - >/dev/null || die "cuDSS archive checksum mismatch"
    tar -xJf "$tmp/cudss.tar.xz" -C "$tmp"
    sudo rm -rf "$CUDSS_PREFIX"
    sudo mkdir -p "$CUDSS_PREFIX"
    sudo cp -a "$tmp/$CUDSS_ARCHIVE/." "$CUDSS_PREFIX/"
    echo "$CUDSS_PREFIX/lib" | sudo tee /etc/ld.so.conf.d/scales-cudss.conf >/dev/null
    sudo ldconfig
    rm -rf "$tmp"
    ldconfig -p | grep -q "libcudss.so.0 " || die "libcudss.so.0 still not found after install"
    ok "installed to $CUDSS_PREFIX (registered in /etc/ld.so.conf.d/scales-cudss.conf)"
fi

# ---------------------------------------------------------------------------
step "4/8 ml-venv (Python 3.10 + Jetson CUDA torch + TensorRT) at $VENV"
if [ "${ML_RECREATE_VENV:-0}" = "1" ] || [ ! -x "$VENV/bin/python" ] \
   || [ "$("$VENV/bin/python" -c 'import sys; print("%d.%d" % sys.version_info[:2])' 2>/dev/null)" != "3.10" ]; then
    rm -rf "$VENV"
    # Isolated on purpose (no --system-site-packages): apt's NumPy-1 SciPy etc.
    # would otherwise shadow the venv's packages and break transformers.
    /usr/bin/python3 -m venv "$VENV"
    ok "created"
fi
SITE="$("$VENV/bin/python" -c 'import sysconfig; print(sysconfig.get_paths()["purelib"])')"
TRT_DIST="$(/usr/bin/python3 -c 'import os, tensorrt; print(os.path.dirname(tensorrt.__path__[0]))')"
for d in "$TRT_DIST"/tensorrt*; do  # expose only JetPack's TensorRT bindings
    ln -sfn "$d" "$SITE/$(basename "$d")"
done
"$VENV/bin/python" -m pip install -q --disable-pip-version-check "pip==25.2"
echo "    pip install -r ${REQ#$ROOT/} (first run downloads ~1 GB)"
"$VENV/bin/pip" install -q --disable-pip-version-check -r "$REQ"
ok "$("$VENV/bin/python" -c 'import torch, tensorrt, transformers; print(f"torch {torch.__version__}, TensorRT {tensorrt.__version__}, transformers {transformers.__version__}")')"

export PYTHONPATH="$ML${PYTHONPATH:+:$PYTHONPATH}"
export SCALES_TRT_PYTHON="$VENV/bin/python"

# ---------------------------------------------------------------------------
step "5/8 Pre-downloading model weights (flight inference runs with HF_HUB_OFFLINE=1)"
RESNET_MODEL="${SCALES_RESNET_MODEL:-microsoft/resnet-18}"
HF_HUB_OFFLINE=0 "$VENV/bin/python" - "$RESNET_MODEL" <<'PY'
import sys
from transformers import AutoImageProcessor, ResNetForImageClassification
m = sys.argv[1]
AutoImageProcessor.from_pretrained(m, backend="pil")
ResNetForImageClassification.from_pretrained(m)
print(f"    cached {m}")
PY
HF_HUB_OFFLINE=1 "$VENV/bin/python" -c "
from transformers import ResNetForImageClassification as R; R.from_pretrained('$RESNET_MODEL')" 2>/dev/null \
    || die "$RESNET_MODEL is not loadable offline after download."
ok "$RESNET_MODEL loads offline"

# ---------------------------------------------------------------------------
step "6/8 Verifying CUDA in the interpreter F´ uses for inference"
"$VENV/bin/python" -m scales_trt.cuda_check || die "CUDA check failed (see PROBLEM lines above)."

# ---------------------------------------------------------------------------
step "7/8 TensorRT engines: ${ML_MODELS:-<none>}"
for m in $ML_MODELS; do
    MODEL="$m" SCALES_TRT_PYTHON="$VENV/bin/python" bash "$ROOT/ml-trt-setup.sh"
done

# ---------------------------------------------------------------------------
step "8/8 ResNet accuracy self-test on test-imagery/"
trt_flag=""
case " $ML_MODELS " in *" resnet "*) ;; *) trt_flag="--no-trt" ;; esac
HF_HUB_OFFLINE=1 "$VENV/bin/python" -m resnet.inference.selftest "$ROOT/test-imagery" $trt_flag \
    || die "ResNet self-test failed."

printf '\n\033[1;32mML setup complete.\033[0m GPU inference interpreter: %s\n' "$VENV/bin/python"
