#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAC_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLIENTS_ROOT="$(cd "$MAC_ROOT/.." && pwd)"
SOURCE_ROOT="$CLIENTS_ROOT/windows"
PACKAGE_SCRIPT="$SCRIPT_DIR/package-macos.sh"

OUTPUT_ZIP=""
STAGE_DIR=""
CHECKSUM="on"
BUILD_JOBS=""
BINARY_PATH=""

usage() {
  cat <<'EOF'
Usage: build-and-package-macos-arm64.sh [options]

Options:
  --binary-path PATH   Optional explicit path for packaging step
  --output-zip PATH    Output zip path for packaging step
  --stage-dir PATH     Packaging stage directory
  --checksum on|off    Create checksum file during packaging (default: on)
  --build-jobs N       Optional parallel jobs for cmake build
  --help               Show this help
EOF
}

fail() {
  echo "Error: $*" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --binary-path)
      [[ $# -ge 2 ]] || fail "--binary-path requires a value"
      BINARY_PATH="$2"
      shift 2
      ;;
    --output-zip)
      [[ $# -ge 2 ]] || fail "--output-zip requires a value"
      OUTPUT_ZIP="$2"
      shift 2
      ;;
    --stage-dir)
      [[ $# -ge 2 ]] || fail "--stage-dir requires a value"
      STAGE_DIR="$2"
      shift 2
      ;;
    --checksum)
      [[ $# -ge 2 ]] || fail "--checksum requires on or off"
      CHECKSUM="$2"
      shift 2
      ;;
    --build-jobs)
      [[ $# -ge 2 ]] || fail "--build-jobs requires a value"
      BUILD_JOBS="$2"
      shift 2
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      fail "Unknown option: $1"
      ;;
  esac
done

if [[ "$CHECKSUM" != "on" && "$CHECKSUM" != "off" ]]; then
  fail "--checksum must be on or off"
fi

if ! command -v cmake >/dev/null 2>&1; then
  fail "'cmake' command is required"
fi
if [[ ! -x "$PACKAGE_SCRIPT" ]]; then
  chmod +x "$PACKAGE_SCRIPT"
fi
if [[ ! -d "$SOURCE_ROOT" ]]; then
  fail "OTClient source root not found at '$SOURCE_ROOT'"
fi

pushd "$SOURCE_ROOT" >/dev/null
cmake --preset macos-release -D CMAKE_OSX_ARCHITECTURES=arm64 -D VCPKG_TARGET_TRIPLET=arm64-osx

build_cmd=(cmake --build --preset macos-release)
if [[ -n "$BUILD_JOBS" ]]; then
  build_cmd+=(--parallel "$BUILD_JOBS")
fi
"${build_cmd[@]}"
popd >/dev/null

package_cmd=("$PACKAGE_SCRIPT" --checksum "$CHECKSUM")
if [[ -n "$BINARY_PATH" ]]; then
  package_cmd+=(--binary-path "$BINARY_PATH")
fi
if [[ -n "$OUTPUT_ZIP" ]]; then
  package_cmd+=(--output-zip "$OUTPUT_ZIP")
fi
if [[ -n "$STAGE_DIR" ]]; then
  package_cmd+=(--stage-dir "$STAGE_DIR")
fi
"${package_cmd[@]}"
