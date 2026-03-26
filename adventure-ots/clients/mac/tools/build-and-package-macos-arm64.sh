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

if [[ "$(uname -s)" != "Darwin" ]]; then
  fail "This script must be run on macOS (Darwin host required)"
fi

prepend_path_if_dir() {
  local dir="$1"
  [[ -d "$dir" ]] || return 0
  case ":$PATH:" in
    *":$dir:"*) ;;
    *) PATH="$dir:$PATH" ;;
  esac
}

prepend_path_if_dir "/opt/homebrew/bin"
prepend_path_if_dir "/usr/local/bin"
export PATH

if ! command -v cmake >/dev/null 2>&1; then
  fail "'cmake' command is required"
fi
if ! command -v ninja >/dev/null 2>&1; then
  fail "'ninja' command is required (install with: brew install ninja)"
fi
if ! command -v pkg-config >/dev/null 2>&1; then
  fail "'pkg-config' command is required (install with: brew install pkg-config)"
fi
if ! xcode-select -p >/dev/null 2>&1; then
  fail "Xcode command line tools are required (run: xcode-select --install)"
fi

if [[ -z "${VCPKG_ROOT:-}" ]]; then
  VCPKG_ROOT="$HOME/.local/share/vcpkg"
fi
if [[ ! -d "$VCPKG_ROOT" ]]; then
  if ! command -v git >/dev/null 2>&1; then
    fail "'git' command is required to clone vcpkg"
  fi
  echo "VCPKG_ROOT not found at '$VCPKG_ROOT'; cloning vcpkg..."
  git clone https://github.com/microsoft/vcpkg.git "$VCPKG_ROOT"
fi

VCPKG_BOOTSTRAP_SCRIPT="$VCPKG_ROOT/bootstrap-vcpkg.sh"
VCPKG_BIN="$VCPKG_ROOT/vcpkg"
VCPKG_TOOLCHAIN_FILE="$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake"

if [[ ! -f "$VCPKG_BOOTSTRAP_SCRIPT" ]]; then
  fail "vcpkg bootstrap script missing at '$VCPKG_BOOTSTRAP_SCRIPT'"
fi
if [[ ! -x "$VCPKG_BIN" ]]; then
  echo "vcpkg executable not found; bootstrapping in '$VCPKG_ROOT'..."
  (cd "$VCPKG_ROOT" && ./bootstrap-vcpkg.sh)
fi

export VCPKG_ROOT
if [[ ! -f "$VCPKG_TOOLCHAIN_FILE" ]]; then
  fail "vcpkg toolchain file not found at '$VCPKG_TOOLCHAIN_FILE'"
fi

if [[ ! -x "$PACKAGE_SCRIPT" ]]; then
  chmod +x "$PACKAGE_SCRIPT"
fi
if [[ ! -d "$SOURCE_ROOT" ]]; then
  fail "OTClient source root not found at '$SOURCE_ROOT'"
fi

OVERLAY_TRIPLETS_DIR="$MAC_ROOT/.local/vcpkg-triplets"
OVERLAY_TRIPLET_FILE="$OVERLAY_TRIPLETS_DIR/arm64-osx-release.cmake"
OVERLAY_PORTS_DIR="$MAC_ROOT/.local/vcpkg-ports"
OVERLAY_INIH_DIR="$OVERLAY_PORTS_DIR/inih"

INIH_UPSTREAM_DIR="$VCPKG_ROOT/ports/inih"
INIH_HELPER_CONFIG_IN="$INIH_UPSTREAM_DIR/unofficial-inihConfig.cmake.in"
INIH_HELPER_USAGE="$INIH_UPSTREAM_DIR/usage"

if [[ -f "$VCPKG_ROOT/triplets/community/arm64-osx.cmake" ]]; then
  VCPKG_BASE_TRIPLET="$VCPKG_ROOT/triplets/community/arm64-osx.cmake"
elif [[ -f "$VCPKG_ROOT/triplets/arm64-osx.cmake" ]]; then
  VCPKG_BASE_TRIPLET="$VCPKG_ROOT/triplets/arm64-osx.cmake"
else
  fail "Could not locate base arm64-osx triplet under '$VCPKG_ROOT/triplets'"
