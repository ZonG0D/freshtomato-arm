#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: tools/scripts/build-wrapper.sh [--clean] <sdk-path> <target> [target...]

Examples:
  tools/scripts/build-wrapper.sh --clean release/src-rt-6.x.4708 n18z
  tools/scripts/build-wrapper.sh release/src-rt-7.x.main/src ac3200-128z
  tools/scripts/build-wrapper.sh release/src-rt-7.14.114.x/src ac5300-128z
USAGE
}

clean=0
if [[ ${1:-} == "--clean" ]]; then
  clean=1
  shift
fi

if [[ $# -lt 2 ]]; then
  usage
  exit 2
fi

sdk_path=$1
shift

if [[ ! -d $sdk_path ]]; then
  echo "error: sdk path not found: $sdk_path" >&2
  exit 1
fi

export LANG=C
export LC_ALL=C
export TZ=UTC

umask 022

echo "[build-wrapper] sdk=${sdk_path} targets=$*"

if [[ $clean -eq 1 ]]; then
  echo "[build-wrapper] cleaning tree"
  git clean -fdxq
  git reset --hard
fi

echo "[build-wrapper] invoking: make -C \"$sdk_path\" $*"

make -C "$sdk_path" "$@"
