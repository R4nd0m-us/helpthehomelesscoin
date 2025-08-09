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
  python3 git libgmp-dev

# For Qt GUI using system Qt (fast path). Comment these if you want depends-based Qt.
sudo apt-get install -y qtbase5-dev qttools5-dev-tools libqt5svg5-dev libqrencode-dev \
  libprotobuf-dev protobuf-compiler libevent-dev libevent-pthreads-2.1-7 \
  libzmq3-dev

# 2) Install BLS (required) exactly as specified + alignment fixes for GCC 13+
TMPDIR="$(mktemp -d)"
pushd "$TMPDIR"
curl -L -o v20181101.zip https://github.com/codablock/bls-signatures/archive/v20181101.zip
unzip -q v20181101.zip
cd bls-signatures-20181101
# Patch relic BLAKE2 arrays-of-1 that trip alignment rules on GCC 13+
sed -i 's/blake2s_state S\[8]\[1];/blake2s_state S[8];/' contrib/relic/src/md/blake2.h
sed -i 's/blake2s_state R\[1];/blake2s_state R;/' contrib/relic/src/md/blake2.h
sed -i 's/blake2b_state S\[4]\[1];/blake2b_state S[4];/' contrib/relic/src/md/blake2.h
sed -i 's/blake2b_state R\[1];/blake2b_state R;/' contrib/relic/src/md/blake2.h
sed -i 's/blake2s_state S\[1];/blake2s_state S;/' contrib/relic/src/md/blake2s-ref.c
cmake .
sudo make -j"$CORES" install
sudo ldconfig
popd
rm -rf "$TMPDIR"

# 3) Clone repository
if [ ! -d helpthehomelesscoin ]; then
  git clone --branch "$REPO_BRANCH" --depth 1 "$REPO_URL" helpthehomelesscoin
fi
cd helpthehomelesscoin

# 4) Build depends (uses updated Boost/BDB in repo)
pushd depends
make -j"$CORES" HOST=x86_64-unknown-linux-gnu
popd

# 5) Configure and build (GUI enabled; uses system Qt and depends for others)
./autogen.sh
PKG_CONFIG_PATH="$(pwd)/depends/x86_64-unknown-linux-gnu/lib/pkgconfig:$PKG_CONFIG_PATH" \
./configure \
  --prefix="$(pwd)/depends/x86_64-unknown-linux-gnu" \
  --with-gui=yes \
  --enable-zmq \
  --enable-reduce-exports

make -j"$CORES"
# Optionally: make install

echo "Build complete. Binaries in src and/or qt/." 

