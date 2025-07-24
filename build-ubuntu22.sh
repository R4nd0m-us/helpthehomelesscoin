#!/bin/bash

set -e

echo "Installing build dependencies..."
sudo apt update
sudo apt install -y \
    build-essential \
    libtool \
    autotools-dev \
    automake \
    pkg-config \
    bsdmainutils \
    python3 \
    cmake \
    curl \
    wget \
    libgmp-dev \
    libssl-dev \
    libevent-dev \
    libboost-all-dev \
    libdb5.3-dev \
    libdb5.3++-dev \
    libminiupnpc-dev \
    libzmq3-dev \
    ccache

echo "Building dependencies (including BLS)..."
cd depends
make -j$(nproc) HOST=x86_64-unknown-linux-gnu
cd ..

echo "Configuring build..."
./autogen.sh
./configure \
    --prefix=$(pwd)/depends/x86_64-unknown-linux-gnu \
    --disable-dependency-tracking \
    --enable-glibc-back-compat \
    --enable-reduce-exports \
    --disable-bench \
    --disable-gui-tests \
    --with-gui=no

echo "Building..."
make -j$(nproc)

echo "Build complete! Binaries are in src/"
