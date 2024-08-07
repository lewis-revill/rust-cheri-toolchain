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

# Build appropriate SDKs

if [ "${FREEBSD_TARGET}" == "yes" ]; then
  (
    set -e
    cd ${TOPDIR}/cheribuild
    ./cheribuild.py cheribsd-sdk-morello-purecap --qemu/no-use-smbd --skip-update
  )
  PATH=${HOME}/cheri/output/morello-sdk/bin:${PATH}
fi

if [ "${LINUX_TARGET}" == "yes" ]; then
  (
    set -e
    cd ${TOPDIR}/morello-sdk/morello
    ./scripts/build-all.sh --x86_64 --rootfs --build-lib --install --clean
  )
  (
    set -e
    cd ${HOME}/morello/llvm/bin
    ln -sf ar aarch64-unknown-linux-musl_purecap-ar
    ln -sf clang aarch64-unknown-linux-musl_purecap-clang
    ln -sf clang++ aarch64-unknown-linux-musl_purecap-clang++
    ln -sf clang aarch64-unknown-linux-musl_purecap-cc
    ln -sf lld aarch64-unknown-linux-musl_purecap-lld
    ln -sf ld.lld aarch64-unknown-linux-musl_purecap-ld.lld
  )
  PATH=${HOME}/morello/llvm/bin:${PATH}
fi

# Build Rust for appropriate Morello targets.
TARGETS_STR=""
if [ "${LINUX_TARGET}" == "yes" ]; then
  TARGETS_STR="--target=morello-unknown-linux-purecap ${TARGETS_STR}"
fi
if [ "${FREEBSD_TARGET}" == "yes" ]; then
  TARGETS_STR="--target=morello-unknown-freebsd-purecap ${TARGETS_STR}"
fi

(
  set -e
  cd ${TOPDIR}/rust
  cp config.toml.morello config.toml
  rm Cargo.lock
  ./x.py build ${TARGETS_STR} library/std || true
  cargo update -p url@2.5.2 --precise 2.5.0
  cargo update -p tinystr@0.7.6 --precise 0.7.1
  cargo update -p tracing-tree@0.2.5 --precise 0.2.4
  cargo update -p home@0.5.9 --precise 0.5.5
  cargo update -p thiserror@1.0.63 --precise 1.0.59
  cargo update -p serde_json@1.0.120 --precise 1.0.116
  cargo update -p mdbook@0.4.37 --precise 0.4.36
  cargo update -p crossbeam-utils@0.8.20 --precise 0.8.19
  (
    cd src/bootstrap
    cargo update -p home@0.5.9 --precise 0.5.5
  )
  ./x.py build ${TARGETS_STR} library/std
)

# Can we copy from the build directory to an install directory?

# Optionally, build the remote-test-server binary for Morello.
(
  set -e
  cd ${TOPDIR}/rust
  ./x.py build ${TARGETS_STR} src/tools/remote-test-server
)


