#!/usr/bin/env bash
set -euo pipefail

# Build HelpTheHomeless on Ubuntu 24.04 using system/external dependencies (no internal depends)
# - Installs system packages (Boost 1.83, Qt 5.15.x from Ubuntu, etc.)
# - Builds and installs Berkeley DB 5.3.28 from source (Oracle tarball)
# - Builds and installs BLS (codablock v20181101.zip) statically
# - Clones repo https://github.com/R4nd0m-us/helpthehomelesscoin branch 24.04 and builds with GUI
#
# Notes:
# - Ubuntu 24.04 ships Qt 5.15.10. If you require exactly 5.15.13, building Qt from source is required (not covered here).
# - We pass --with-incompatible-bdb because upstream macros may still default to requiring BDB 4.8.
# - We attempt to use GCC/G++ 9 to avoid strict GCC 13 breakages; falls back if unavailable.

REPO_URL="https://github.com/R4nd0m-us/helpthehomelesscoin"
REPO_BRANCH="24.04"
CORES="$(nproc || echo 2)"

sudo apt-get update
sudo apt-get install -y \
  build-essential autoconf automake libtool pkg-config git curl unzip cmake \
  software-properties-common \
  libgmp-dev libevent-dev libzmq3-dev libprotobuf-dev protobuf-compiler \
  libminiupnpc-dev libqrencode-dev \
  qtbase5-dev qttools5-dev-tools libqt5svg5-dev \
  libboost-all-dev

# Try to install GCC/G++ 9; if not available, we continue with system compiler
if ! command -v gcc-9 >/dev/null 2>&1; then
  sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test || true
  sudo apt-get update || true
  sudo apt-get install -y gcc-9 g++-9 || true
fi
if command -v gcc-9 >/dev/null 2>&1; then
  export CC=gcc-9
  export CXX=g++-9
else
  export CC=gcc
  export CXX=g++
fi

echo "Using compiler: $CC / $CXX"

# 1) Build & install Berkeley DB 5.3.28 (static + headers)
TMPDIR="$(mktemp -d)"
pushd "$TMPDIR"
BDB_VER=5.3.28
BDB_TGZ="db-${BDB_VER}.NC.tar.gz"
BDB_URL="https://download.oracle.com/berkeley-db/${BDB_TGZ}"
curl -L -o "$BDB_TGZ" "$BDB_URL"
tar xf "$BDB_TGZ"
cd "db-${BDB_VER}/build_unix"
../dist/configure \
  --prefix=/usr/local/BerkeleyDB.${BDB_VER%.*} \
  --disable-shared --enable-cxx --disable-replication
make -j"$CORES"
sudo make install
# Ensure runtime/linker sees the libs
echo "/usr/local/BerkeleyDB.${BDB_VER%.*}/lib" | sudo tee /etc/ld.so.conf.d/berkeleydb${BDB_VER%.*}.conf >/dev/null
sudo ldconfig
popd
rm -rf "$TMPDIR"

# 2) Build & install BLS (static lib + headers) from codablock v20181101
TMPDIR="$(mktemp -d)"
pushd "$TMPDIR"
curl -L -o v20181101.zip https://github.com/codablock/bls-signatures/archive/v20181101.zip
unzip -q v20181101.zip
cd bls-signatures-20181101
# If using GCC >= 13, drop problematic alignment attributes in BLAKE2 headers
GCC_MAJ=$($CC -dumpversion | cut -d. -f1 || echo 0)
if [ "${GCC_MAJ}" -ge 13 ]; then
  sed -i -E 's/__attribute__\s*\(\(aligned\([0-9]+\)\)\)//g' contrib/relic/src/md/blake2.h || true
fi
# Build static lib only; do not build tests/benchmarks
cmake -DCMAKE_C_COMPILER="$CC" -DCMAKE_CXX_COMPILER="$CXX" \
      -DSTLIB=ON -DSHLIB=OFF -DSTBIN=OFF \
      -DBUILD_TESTS=OFF -DBUILD_BENCHMARKS=OFF -DBENCHMARK=OFF -DTESTS=OFF \
      .
cmake --build . --target chiabls -- -j"$CORES"
LIB_PATH="libchiabls.a"; [ -f "$LIB_PATH" ] || LIB_PATH="src/libchiabls.a"
sudo install -Dm644 "$LIB_PATH" /usr/local/lib/libchiabls.a
sudo mkdir -p /usr/local/include/chiabls
sudo cp -a src/*.hpp /usr/local/include/chiabls/
sudo ldconfig
popd
rm -rf "$TMPDIR"

# 3) Clone repo and build using system deps
if [ ! -d helpthehomelesscoin ]; then
  git clone --branch "$REPO_BRANCH" --depth 1 "$REPO_URL" helpthehomelesscoin
fi
cd helpthehomelesscoin

# Configure flags to help find BDB and link properly
export BDB_CFLAGS="-I/usr/local/BerkeleyDB.${BDB_VER%.*}/include"
export BDB_LIBS="-L/usr/local/BerkeleyDB.${BDB_VER%.*}/lib -ldb_cxx-${BDB_VER%.*}"
# /usr/local/include and /usr/local/lib are default search paths, but we make it explicit
export CPPFLAGS="${CPPFLAGS:-} -I/usr/local/include"
export LDFLAGS="${LDFLAGS:-} -L/usr/local/lib"

./autogen.sh
./configure --with-gui=yes --with-incompatible-bdb CC="$CC" CXX="$CXX" \
  --enable-zmq --enable-reduce-exports
make -j"$CORES"
# Optionally: sudo make install

echo "Build complete. Binaries are in src/ (and qt/ if GUI was enabled)." 

