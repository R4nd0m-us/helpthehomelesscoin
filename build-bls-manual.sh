#!/bin/bash

set -e

echo "Building BLS signatures manually..."

# Download and build BLS
wget https://github.com/codablock/bls-signatures/archive/v20181101.tar.gz
tar -xzf v20181101.tar.gz
cd bls-signatures-20181101

mkdir -p build
cd build

cmake .. \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DSTLIB=ON \
    -DSHLIB=OFF \
    -DSTBIN=ON \
    -DBUILD_BLS_TESTS=OFF \
    -DCMAKE_CXX_STANDARD=14

make -j$(nproc)
sudo make install

echo "BLS installed to /usr/local"