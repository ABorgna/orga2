#!/bin/sh
#
# .conf.linux
#

#which_config=normal
which_config=plugins

CC="gcc"
CXX="c++"
CFLAGS="-Wall -O3 -fomit-frame-pointer -pipe"    # for speed
#CFLAGS="-Wall -g -pipe"                         # for development
CXXFLAGS="$CFLAGS"

export CC
export CXX
export CFLAGS
export CXXFLAGS

#######################################################################
# configuration 2 for release binary RPMs
# Include plugins, every possible gui.
#######################################################################
./configure --enable-sb16 \
            --enable-ne2000 \
            --enable-all-optimizations \
            --enable-cpu-level=6 \
            --enable-x86-64 \
            --enable-vmx=2 \
            --enable-pci \
            --enable-clgd54xx \
            --enable-voodoo \
            --enable-es1370 \
            --enable-e1000 \
            --enable-plugins \
            --enable-show-ips \
            --enable-debugger \
            ${CONFIGURE_ARGS}

sed -i -- 's/BX_NETMOD_FBSD 1/BX_NETMOD_FBSD 0/g' ./config.h

