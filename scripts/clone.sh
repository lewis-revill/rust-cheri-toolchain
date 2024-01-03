#!/bin/bash
# Script for checking out sources of branches

# Variables used in this script
TOPDIR="$(realpath $(dirname $0)/../../)"
LINUX_TARGET=yes
FREEBSD_TARGET=yes

for opt in ${@}; do
  valid_arg=1
  case ${opt} in
  "--linux")
    LINUX_TARGET=yes
    ;;
  "--no-linux")
    LINUX_TARGET=no
    ;;
  "--freebsd")
    FREEBSD_TARGET=yes
    ;;
  "--no-freebsd")
    FREEBSD_TARGET=no
    ;;
  "--help")
    valid_arg=0
    ;;&
  *)
    echo "Usage for $0:"
    echo "  --linux                      Assume we're building a toolchain for Morello Linux [Default]"
    echo "  --no-linux                   Assume we're not building a toolchain for Morello Linux"
    echo "  --freebsd                    Assume we're building a toolchain for Morello FreeBSD [Default]"
    echo "  --no-freebsd                 Assume we're not building a toolchain for Morello FreeBSD"
    echo "  --help                       Present this message."
    exit $valid_arg
    ;;
  esac
done

if [ ! -d ${TOPDIR}/toolchain ]; then
  git clone https://github.com/lewis-revill/rust-cheri-toolchain.git ${TOPDIR}/toolchain
fi
if [ "${LINUX_TARGET}" == "yes" -a ! -d ${TOPDIR}/morello-sdk ]; then
  git clone https://github.com/lewis-revill/morello-sdk.git ${TOPDIR}/morello-sdk
fi
if [ "${FREEBSD_TARGET}" == "yes" -a ! -d ${TOPDIR}/cheribuild ]; then
  git clone https://github.com/CTSRD-CHERI/cheribuild.git ${TOPDIR}/cheribuild
fi
if [ ! -d ${TOPDIR}/rust ]; then
  git clone https://github.com/CyberHive/rust-cheri.git ${TOPDIR}/rust
fi
