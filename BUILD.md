# HelpTheHomeless Coin Robust Build System

This document provides instructions for building HelpTheHomeless Coin on Ubuntu 22.04 and 24.04 using the robust makefile.unix system that handles failures and provides multiple build strategies.

## Quick Start

To build HelpTheHomeless Coin with automatic failure recovery:

```bash
make
```

This robust build system will automatically:
1. Check your system environment
2. Install system dependencies with fallbacks
3. Try multiple build strategies (depends → system → minimal)
4. Handle common failures and provide recovery options
5. Verify the final binaries work correctly

## Build Strategies

The robust build system supports multiple strategies with automatic fallbacks:

### Auto Strategy (Default)
```bash
make                    # Tries depends, then system, then minimal
```

### Force Specific Strategy
```bash
make BUILD_STRATEGY=depends   # Most robust, builds all deps from source
make BUILD_STRATEGY=system    # Uses system libraries (faster)
make BUILD_STRATEGY=minimal   # Minimal build (fastest, may have issues)
```

## System Requirements

- **Operating System**: Ubuntu 22.04 LTS or Ubuntu 24.04 LTS
- **RAM**: At least 4GB (8GB recommended)
- **Disk Space**: At least 10GB free space
- **Internet Connection**: Required for downloading dependencies
- **Sudo Access**: Required for installing system packages

## Build Targets

### Full Build (Recommended)
```bash
make
```
This performs a complete build using the depends system, which ensures all dependencies are built with compatible versions.

### Quick Development Build
```bash
make quick
```
This uses system-installed libraries for faster builds during development. Note: May fail if system libraries are incompatible.

### Individual Steps
```bash
make install-deps    # Install Ubuntu system dependencies
make build-deps      # Build all dependencies using depends system
make configure       # Configure the build
make build          # Build the main project
make install        # Install binaries to depends prefix
```

### Testing
```bash
make test           # Run tests after building
```

### Cleaning
```bash
make clean          # Clean build files
make distclean      # Clean everything including dependencies
```

## Build Output

After a successful build, the following binaries will be available:

- `./src/helpthehomelessd` - The daemon/node software
- `./src/helpthehomeless-cli` - Command-line interface
- `./src/helpthehomeless-tx` - Transaction utility

## Dependencies

The build system automatically handles the following dependencies:

### System Dependencies (installed via apt)
- build-essential
- libtool, autotools-dev, automake
- pkg-config, bsdmainutils
- python3, cmake
- curl, wget, git
- ccache (for faster rebuilds)
- Various development libraries (boost, openssl, etc.)

### Built Dependencies (via depends system)
- Boost libraries
- OpenSSL
- libevent
- ZeroMQ
- GMP (for BLS signatures)
- BLS signatures library (Chia/codablock fork)
- Berkeley DB 4.8
- And many others...

## Troubleshooting

The robust build system includes comprehensive error handling and recovery options.

### Automatic Recovery

If a build fails, the system will automatically:
1. Try alternative build strategies
2. Reduce parallel jobs if memory issues occur
3. Provide specific error messages and solutions

### Manual Recovery Commands

#### Get Help for Build Failures
```bash
make build-failure-help    # Shows detailed recovery options
```

#### Fix Library Version Issues
```bash
make fix-library-links     # Fixes boost version conflicts
```

#### Check System Status
```bash
make check-env            # Check system environment
make check-deps           # Verify dependencies
make verify-binaries      # Check if binaries work
```

#### Clean Rebuilds
```bash
make clean                # Clean build files only
make distclean            # Clean everything including dependencies
```

### Common Issues and Solutions

#### 1. Library Version Conflicts (e.g., boost 1.71 vs 1.74)
```bash
# Automatic fix
make fix-library-links

# Or force system libraries
make clean && make BUILD_STRATEGY=system

# Or minimal build
make clean && make BUILD_STRATEGY=minimal
```

#### 2. Memory/Resource Issues
```bash
# Single-threaded build
make MAKEJOBS=-j1

# Or try minimal build
make BUILD_STRATEGY=minimal
```

#### 3. Network/Download Issues
```bash
# Check connection and retry
make distclean && make

# Or use system libraries to avoid downloads
make BUILD_STRATEGY=system
```

#### 4. Permission Issues
```bash
# Fix ownership and retry
sudo chown -R $USER:$USER .
make clean && make
```

#### 5. Dependency Installation Failures
```bash
# Manual dependency check
make check-deps

# Force dependency reinstall
sudo apt update && make install-deps
```

#### 6. Configure/Autogen Failures
```bash
# Clean and retry
make distclean
./autogen.sh
make BUILD_STRATEGY=system
```

### Build Logs and Debugging

Build logs are available in:
- `config.log` - Configuration log
- `depends/work/` - Dependency build logs
- Terminal output shows detailed progress

### Getting Help

If you encounter issues:

1. **First**: Run `make build-failure-help` for automated solutions
2. **Check**: System requirements and available disk space/memory
3. **Try**: Different build strategies (`depends`, `system`, `minimal`)
4. **Clean**: `make distclean && make` for a fresh start
5. **Fix**: Library issues with `make fix-library-links`

## Advanced Usage

### Cross-compilation

The depends system supports cross-compilation. See `doc/build-cross.md` for details.

### Custom Configuration

You can pass additional configure flags:
```bash
./configure --help  # See all available options
```

### Using System Libraries

For development, you can use system libraries instead of building everything:
```bash
make quick
```

This is faster but may have compatibility issues.

## File Structure

- `makefile.unix` - Main build file for Ubuntu
- `Makefile` - Simple wrapper that includes makefile.unix
- `depends/` - Dependency build system
- `src/` - Source code
- `doc/` - Documentation
- `test-build.sh` - Build system test script

## Notes

- This build system is specifically designed for Ubuntu 22.04/24.04
- The first build will take significant time (30+ minutes) as it builds all dependencies
- Subsequent builds are much faster due to caching
- The depends system ensures reproducible builds across different environments
