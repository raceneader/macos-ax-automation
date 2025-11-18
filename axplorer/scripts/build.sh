#!/bin/bash

# Exit on error
set -e

# Script location
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Building Axplorer..."

# Build Swift library
echo "Building Swift library..."
cd "$PROJECT_ROOT/lib/AXplorer"
swift build -c release

# Get the path to the built library
SWIFT_LIB_PATH=".build/arm64-apple-macosx/release/libAXplorer.dylib"

if [ ! -f "$SWIFT_LIB_PATH" ]; then
    echo "Error: Swift library not found at $SWIFT_LIB_PATH"
    exit 1
fi

# Create lib directory in Python package if it doesn't exist
PYTHON_LIB_DIR="$PROJECT_ROOT/py/src/axplorer/macos/lib"
mkdir -p "$PYTHON_LIB_DIR"

# Copy Swift library to Python package
echo "Copying Swift library to Python package..."
cp "$SWIFT_LIB_PATH" "$PYTHON_LIB_DIR/"

# Update library path in lib.py
echo "Updating library path in lib.py..."
RELATIVE_LIB_PATH="lib/libAXplorer.dylib"
sed -i '' "s|lib = ctypes.CDLL('.*')|lib = ctypes.CDLL(os.path.join(os.path.dirname(__file__), '$RELATIVE_LIB_PATH'))|" \
    "$PROJECT_ROOT/py/src/axplorer/macos/lib.py"

# Build Python package
echo "Building Python package..."
cd "$PROJECT_ROOT/py"
poetry install
poetry build

echo "Build complete!"
echo "Swift library: $SWIFT_LIB_PATH"
echo "Python package: $PROJECT_ROOT/py/dist/"
