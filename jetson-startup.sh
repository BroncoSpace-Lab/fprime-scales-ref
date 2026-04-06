#!/bin/bash
# jetson-startup.sh
# Starts the JetsonDeployment flight software and connects to fprime.
# Uses the fprime-venv Python interpreter directly (no source activate needed).
# Retries automatically on crash.

# ---- Configuration ----
MAX_RETRIES=5       # Max number of crash restarts (0 = run once, no retry)
RETRY_DELAY=5       # Seconds to wait between restarts

# ---- Paths ----
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
PYTHON="$PROJECT_ROOT/fprime-venv/bin/python"
BUILD_DIR="$PROJECT_ROOT/build-python-fprime-aarch64-linux"

# Small Python script to run — more reliable than python -c "..." one-liner
# (see README troubleshooting: running each import step separately is stabler)
RUN_SCRIPT="$BUILD_DIR/run_jetson.py"

# ---- Preflight checks ----
if [ ! -f "$PYTHON" ]; then
    echo "ERROR: fprime-venv not found at $PYTHON"
    echo "       Run 'make setup' first."
    exit 1
fi

if [ ! -d "$BUILD_DIR" ]; then
    echo "ERROR: Build directory not found: $BUILD_DIR"
    echo "       Run 'make build-jetson' first."
    exit 1
fi

# Write the launcher script into the build dir so python_extension is importable
cat > "$RUN_SCRIPT" << 'EOF'
import python_extension
python_extension.main()
EOF

echo "========================================"
echo " JetsonDeployment Flight Software"
echo " Project: $PROJECT_ROOT"
echo " Python:  $PYTHON"
echo " Build:   $BUILD_DIR"
echo "========================================"
echo ""

cd "$BUILD_DIR"

attempt=0
while true; do
    attempt=$((attempt + 1))

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Attempt $attempt — launching python_extension..."
    "$PYTHON" "$RUN_SCRIPT"
    EXIT_CODE=$?

    if [ $EXIT_CODE -eq 0 ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Flight software exited cleanly (exit 0)."
        break
    fi

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Flight software exited with code $EXIT_CODE."

    if [ $MAX_RETRIES -gt 0 ] && [ $attempt -ge $MAX_RETRIES ]; then
        echo "Max retries ($MAX_RETRIES) reached. Giving up."
        rm -f "$RUN_SCRIPT"
        exit $EXIT_CODE
    fi

    echo "Restarting in $RETRY_DELAY seconds... (Ctrl+C to abort)"
    sleep $RETRY_DELAY
done

rm -f "$RUN_SCRIPT"
