#!/bin/bash
# Script for checking out sources of branches

# Variables used in this script
TOPDIR="$(realpath $(dirname $0)/../../)"
CHECKOUT=yes
PULL=no
LINUX_TARGET=yes
FREEBSD_TARGET=yes
TOOLCHAIN_OVERRIDE=""
CHERIBUILD_OVERRIDE=""
MORELLO_SDK_OVERRIDE=""
RUST_OVERRIDE=""
RETVAL=0

# Load up set of expected branches
source "${TOPDIR}/toolchain/scripts/EXPECTED_BRANCHES"

for opt in ${@}; do
  valid_arg=1
  case ${opt} in
  "--checkout")
    CHECKOUT=yes
    ;;
  "--no-checkout")
    CHECKOUT=no
    ;;
  "--pull")
    PULL=yes
    ;;
  "--no-pull")
    PULL=no
    ;;
  --toolchain-branch=*)
    TOOLCHAIN_OVERRIDE="${opt#*=}"
    ;;
  --cheribuild-branch=*)
    CHERIBUILD_OVERRIDE="${opt#*=}"
    ;;
  --morello-sdk-branch=*)
    MORELLO_SDK_OVERRIDE="${opt#*=}"
    ;;
  --rust-branch=*)
    RUST_OVERRIDE="${opt#*=}"
    ;;
  "--help")
    valid_arg=0
    ;;& # Fallthrough
  *)
    echo "Usage for $0:"
    echo "  --checkout                   Run git checkout on branch. [Default]"
    echo "  --no-checkout                Don't run git checkout on branch."
    echo "  --pull                       Run git pull on branch."
    echo "  --no-pull                    Don't run git pull on branch. [Default]"
    echo "  --linux                      Assume we're building a toolchain for Morello Linux [Default]"
    echo "  --no-linux                   Assume we're not building a toolchain for Morello Linux"
    echo "  --freebsd                    Assume we're building a toolchain for Morello FreeBSD [Default]"
    echo "  --no-freebsd                 Assume we're not building a toolchain for Morello FreeBSD"
    echo "  --toolchain-branch=<branch>  Use <branch> for the toolchain repository"
    echo "  --cheribuild-branch=<branch> Use <branch> for the cheribuild repository"
    echo "  --morello-sdk-branch=<branch> Use <branch> for the morello-sdk repository"
    echo "  --rust-branch=<branch>       Use <branch> for the rust repository"
    echo "  --help                       Present this message."
    exit $valid_arg
    ;;
  esac
done

processBranch() {(
  set -e
  echo "* Processing directory ${1}"
  cd ${TOPDIR}/${1}
  THISBRANCH=$(git rev-parse --abbrev-ref HEAD)
  echo "  Current branch: ${THISBRANCH}"
  # If pull is enabled, do a fetch first in case the target branch did
  # not exist before this script was invoked.
  if [ "${PULL}" == "yes" ]; then
    echo "  Fetching sources for repo"
    (set +x; git fetch)
  fi
  if [ "${CHECKOUT}" == "yes" ]; then
    echo "  Checking out branch '${2}'"
    (set +x; git checkout "${2}")
  fi
  if [ "${PULL}" == "yes" ]; then
    echo "  Pulling sources for branch"
    (set +x; git pull --ff-only)
  fi
)
if [ $? -ne 0 ]; then
  echo "  ** Error checking out directory ${1} **"
  RETVAL=1
fi
}

# First update the toolchain script, then re-source the expected branches in
# case these changed as a result of the processing.
source "${TOPDIR}/toolchain/scripts/EXPECTED_BRANCHES"
if [ -n "${TOOLCHAIN_OVERRIDE}" ]; then
  EXPECTED_TOOLCHAIN=${TOOLCHAIN_OVERRIDE}
fi
processBranch toolchain ${EXPECTED_TOOLCHAIN}

source "${TOPDIR}/toolchain/scripts/EXPECTED_BRANCHES"
if [ -n "${MORELLO_SDK_OVERRIDE}" ]; then
  EXPECTED_MORELLO_SDK=${MORELLO_SDK_OVERRIDE}
fi
if [ "${LINUX_TARGET}" == "yes" ]; then
  processBranch morello-sdk ${EXPECTED_MORELLO_SDK}
fi
if [ -n "${CHERIBUILD_OVERRIDE}" ]; then
  EXPECTED_CHERIBUILD=${CHERIBUILD_OVERRIDE}
fi
if [ "${FREEBSD_TARGET}" == "yes" ]; then
  processBranch cheribuild ${EXPECTED_CHERIBUILD}
fi
if [ -n "${RUST_OVERRIDE}" ]; then
  EXPECTED_RUST=${RUST_OVERRIDE}
fi
processBranch rust ${EXPECTED_RUST}

exit ${RETVAL}
