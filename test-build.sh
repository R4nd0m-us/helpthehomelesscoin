#!/bin/bash
# Comprehensive test script for the robust HelpTheHomeless build system

set -e

echo "HelpTheHomeless Coin Robust Build System Test"
echo "============================================="
echo ""

# Check system information
UBUNTU_VERSION=$(lsb_release -rs 2>/dev/null || echo "unknown")
DISTRO=$(lsb_release -si 2>/dev/null || echo "unknown")
ARCH=$(uname -m)
CORES=$(nproc)
MEMORY=$(free -h | grep Mem | awk '{print $2}')

echo "System Information:"
echo "  Distribution: $DISTRO $UBUNTU_VERSION"
echo "  Architecture: $ARCH"
echo "  CPU Cores: $CORES"
echo "  Memory: $MEMORY"
echo ""

# Check if we're on supported systems
if [[ "$UBUNTU_VERSION" != "22.04" && "$UBUNTU_VERSION" != "24.04" ]]; then
    echo "Warning: This system is designed for Ubuntu 22.04 or 24.04"
    echo "Current version: $DISTRO $UBUNTU_VERSION"
    echo "The build system may still work but is untested on this version."
    echo ""
fi

# Check required files
echo "Checking build system files..."
MISSING_FILES=0

if [ ! -f "makefile.unix" ]; then
    echo "  ✗ makefile.unix not found"
    MISSING_FILES=1
else
    echo "  ✓ makefile.unix"
fi

if [ ! -f "Makefile" ]; then
    echo "  ✗ Makefile not found"
    MISSING_FILES=1
else
    echo "  ✓ Makefile"
fi

if [ ! -f "depends/Makefile" ]; then
    echo "  ✗ depends/Makefile not found"
    MISSING_FILES=1
else
    echo "  ✓ depends/Makefile"
fi

if [ ! -f "autogen.sh" ]; then
    echo "  ✗ autogen.sh not found"
    MISSING_FILES=1
else
    echo "  ✓ autogen.sh"
fi

if [ ! -f "configure.ac" ]; then
    echo "  ✗ configure.ac not found"
    MISSING_FILES=1
else
    echo "  ✓ configure.ac"
fi

if [ $MISSING_FILES -eq 1 ]; then
    echo ""
    echo "Error: Missing required build system files!"
    echo "Make sure you're in the HelpTheHomeless project root directory."
    exit 1
fi

echo ""

# Test basic make functionality
echo "Testing make command availability..."
if ! command -v make &> /dev/null; then
    echo "Error: make command not found. Please install build-essential first:"
    echo "  sudo apt update && sudo apt install build-essential"
    exit 1
else
    echo "  ✓ make command available"
fi

echo ""

# Test makefile syntax
echo "Testing makefile syntax..."
if make -n help >/dev/null 2>&1; then
    echo "  ✓ Makefile syntax is valid"
else
    echo "  ✗ Makefile syntax error detected"
    exit 1
fi

echo ""

# Test build system targets
echo "Testing build system targets..."

echo "  Testing help target..."
if make help >/dev/null 2>&1; then
    echo "    ✓ help target works"
else
    echo "    ✗ help target failed"
    exit 1
fi

echo "  Testing check-env target..."
if make check-env >/dev/null 2>&1; then
    echo "    ✓ check-env target works"
else
    echo "    ✗ check-env target failed"
    exit 1
fi

echo "  Testing check-deps target..."
if make check-deps >/dev/null 2>&1; then
    echo "    ✓ check-deps target works"
else
    echo "    ✗ check-deps target failed"
    exit 1
fi

echo ""

# Show actual help output
echo "Build System Help Output:"
echo "========================="
make help
echo ""

# Show environment check
echo "Environment Check:"
echo "=================="
make check-env
echo ""

# Show dependency check
echo "Dependency Check:"
echo "================="
make check-deps
echo ""

echo "=== TEST RESULTS ==="
echo "✓ All basic tests passed!"
echo ""
echo "NEXT STEPS:"
echo "1. Install dependencies: make install-deps"
echo "2. Build the project: make"
echo "3. If build fails: make build-failure-help"
echo ""
echo "BUILD STRATEGIES AVAILABLE:"
echo "- make                        # Auto-build with fallbacks"
echo "- make BUILD_STRATEGY=depends # Force depends build"
echo "- make BUILD_STRATEGY=system  # Force system libraries"
echo "- make BUILD_STRATEGY=minimal # Minimal build"
echo ""
echo "RECOVERY OPTIONS:"
echo "- make fix-library-links      # Fix library version issues"
echo "- make build-failure-help     # Show detailed recovery help"
echo "- make distclean && make      # Complete clean rebuild"
echo ""
echo "The robust build system is ready to use!"
