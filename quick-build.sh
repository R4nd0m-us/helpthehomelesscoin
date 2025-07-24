#!/bin/bash

# Quick build using system libraries
set -e

echo "Quick build for Ubuntu 22.04..."

./autogen.sh

./configure \
    --disable-dependency-tracking \
    --with-incompatible-bdb \
    --disable-bench \
    --disable-gui-tests \
    --with-gui=no \
    CPPFLAGS="-I/usr/include" \
    LDFLAGS="-L/usr/lib/x86_64-linux-gnu"

make -j$(nproc)

echo "Done! Binaries:"
echo "  helpthehomelessd: $(pwd)/src/helpthehomelessd"
echo "  helpthehomeless-cli: $(pwd)/src/helpthehomeless-cli" 
echo "  helpthehomeless-tx: $(pwd)/src/helpthehomeless-tx"