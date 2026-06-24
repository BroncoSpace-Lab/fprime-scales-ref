#!/bin/bash
set -e

# ======================================================================
# jetson-startup.sh
#
# Startup wrapper for JetsonDeployment fprime-python.
# ======================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

PYTHON_LAUNCHER="$PROJECT_ROOT/jetson-python.sh"
IMAGES_DIR="$PROJECT_ROOT/Images"

echo "Making the Images folder..."
mkdir -p "$IMAGES_DIR"

if [ ! -x "$PYTHON_LAUNCHER" ]; then
    echo "ERROR: launcher not found or not executable:"
    echo "  $PYTHON_LAUNCHER"
    echo "Run:"
    echo "  chmod +x $PYTHON_LAUNCHER"
    exit 1
fi

echo "Starting JetsonDeployment fprime-python..."
exec "$PYTHON_LAUNCHER"