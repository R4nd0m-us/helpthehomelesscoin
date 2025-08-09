package=chia_bls
$(package)_version=v20181101
# It's actually from https://github.com/Chia-Network/bls-signatures, but we have so many patches atm that it's forked
$(package)_download_path=https://github.com/codablock/bls-signatures/archive
$(package)_file_name=$($(package)_version).tar.gz
$(package)_sha256_hash=b3ec74a77a7b6795f84b05e051a0824ef8d9e05b04b2993f01040f35689aa87c
$(package)_dependencies=gmp
#$(package)_patches=...TODO (when we switch back to https://github.com/Chia-Network/bls-signatures)

# Work around GCC 13+ alignment errors in relic's BLAKE2 by avoiding arrays-of-1 of aligned types
# See errors like: size of array element is not a multiple of its alignment
# This sed-based patch is scoped narrowly to v20181101 layout

define $(package)_preprocess_cmds
  sed -i.bak 's/blake2s_state S\[8\]\[1\];/blake2s_state S[8];/' contrib/relic/src/md/blake2.h && \
  sed -i.bak 's/blake2s_state R\[1\];/blake2s_state R;/' contrib/relic/src/md/blake2.h && \
  sed -i.bak 's/blake2b_state S\[4\]\[1\];/blake2b_state S[4];/' contrib/relic/src/md/blake2.h && \
  sed -i.bak 's/blake2b_state R\[1\];/blake2b_state R;/' contrib/relic/src/md/blake2.h && \
  sed -i.bak 's/blake2s_state S\[1\];/blake2s_state S;/' contrib/relic/src/md/blake2s-ref.c
endef

define $(package)_set_vars
  $(package)_config_opts=-DCMAKE_INSTALL_PREFIX=$($(package)_staging_dir)/$(host_prefix)
  $(package)_config_opts+= -DCMAKE_PREFIX_PATH=$($(package)_staging_dir)/$(host_prefix)
  $(package)_config_opts+= -DSTLIB=ON -DSHLIB=OFF -DSTBIN=ON
  $(package)_config_opts_linux=-DOPSYS=LINUX -DCMAKE_SYSTEM_NAME=Linux
  $(package)_config_opts_darwin=-DOPSYS=MACOSX -DCMAKE_SYSTEM_NAME=Darwin
  $(package)_config_opts_mingw32=-DOPSYS=WINDOWS -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_SHARED_LIBRARY_LINK_C_FLAGS="" -DCMAKE_SHARED_LIBRARY_LINK_CXX_FLAGS=""
  $(package)_config_opts_i686+= -DWSIZE=32
  $(package)_config_opts_x86_64+= -DWSIZE=64
  $(package)_config_opts_arm+= -DWSIZE=32
  $(package)_config_opts_armv7l+= -DWSIZE=32
  $(package)_config_opts_debug=-DDEBUG=ON -DCMAKE_BUILD_TYPE=Debug

  ifneq ($(darwin_native_toolchain),)
    $(package)_config_opts_darwin+= -DCMAKE_AR="$(host_prefix)/native/bin/$($(package)_ar)"
    $(package)_config_opts_darwin+= -DCMAKE_RANLIB="$(host_prefix)/native/bin/$($(package)_ranlib)"
  endif
endef

define $(package)_config_cmds
  export CC="$($(package)_cc)" && \
  export CXX="$($(package)_cxx)" && \
  export CFLAGS="$($(package)_cflags) $($(package)_cppflags)" && \
  export CXXFLAGS="$($(package)_cxxflags) $($(package)_cppflags)" && \
  export LDFLAGS="$($(package)_ldflags)" && \
  mkdir -p build && cd build && \
  cmake ../ $($(package)_config_opts)
endef

define $(package)_build_cmds
  cd build && \
  $(MAKE) $($(package)_build_opts)
endef

define $(package)_stage_cmds
  cd build && \
  $(MAKE) install
endef
