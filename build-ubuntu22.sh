#!/bin/bash

# Direct build script for Ubuntu 22.04
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
    python3-pip \
    libevent-dev \
    libboost-system-dev \
    libboost-filesystem-dev \
    libboost-test-dev \
    libboost-thread-dev \
    libboost-chrono-dev \
    libboost-program-options-dev \
    libssl-dev \
    libdb5.3-dev \
    libdb5.3++-dev \
    libminiupnpc-dev \
    libzmq3-dev \
    libqrencode-dev \
    libprotobuf-dev \
    protobuf-compiler \
    libqt5gui5 \
    libqt5core5a \
    libqt5dbus5 \
    qttools5-dev \
    qttools5-dev-tools \
    qt5-qmake \
    qtbase5-dev \
    ccache \
    git

# Install Python dependencies
pip3 install pyzmq

echo "Building dependencies..."
cd depends
make -j$(nproc) NO_QT=1 NO_UPNP=1
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