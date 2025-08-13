#!/usr/bin/env bash
set -euo pipefail

# Function to handle build failures with detailed error reporting
handle_build_error() {
    local component="$1"
    local step="$2"
    local exit_code="$3"

    echo "=============================================="
    echo "ERROR: $component $step FAILED (exit code: $exit_code)"
    echo "=============================================="
    echo "Working directory: $(pwd)"
    echo "Last 50 lines of output:"
    echo "----------------------------------------------"
    tail -50 build.log 2>/dev/null || echo "No build.log found"
    echo "----------------------------------------------"
    echo "Environment variables:"
    echo "CC=$CC"
    echo "CXX=$CXX"
    echo "CPPFLAGS=$CPPFLAGS"
    echo "LDFLAGS=$LDFLAGS"
    echo "PATH=$PATH"
    echo "=============================================="
    exit $exit_code
}

# Build HelpTheHomeless on Ubuntu 22.04/24.04 using original dependency versions
# This script builds all dependencies from source to match the original codebase exactly:
# - Boost 1.63.0, Qt 5.7.1, OpenSSL 1.0.1k, Berkeley DB 4.8.30, BLS v20181101, etc.
# - Uses GCC 7 to avoid modern compiler strictness issues with old code
# - Builds everything from scratch without modifying the original source

REPO_URL="https://github.com/R4nd0m-us/helpthehomelesscoin"
REPO_BRANCH="new"
TOTAL_CORES="$(nproc || echo 4)"
CORES="$(( TOTAL_CORES / 4 ))"
[ "$CORES" -lt 1 ] && CORES=1
BUILD_PREFIX="/opt/helpthehomeless-deps"

echo "Building HelpTheHomeless with original dependency versions on Ubuntu $(lsb_release -rs)"

# 1) Install build prerequisites and GCC 7 (compatible with old dependencies)
sudo apt-get update
sudo apt-get install -y \
  build-essential autoconf automake libtool pkg-config git curl unzip cmake \
  python3 bsdmainutils software-properties-common

# Install GCC 7 from archived sources (exact version that built original dependencies)
if ! command -v gcc-7 >/dev/null 2>&1; then
  echo "Installing GCC 7 from archived packages..."

  # Add Ubuntu 18.04 (bionic) sources for GCC 7
  echo "deb http://archive.ubuntu.com/ubuntu bionic main universe" | sudo tee /etc/apt/sources.list.d/bionic.list
  echo "deb http://archive.ubuntu.com/ubuntu bionic-updates main universe" | sudo tee -a /etc/apt/sources.list.d/bionic.list

  # Add GPG key for bionic
  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3B4FE6ACC0B21F32

  # Update and install GCC 7 with specific version pinning
  sudo apt-get update
  sudo apt-get install -y gcc-7 g++-7 gcc-7-base cpp-7 libgcc-7-dev libstdc++-7-dev

  # Clean up bionic sources to avoid conflicts
  sudo rm -f /etc/apt/sources.list.d/bionic.list
  sudo apt-get update
fi

export CC=gcc-7
export CXX=g++-7
export AR=ar
export RANLIB=ranlib
export STRIP=strip

echo "Using toolchain: $CC / $CXX"

# 2) Create build prefix
sudo mkdir -p "$BUILD_PREFIX"
sudo chown "$(whoami):$(whoami)" "$BUILD_PREFIX"
export PKG_CONFIG_PATH="$BUILD_PREFIX/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
export CPPFLAGS="-I$BUILD_PREFIX/include ${CPPFLAGS:-}"
export LDFLAGS="-L$BUILD_PREFIX/lib ${LDFLAGS:-}"
export PATH="$BUILD_PREFIX/bin:$PATH"

# 3) Build GMP 6.1.2 (required for BLS)
echo "Building GMP 6.1.2..."
TMPDIR="$(mktemp -d)"
pushd "$TMPDIR"
curl -L -o gmp-6.1.2.tar.bz2 https://gmplib.org/download/gmp/gmp-6.1.2.tar.bz2
tar xf gmp-6.1.2.tar.bz2
cd gmp-6.1.2
./configure --prefix="$BUILD_PREFIX" --enable-cxx --enable-fat --with-pic --disable-shared
make -j"$CORES"
make install
popd
rm -rf "$TMPDIR"

