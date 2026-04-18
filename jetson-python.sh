#!/bin/bash

PYTHON_BUILD=./build-python-fprime-aarch64-linux
BUILD_AUTOMATIC=./build-fprime-automatic-aarch64-linux


if test -d "$PYTHON_BUILD"; then
    rm -r $PYTHON_BUILD/*
else
    mkdir $PYTHON_BUILD
fi

find ./Components/ -type f -name "*Component.py" | xargs cp -t $PYTHON_BUILD
find ./Components/ -type f -name "*resnet*.py" | xargs cp -t $PYTHON_BUILD
cp $BUILD_AUTOMATIC/fprime_pybind.py $PYTHON_BUILD

cp $BUILD_AUTOMATIC/lib/aarch64-linux/libpython_extension.so $PYTHON_BUILD


cd $PYTHON_BUILD
mv libpython_extension.so python_extension.so

# Patch with patchelf as backup
echo "Patching python_extension.so with Arena SDK library paths..."
patchelf --set-rpath '../lib/ArenaSDK/lib:../lib/ArenaSDK/ffmpeg:../lib/ArenaSDK/GenICam/library/lib/Linux64_ARM' python_extension.so

ln python_extension.so Fw.so
ln python_extension.so Components.so

# Create a wrapper script that sets LD_LIBRARY_PATH for Python execution
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cat > run-python.sh << 'EOF'
#!/bin/bash
# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/.."

# Set LD_LIBRARY_PATH to include Arena SDK libraries
export LD_LIBRARY_PATH="$PROJECT_ROOT/lib/ArenaSDK/lib:$PROJECT_ROOT/lib/ArenaSDK/ffmpeg:$PROJECT_ROOT/lib/ArenaSDK/GenICam/library/lib/Linux64_ARM:$LD_LIBRARY_PATH"

# Run Python using the venv's Python executable directly
"$PROJECT_ROOT/fprime-venv/bin/python" "$@"
EOF

chmod +x run-python.sh
echo ""
echo "✓ Created run-python.sh wrapper script"
echo "Usage: ./build-python-fprime-aarch64-linux/run-python.sh -c \"import python_extension; python_extension.main()\""
