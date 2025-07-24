# Copyright (c) 2011 The LevelDB Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file. See the AUTHORS file for names of contributors.

# Production use (optimized mode)
OPT ?= -O2 -DNDEBUG

# Generate build_config.mk if it doesn't exist
build_config.mk:
    @echo "Generating build_config.mk..."
    CC="$(CC)" CXX="$(CXX)" TARGET_OS="$(TARGET_OS)" ./build_detect_platform build_config.mk ./

# Include the generated config
-include build_config.mk

# Set default sources if build_config.mk failed to generate
SOURCES ?= \
    db/builder.cc \
    db/c.cc \
    db/dbformat.cc \
    db/db_impl.cc \
    db/db_iter.cc \
    db/dumpfile.cc \
    db/filename.cc \
    db/log_reader.cc \
    db/log_writer.cc \
    db/memtable.cc \
    db/repair.cc \
    db/table_cache.cc \
    db/version_edit.cc \
    db/version_set.cc \
    db/write_batch.cc \
    table/block_builder.cc \
    table/block.cc \
    table/filter_block.cc \
    table/format.cc \
    table/iterator.cc \
    table/merger.cc \
    table/table_builder.cc \
    table/table.cc \
    table/two_level_iterator.cc \
    util/arena.cc \
    util/bloom.cc \
    util/cache.cc \
    util/coding.cc \
    util/comparator.cc \
    util/crc32c.cc \
    util/env.cc \
    util/filter_policy.cc \
    util/hash.cc \
    util/histogram.cc \
    util/logging.cc \
    util/options.cc \
    util/status.cc \
    port/port_posix.cc

MEMENV_SOURCES ?= helpers/memenv/memenv.cc

# Set defaults if not defined
STATIC_OUTDIR ?= out-static
PLATFORM_CCFLAGS ?= 
PLATFORM_CXXFLAGS ?= 
PLATFORM_LDFLAGS ?= 
PLATFORM_LIBS ?= 

CFLAGS += -I. -I./include $(PLATFORM_CCFLAGS) $(OPT)
CXXFLAGS += -I. -I./include $(PLATFORM_CXXFLAGS) $(OPT)

STATIC_LIBOBJECTS := $(addprefix $(STATIC_OUTDIR)/, $(SOURCES:.cc=.o))
STATIC_MEMENVOBJECTS := $(addprefix $(STATIC_OUTDIR)/, $(MEMENV_SOURCES:.cc=.o))

# Default target
default: libleveldb.a libmemenv.a

# Create output directory
$(STATIC_OUTDIR):
    mkdir -p $(STATIC_OUTDIR)
    mkdir -p $(STATIC_OUTDIR)/db
    mkdir -p $(STATIC_OUTDIR)/table
    mkdir -p $(STATIC_OUTDIR)/util
    mkdir -p $(STATIC_OUTDIR)/port
    mkdir -p $(STATIC_OUTDIR)/helpers/memenv

# Build static libraries
libleveldb.a: build_config.mk $(STATIC_OUTDIR) $(STATIC_LIBOBJECTS)
    rm -f $@
    $(AR) -rs $@ $(STATIC_LIBOBJECTS)

libmemenv.a: build_config.mk $(STATIC_OUTDIR) $(STATIC_MEMENVOBJECTS)
    rm -f $@
    $(AR) -rs $@ $(STATIC_MEMENVOBJECTS)

# Object file rules
$(STATIC_OUTDIR)/%.o: %.cc
    $(CXX) $(CXXFLAGS) -c $< -o $@

clean:
    rm -rf $(STATIC_OUTDIR) libleveldb.a libmemenv.a build_config.mk
