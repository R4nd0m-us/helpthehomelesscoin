# Top-level Makefile wrapper
# This builds dependencies first, then the main project

.PHONY: all clean depends configure build install

# Default target
all: build

# Build dependencies
depends:
    @echo "Building dependencies..."
    $(MAKE) -C depends HOST=x86_64-unknown-linux-gnu -j$$(nproc)

# Configure the build
configure: depends
    @if [ ! -f configure ]; then ./autogen.sh; fi
    @if [ ! -f Makefile.real ]; then \
        ./configure --prefix=$$(pwd)/depends/x86_64-unknown-linux-gnu \
                    --disable-dependency-tracking \
                    --enable-glibc-back-compat \
                    --enable-reduce-exports \
                    --disable-bench \
                    --disable-gui-tests \
                    --with-gui=no && \
        mv Makefile Makefile.real; \
    fi

# Build the main project
build: configure
    @echo "Building main project..."
    $(MAKE) -f Makefile.real -j$$(nproc)

# Install
install: build
    $(MAKE) -f Makefile.real install

# Clean everything
clean:
    @if [ -f Makefile.real ]; then $(MAKE) -f Makefile.real clean; fi
    $(MAKE) -C depends clean
    rm -f Makefile.real

# Clean dependencies too
distclean: clean
    $(MAKE) -C depends distclean
    rm -f configure config.log config.status