fi

mkdir -p "$OVERLAY_TRIPLETS_DIR"
cat >"$OVERLAY_TRIPLET_FILE" <<EOF
include("$VCPKG_BASE_TRIPLET")
set(VCPKG_BUILD_TYPE release)
EOF

mkdir -p "$OVERLAY_INIH_DIR"

if [[ ! -f "$INIH_HELPER_CONFIG_IN" ]]; then
  fail "Missing helper file '$INIH_HELPER_CONFIG_IN'. Ensure your vcpkg checkout contains ports/inih files or update VCPKG_ROOT."
fi
if [[ ! -f "$INIH_HELPER_USAGE" ]]; then
  fail "Missing helper file '$INIH_HELPER_USAGE'. Ensure your vcpkg checkout contains ports/inih files or update VCPKG_ROOT."
fi

cp "$INIH_HELPER_CONFIG_IN" "$OVERLAY_INIH_DIR/unofficial-inihConfig.cmake.in"
cp "$INIH_HELPER_USAGE" "$OVERLAY_INIH_DIR/usage"

cat >"$OVERLAY_INIH_DIR/vcpkg.json" <<'EOF'
{
  "name": "inih",
  "version": "58",
  "description": "simple .INI file parser in C",
  "homepage": "https://github.com/benhoyt/inih",
  "license": "BSD-3-Clause",
  "features": {
    "cpp": {
      "description": "Build C++ parser library",
      "dependencies": []
    }
  },
  "dependencies": [
    {
      "name": "vcpkg-tool-meson",
      "host": true
    }
  ]
}
EOF

cat >"$OVERLAY_INIH_DIR/portfile.cmake" <<'EOF'
vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO benhoyt/inih
    REF r58
    SHA512 d69f488299c1896e87ddd3dd20cd9db5848da7afa4c6159b8a99ba9a5d33f35cadfdb9f65d6f2fe31decdbadb8b43bf610ff2699df475e1f9ff045e343ac26ae
    HEAD_REF master
)

vcpkg_check_features(
  OUT_FEATURE_OPTIONS FEATURE_OPTIONS
  FEATURES
    cpp with_INIReader
)

if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "debug")
  set(INIH_CONFIG_DEBUG ON)
else()
  set(INIH_CONFIG_DEBUG OFF)
endif()

# Install unofficial CMake package
configure_file("${CMAKE_CURRENT_LIST_DIR}/unofficial-inihConfig.cmake.in" "${CURRENT_PACKAGES_DIR}/share/unofficial-inih/unofficial-inihConfig.cmake" @ONLY)

# meson build
string(REPLACE "OFF" "false" FEATURE_OPTIONS "${FEATURE_OPTIONS}")
string(REPLACE "ON" "true" FEATURE_OPTIONS "${FEATURE_OPTIONS}")

vcpkg_configure_meson(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        "${FEATURE_OPTIONS}"
        "-Dcpp_std=c++11"
    "-Dcpp_debugstl=false"
    "-Dcpp_args=-U_LIBCPP_ENABLE_ASSERTIONS"
)

vcpkg_install_meson()
vcpkg_fixup_pkgconfig()

vcpkg_copy_pdbs()

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE.txt")

configure_file("${CMAKE_CURRENT_LIST_DIR}/usage" "${CURRENT_PACKAGES_DIR}/share/${PORT}/usage" COPYONLY)
EOF

echo "Using vcpkg overlay triplets: $OVERLAY_TRIPLETS_DIR"
echo "Using vcpkg overlay ports: $OVERLAY_PORTS_DIR"
echo "Using inih overlay port dir: $OVERLAY_INIH_DIR"
echo "Using vcpkg target/host triplet: arm64-osx-release"

pushd "$SOURCE_ROOT" >/dev/null
cmake --preset macos-release -D CMAKE_OSX_ARCHITECTURES=arm64 -D VCPKG_OVERLAY_TRIPLETS="$OVERLAY_TRIPLETS_DIR" -D VCPKG_OVERLAY_PORTS="$OVERLAY_PORTS_DIR" -D VCPKG_TARGET_TRIPLET=arm64-osx-release -D VCPKG_HOST_TRIPLET=arm64-osx-release

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