# 4) Build OpenSSL 1.0.1k (required for Qt)
echo "Building OpenSSL 1.0.1k..."
TMPDIR="$(mktemp -d)"
pushd "$TMPDIR"
# OpenSSL 1.0.1k from GitHub releases (only remaining source)
curl -L -o openssl-1.0.1k.tar.gz https://github.com/openssl/openssl/releases/download/OpenSSL_1_0_1k/openssl-1.0.1k.tar.gz
tar xf openssl-1.0.1k.tar.gz
# Handle different archive structures
if [ -d openssl-1.0.1k ]; then
  cd openssl-1.0.1k
elif [ -d openssl-OpenSSL_1_0_1k ]; then
  cd openssl-OpenSSL_1_0_1k
else
  cd openssl-*
fi
./config --prefix="$BUILD_PREFIX" --openssldir="$BUILD_PREFIX/etc/openssl" \
  no-camellia no-capieng no-cast no-cms no-dtls1 no-gost no-gmp no-heartbeats \
  no-idea no-jpake no-krb5 no-md2 no-mdc2 no-rc5 no-rdrand no-rfc3779 no-rsax \
  no-sctp no-seed no-sha0 no-static_engine no-whirlpool no-rc2 no-rc4 no-ssl2 no-ssl3
make -j"$CORES" 2>&1 | tee build.log
if [ ${PIPESTATUS[0]} -ne 0 ]; then
  handle_build_error "OpenSSL" "build" ${PIPESTATUS[0]}
fi
make install 2>&1 | tee -a build.log
if [ ${PIPESTATUS[0]} -ne 0 ]; then
  handle_build_error "OpenSSL" "install" ${PIPESTATUS[0]}
fi
echo "OpenSSL 1.0.1k build completed successfully"
popd
rm -rf "$TMPDIR"

# 5) Build zlib (required for Qt)
echo "Building zlib..."
TMPDIR="$(mktemp -d)"
pushd "$TMPDIR"
curl -L -o zlib-1.2.11.tar.gz https://zlib.net/fossils/zlib-1.2.11.tar.gz
tar xf zlib-1.2.11.tar.gz
cd zlib-1.2.11
./configure --prefix="$BUILD_PREFIX" --static
make -j"$CORES" 2>&1 | tee build.log
if [ ${PIPESTATUS[0]} -ne 0 ]; then
  handle_build_error "zlib" "build" ${PIPESTATUS[0]}
fi
make install 2>&1 | tee -a build.log
if [ ${PIPESTATUS[0]} -ne 0 ]; then
  handle_build_error "zlib" "install" ${PIPESTATUS[0]}
fi
popd
rm -rf "$TMPDIR"

# 6) Build Berkeley DB 4.8.30
echo "Building Berkeley DB 4.8.30..."
TMPDIR="$(mktemp -d)"
pushd "$TMPDIR"
curl -L -o db-4.8.30.NC.tar.gz http://download.oracle.com/berkeley-db/db-4.8.30.NC.tar.gz
tar xf db-4.8.30.NC.tar.gz
cd db-4.8.30.NC/build_unix
# Fix atomic issues on modern systems
sed -i.bak 's/__atomic_compare_exchange/__atomic_compare_exchange_db/' ../dbinc/atomic.h
sed -i.bak 's/atomic_init/atomic_init_db/' ../dbinc/atomic.h ../mp/mp_region.c ../mp/mp_mvcc.c ../mp/mp_fget.c ../mutex/mut_method.c ../mutex/mut_tas.c
../dist/configure --prefix="$BUILD_PREFIX" --disable-shared --enable-cxx --disable-replication --with-pic
make -j"$CORES" libdb_cxx-4.8.a libdb-4.8.a 2>&1 | tee build.log
if [ ${PIPESTATUS[0]} -ne 0 ]; then
  handle_build_error "Berkeley DB" "build" ${PIPESTATUS[0]}
fi
make install_lib install_include 2>&1 | tee -a build.log
if [ ${PIPESTATUS[0]} -ne 0 ]; then
  handle_build_error "Berkeley DB" "install" ${PIPESTATUS[0]}
fi
popd
rm -rf "$TMPDIR"

