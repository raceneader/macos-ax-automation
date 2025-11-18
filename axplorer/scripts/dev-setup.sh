#!/bin/bash

# Exit on error
set -e

# Script location
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Setting up Axplorer development environment..."

# Check for Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo "Error: Xcode is required but not installed."
    echo "Please install Xcode from the App Store."
    exit 1
fi

# Check for Python
if ! command -v python3 &> /dev/null; then
    echo "Error: Python 3 is required but not installed."
    echo "Please install Python 3.12 or later."
    exit 1
fi

# Check Python version
PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
if (( $(echo "$PYTHON_VERSION < 3.12" | bc -l) )); then
    echo "Error: Python 3.12 or later is required (found $PYTHON_VERSION)"
    exit 1
fi

# Check for Poetry
if ! command -v poetry &> /dev/null; then
    echo "Installing Poetry..."
    curl -sSL https://install.python-poetry.org | python3 -
fi

# Install Python dependencies
echo "Installing Python dependencies..."
cd "$PROJECT_ROOT/py"
poetry install

# Create necessary directories
echo "Creating project directories..."
mkdir -p "$PROJECT_ROOT/py/src/axplorer/macos/lib"

# Set up pre-commit hooks (optional)
if [ -f "$PROJECT_ROOT/.git/hooks" ]; then
    echo "Setting up git hooks..."
    # Add any git hooks setup here
fi

# Build the project
echo "Building project..."
"$SCRIPT_DIR/build.sh"

echo "Development environment setup complete!"
echo
echo "Next steps:"
echo "1. Review the documentation in docs/"
echo "2. Try running the examples in py/examples/"
echo "3. Run the tests with 'cd py && poetry run pytest'"
echo
echo "Happy coding!"
