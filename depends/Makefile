# Top-level Makefile for Help The Homeless Coin
# Builds everything from dependencies to final binaries

.PHONY: all clean install-deps build-deps configure build install

# Detect Ubuntu version and set packages accordingly
UBUNTU_VERSION := $(shell lsb_release -rs 2>/dev/null || echo "22.04")
HOST := x86_64-unknown-linux-gnu
MAKEJOBS := -j$(shell nproc)

# Default target
all: build

# Install system dependencies
install-deps:
    @echo "Installing system dependencies for Ubuntu $(UBUNTU_VERSION)..."
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
        git \
        ccache \
        libgmp-dev \
        libssl-dev \
        libevent-dev \
        libboost-all-dev \
        libdb5.3-dev \
        libdb5.3++-dev \
        libminiupnpc-dev \
        libzmq3-dev \
        libqrencode-dev \
        zlib1g-dev

# Build all dependencies (including BLS)
build-deps: install-deps
    @echo "Building dependencies..."
    cd depends && $(MAKE) $(MAKEJOBS) HOST=$(HOST)

# Configure the build
configure: build-deps
    @echo "Configuring build..."
    @if [ ! -f configure ]; then ./autogen.sh; fi
    ./configure \
        --prefix=$(PWD)/depends/$(HOST) \
        --disable-dependency-tracking \
        --enable-glibc-back-compat \
        --enable-reduce-exports \
        --disable-bench \
        --disable-gui-tests \
        --with-gui=no

# Build the main project
build: configure
    @echo "Building Help The Homeless Coin..."
    $(MAKE) $(MAKEJOBS)
    @echo ""
    @echo "Build complete! Binaries are available:"
    @echo "  ./src/helpthehomelessd"
    @echo "  ./src/helpthehomeless-cli"
    @echo "  ./src/helpthehomeless-tx"

# Install binaries to system
install: build
    $(MAKE) install
    @echo "Binaries installed to $(PWD)/depends/$(HOST)/bin/"

# Clean everything
clean:
    @if [ -f Makefile.in ]; then $(MAKE) clean; fi
    cd depends && $(MAKE) clean
    rm -f configure config.log config.status
    rm -rf autom4te.cache/

# Complete clean including dependencies
distclean: clean
    cd depends && $(MAKE) distclean

# Quick build using system libraries (for development)
quick: install-deps
    @echo "Quick build using system libraries..."
    @if [ ! -f configure ]; then ./autogen.sh; fi
    ./configure \
        --with-incompatible-bdb \
        --disable-bench \
        --disable-gui-tests \
        --with-gui=no \
        CPPFLAGS="-I/usr/include" \
        LDFLAGS="-L/usr/lib/x86_64-linux-gnu"
    $(MAKE) $(MAKEJOBS)
    @echo "Quick build complete! Note: This may fail due to missing BLS library."

# Help target
help:
    @echo "Available targets:"
    @echo "  all        - Full build (default)"
    @echo "  install-deps - Install Ubuntu system dependencies"
    @echo "  build-deps - Build all dependencies including BLS"
    @echo "  configure  - Configure the build"
    @echo "  build      - Build the main project"
    @echo "  install    - Install binaries"
    @echo "  quick      - Quick build using system libraries"
    @echo "  clean      - Clean build files"
    @echo "  distclean  - Clean everything including dependencies"
    @echo "  help       - Show this help"
