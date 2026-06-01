#!/bin/bash
# jetson-startup.sh
# Starts the JetsonDeployment flight software and connects to fprime.
# Uses the fprime-venv Python interpreter directly.
# Retries automatically on crash.
#
# This script also sets up the Lucid/Arena SDK shared library paths and symlinks
# before importing python_extension.

# ---- Configuration ----
MAX_RETRIES=5       # Max number of crash restarts (0 = run once, no retry)
RETRY_DELAY=5       # Seconds to wait between restarts

# ---- Paths ----
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

PYTHON="$PROJECT_ROOT/fprime-venv/bin/python"
BUILD_DIR="$PROJECT_ROOT/build-python-fprime-aarch64-linux"
RUN_SCRIPT="$BUILD_DIR/run_jetson.py"

ARENA_SDK_DIR="$PROJECT_ROOT/lib/ArenaSDK"
ARENA_LIB_DIR="$ARENA_SDK_DIR/lib"
GENICAM_LIB_DIR="$ARENA_SDK_DIR/GenICam/library/lib/Linux64_ARM"
FFMPEG_LIB_DIR="$ARENA_SDK_DIR/ffmpeg"

# ---- Preflight checks ----
if [ ! -f "$PYTHON" ]; then
    echo "ERROR: fprime-venv Python not found at:"
    echo "       $PYTHON"
    echo "       Run 'make setup' first."
    exit 1
fi

if [ ! -d "$BUILD_DIR" ]; then
    echo "ERROR: Build directory not found:"
    echo "       $BUILD_DIR"
    echo "       Run 'make build-jetson' first."
    exit 1
fi

if [ ! -d "$ARENA_LIB_DIR" ]; then
    echo "ERROR: Arena SDK lib directory not found:"
    echo "       $ARENA_LIB_DIR"
    exit 1
fi

if [ ! -d "$GENICAM_LIB_DIR" ]; then
    echo "WARNING: GenICam library directory not found:"
    echo "         $GENICAM_LIB_DIR"
fi

if [ ! -d "$FFMPEG_LIB_DIR" ]; then
    echo "WARNING: Arena SDK ffmpeg directory not found:"
    echo "         $FFMPEG_LIB_DIR"
fi

# ---- Arena SDK / Lucid shared library setup ----
echo "Setting up Arena SDK library symlinks..."

cd "$ARENA_LIB_DIR" || exit 1

ln -sf libarena.so.0.1.77 libarena.so
ln -sf libarena.so.0.1.77 libarena.so.0

ln -sf libarenac.so.0.1.77 libarenac.so
ln -sf libarenac.so.0.1.77 libarenac.so.0

ln -sf libgentl.so.0.1.77 libgentl.so
ln -sf libgentl.so.0.1.77 libgentl.so.0

ln -sf liblucidlog.so.0.1.77 liblucidlog.so
ln -sf liblucidlog.so.0.1.77 liblucidlog.so.0

ln -sf libsave.so.0.1.77 libsave.so
ln -sf libsave.so.0.1.77 libsave.so.0

ln -sf libsavec.so.0.1.77 libsavec.so
ln -sf libsavec.so.0.1.77 libsavec.so.0

# This must be exported before Python imports python_extension.
export LD_LIBRARY_PATH="$ARENA_LIB_DIR:$GENICAM_LIB_DIR:$FFMPEG_LIB_DIR:$LD_LIBRARY_PATH"

# ---- Write temporary Python launcher ----
# This file lives in the build directory so python_extension can be imported.
cat > "$RUN_SCRIPT" << 'EOF'
import python_extension

python_extension.main()
EOF

echo "========================================"
echo " JetsonDeployment Flight Software"
echo " Project: $PROJECT_ROOT"
echo " Python:  $PYTHON"
echo " Build:   $BUILD_DIR"
echo " Arena:   $ARENA_LIB_DIR"
echo " LD path: $LD_LIBRARY_PATH"
echo "========================================"
echo ""

cd "$BUILD_DIR" || exit 1

# ---- Main retry loop ----
attempt=0

while true; do
    attempt=$((attempt + 1))

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Attempt $attempt - launching python_extension..."

    "$PYTHON" "$RUN_SCRIPT"
    EXIT_CODE=$?

    if [ "$EXIT_CODE" -eq 0 ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Flight software exited cleanly."
        break
    fi

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Flight software exited with code $EXIT_CODE."

    if [ "$MAX_RETRIES" -gt 0 ] && [ "$attempt" -ge "$MAX_RETRIES" ]; then
        echo "Max retries ($MAX_RETRIES) reached. Giving up."
        rm -f "$RUN_SCRIPT"
        exit "$EXIT_CODE"
    fi

    echo "Restarting in $RETRY_DELAY seconds..."
    sleep "$RETRY_DELAY"
done

rm -f "$RUN_SCRIPT"

exit 0

#Since this is the lab jetson, before running the python_extension main code, these commands need to be link the necessary .so files and export them
# cd ~/fprime-scales-ref/lib/ArenaSDK/lib

# ln -sf libarena.so.0.1.77 libarena.so
# ln -sf libarena.so.0.1.77 libarena.so.0

# ln -sf libarenac.so.0.1.77 libarenac.so
# ln -sf libarenac.so.0.1.77 libarenac.so.0

# ln -sf libgentl.so.0.1.77 libgentl.so
# ln -sf libgentl.so.0.1.77 libgentl.so.0

# ln -sf liblucidlog.so.0.1.77 liblucidlog.so
# ln -sf liblucidlog.so.0.1.77 liblucidlog.so.0

# ln -sf libsave.so.0.1.77 libsave.so
# ln -sf libsave.so.0.1.77 libsave.so.0

# ln -sf libsavec.so.0.1.77 libsavec.so
# ln -sf libsavec.so.0.1.77 libsavec.so.0

# cd ~/fprime-scales-ref

# export LD_LIBRARY_PATH="$HOME/fprime-scales-ref/lib/ArenaSDK/lib:$HOME/fprime-scales-ref/lib/ArenaSDK/GenICam/library/lib/Linux64_ARM:$HOME/fprime-scales-ref/lib/ArenaSDK/ffmpeg:$LD_LIBRARY_PATH"