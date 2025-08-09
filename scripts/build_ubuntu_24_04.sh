#!/usr/bin/env bash
set -euo pipefail

# Build HelpTheHomeless on Ubuntu 24.04 with GUI and BLS
# - Fetches repo and builds from branch 24.04
# - Installs BLS v20181101 from the specified zip
# - Builds depends (Boost 1.83, BDB 5.3.28 via repo changes)

REPO_URL="https://github.com/R4nd0m-us/helpthehomelesscoin"
REPO_BRANCH="24.04"
CORES="$(nproc || echo 2)"

# 1) Prerequisites
sudo apt-get update
sudo apt-get install -y \
  build-essential libtool autotools-dev automake pkg-config bsdmainutils cmake curl unzip \
  python3 git libgmp-dev software-properties-common dos2unix

# Try to install GCC/G++ 9 from the Ubuntu Toolchain PPA; fall back to system GCC if unavailable
if ! command -v gcc-9 >/dev/null 2>&1; then
  sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test || true
  sudo apt-get update || true
  sudo apt-get install -y gcc-9 g++-9 || true
fi

# Select compiler
if command -v gcc-9 >/dev/null 2>&1; then
  export CC=gcc-9
  export CXX=g++-9
else
  export CC=gcc
  export CXX=g++
fi

# For Qt GUI using system Qt (fast path). Comment these if you want depends-based Qt.
sudo apt-get install -y qtbase5-dev qttools5-dev-tools libqt5svg5-dev libqrencode-dev \
  libprotobuf-dev protobuf-compiler libevent-dev libevent-pthreads-2.1-7 \
  libzmq3-dev

# 2) Install BLS (required) exactly as specified; no patches needed when using GCC 9
TMPDIR="$(mktemp -d)"
pushd "$TMPDIR"
curl -L -o v20181101.zip https://github.com/codablock/bls-signatures/archive/v20181101.zip
unzip -q v20181101.zip
cd bls-signatures-20181101
cmake -DCMAKE_C_COMPILER="$CC" -DCMAKE_CXX_COMPILER="$CXX" \
      -DSTLIB=ON -DSHLIB=OFF -DSTBIN=OFF \
      -DBUILD_TESTS=OFF -DBUILD_BENCHMARKS=OFF -DBENCHMARK=OFF -DTESTS=OFF \
      .
# Build only the library and then manually install headers and static lib (avoid CMake install targets that build tests)
cmake --build . --target chiabls -- -j"$CORES"
# Locate library
LIB_PATH="libchiabls.a"
if [ ! -f "$LIB_PATH" ] && [ -f "src/libchiabls.a" ]; then
  LIB_PATH="src/libchiabls.a"
fi
sudo install -Dm644 "$LIB_PATH" /usr/local/lib/libchiabls.a
sudo mkdir -p /usr/local/include/chiabls
sudo cp -a src/*.hpp /usr/local/include/chiabls/
sudo ldconfig
popd
rm -rf "$TMPDIR"

# 3) Clone repository
if [ ! -d helpthehomelesscoin ]; then
  git clone --branch "$REPO_BRANCH" --depth 1 "$REPO_URL" helpthehomelesscoin
fi
cd helpthehomelesscoin

# Normalize potential CRLF line endings in depends to avoid GNU make parse errors
find depends -type f \( -name "*.mk" -o -name "Makefile" -o -name "*.m4" \) -print0 | \
  xargs -0 dos2unix -q --allow-chown || true
# Remove any stray leading tabs on non-recipe lines (guard against parse error)
sed -i '240,248s/^\t//' depends/funcs.mk

# 4) Build depends (uses updated Boost/BDB in repo)
pushd depends
# Ensure depends uses the selected toolchain
make -j"$CORES" HOST=x86_64-unknown-linux-gnu CC="$CC" CXX="$CXX"
popd

# 5) Configure and build (GUI enabled; uses system Qt and depends for others)
./autogen.sh
PKG_CONFIG_PATH="$(pwd)/depends/x86_64-unknown-linux-gnu/lib/pkgconfig:$PKG_CONFIG_PATH" \
CC="$CC" CXX="$CXX" \
./configure \
  --prefix="$(pwd)/depends/x86_64-unknown-linux-gnu" \
  --with-gui=yes \
  --enable-zmq \
  --enable-reduce-exports

make -j"$CORES"
# Optionally: make install

echo "Build complete. Binaries in src and/or qt/." 