# 7) Build libevent 2.1.8
echo "Building libevent 2.1.8..."
TMPDIR="$(mktemp -d)"
pushd "$TMPDIR"
curl -L -o libevent-2.1.8-stable.tar.gz https://github.com/libevent/libevent/releases/download/release-2.1.8-stable/libevent-2.1.8-stable.tar.gz
tar xf libevent-2.1.8-stable.tar.gz
cd libevent-2.1.8-stable
./configure --prefix="$BUILD_PREFIX" --disable-shared --with-pic --disable-samples
make -j"$CORES"
make install
popd
rm -rf "$TMPDIR"

# 8) Build ZeroMQ 4.1.5
echo "Building ZeroMQ 4.1.5..."
TMPDIR="$(mktemp -d)"
pushd "$TMPDIR"
curl -L -o zeromq-4.1.5.tar.gz https://github.com/zeromq/zeromq4-1/releases/download/v4.1.5/zeromq-4.1.5.tar.gz
tar xf zeromq-4.1.5.tar.gz
cd zeromq-4.1.5
./configure --prefix="$BUILD_PREFIX" --without-documentation --disable-shared --without-libsodium --disable-curve --with-pic
make -j"$CORES"
make install
popd
rm -rf "$TMPDIR"

# 9) Build Boost 1.63.0 (original version, no modifications)
echo "Building Boost 1.63.0..."
TMPDIR="$(mktemp -d)"
pushd "$TMPDIR"
curl -L -o boost_1_63_0.tar.bz2 https://sourceforge.net/projects/boost/files/boost/1.63.0/boost_1_63_0.tar.bz2/download
tar xf boost_1_63_0.tar.bz2
cd boost_1_63_0
echo "using gcc : : $CXX : <cxxflags>\"-std=c++11 -fvisibility=hidden -fPIC\" ;" > user-config.jam
./bootstrap.sh --without-icu --with-libraries=chrono,filesystem,program_options,system,thread,test
./b2 -d2 -j"$CORES" --prefix="$BUILD_PREFIX" --user-config=user-config.jam \
  variant=release link=static threading=multi runtime-link=shared \
  cxxflags="-std=c++11 -fvisibility=hidden -fPIC" install
popd
rm -rf "$TMPDIR"

# 10) Build BLS v20181101 (original version, no modifications)
echo "Building BLS v20181101..."
TMPDIR="$(mktemp -d)"
pushd "$TMPDIR"
curl -L -o v20181101.tar.gz https://github.com/codablock/bls-signatures/archive/v20181101.tar.gz
tar xf v20181101.tar.gz
cd bls-signatures-20181101
cmake -DCMAKE_INSTALL_PREFIX="$BUILD_PREFIX" -DCMAKE_PREFIX_PATH="$BUILD_PREFIX" \
      -DSTLIB=ON -DSHLIB=OFF -DSTBIN=OFF \
      -DBUILD_TESTS=OFF -DBUILD_BENCHMARKS=OFF -DBENCHMARK=OFF -DTESTS=OFF \
      -DCMAKE_C_COMPILER="$CC" -DCMAKE_CXX_COMPILER="$CXX" .
cmake --build . --target chiabls -- -j"$CORES"
# Manual install to avoid test dependencies
install -Dm644 libchiabls.a "$BUILD_PREFIX/lib/libchiabls.a"
mkdir -p "$BUILD_PREFIX/include/chiabls"
cp -a src/*.hpp "$BUILD_PREFIX/include/chiabls/"
popd
rm -rf "$TMPDIR"

# 11) Clone and build the project
echo "Cloning and building HelpTheHomeless..."
if [ ! -d helpthehomelesscoin ]; then
  git clone --branch "$REPO_BRANCH" --depth 1 "$REPO_URL" helpthehomelesscoin
fi
cd helpthehomelesscoin

# Configure with our built dependencies
./autogen.sh
./configure \
  --prefix="$BUILD_PREFIX" \
  --with-gui=no \
  --enable-wallet \
  --with-incompatible-bdb \
  CC="$CC" CXX="$CXX" \
  CPPFLAGS="-I$BUILD_PREFIX/include" \
  LDFLAGS="-L$BUILD_PREFIX/lib" \
  BOOST_ROOT="$BUILD_PREFIX" \
  BDB_CFLAGS="-I$BUILD_PREFIX/include" \
  BDB_LIBS="-L$BUILD_PREFIX/lib -ldb_cxx-4.8"

make -j"$CORES"

echo "Build complete! Binaries are in src/"
echo "All dependencies built in: $BUILD_PREFIX"
