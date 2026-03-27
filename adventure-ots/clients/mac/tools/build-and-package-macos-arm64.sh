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

sanitize_macro_token() {
  local value="$1"
  value="${value//[^[:alnum:]_]/_}"
  if [[ -z "$value" ]]; then
    value="unknown"
  fi
  printf '%s\n' "$value"
}

generate_gitinfo_header() {
  local gitinfo_path="$SOURCE_ROOT/src/gitinfo.h"
  local branch="unknown"
  local version="0.0.0"
  local commits="0"

  if command -v git >/dev/null 2>&1; then
    branch="$(git -C "$SOURCE_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
    version="$(git -C "$SOURCE_ROOT" describe --abbrev=0 --tag 2>/dev/null || echo 0.0.0)"
    commits="$(git -C "$SOURCE_ROOT" rev-list --count HEAD 2>/dev/null || echo 0)"
  fi

  branch="$(sanitize_macro_token "$branch")"
  version="$(sanitize_macro_token "$version")"

  if [[ ! "$commits" =~ ^[0-9]+$ ]]; then
    commits="0"
  fi

  cat >"$gitinfo_path" <<EOF
#define GIT_BRANCH $branch
#define GIT_VERSION $version
#define GIT_COMMITS $commits
EOF

  echo "Generated git info header: $gitinfo_path"
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

append_unique() {
  local var_name="$1"
  local value="$2"
  [[ -n "$value" ]] || return 0

  eval "local current=\"\${${var_name}:-}\""
  local part
  IFS=';' read -r -a parts <<< "$current"
  for part in "${parts[@]}"; do
    [[ "$part" == "$value" ]] && return 0
  done

  if [[ -n "$current" ]]; then
    eval "${var_name}=\"${current};${value}\""
  else
    eval "${var_name}=\"${value}\""
  fi
}

append_unique_space_flag() {
  local var_name="$1"
  local value="$2"
  [[ -n "$value" ]] || return 0

  eval "local current=\"\${${var_name}:-}\""
  case " $current " in
    *" $value "*)
      return 0
      ;;
  esac

  if [[ -n "$current" ]]; then
    eval "${var_name}=\"${current} ${value}\""
  else
    eval "${var_name}=\"${value}\""
  fi
}

append_unique_colon_path() {
  local var_name="$1"
  local value="$2"
  [[ -n "$value" ]] || return 0

  eval "local current=\"\${${var_name}:-}\""
  local part
  IFS=':' read -r -a parts <<< "$current"
  for part in "${parts[@]}"; do
    [[ "$part" == "$value" ]] && return 0
  done

  if [[ -n "$current" ]]; then
    eval "${var_name}=\"${current}:${value}\""
  else
    eval "${var_name}=\"${value}\""
  fi
}

find_file_in_roots() {
  local relpath="$1"
  shift

  local root
  for root in "$@"; do
    [[ -n "$root" ]] || continue
    [[ -d "$root" ]] || continue
    if [[ -f "$root/$relpath" ]]; then
      printf '%s\n' "$root/$relpath"
      return 0
    fi
  done

  return 1
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

BREW_PREFIX=""
if command -v brew >/dev/null 2>&1; then
  BREW_PREFIX="$(brew --prefix 2>/dev/null || true)"
fi

# macOS OTClient: Pin X11/GLX to XQuartz (/opt/X11) exclusively to avoid library path mixing.
# Homebrew X11 and XQuartz have incompatible GLX implementations that cause glXChooseFBConfig failures.
# See: X11Window::init() -> internalChooseGLVisual() -> glXChooseFBConfig crash
X11_INCLUDE_ROOTS=(
  "/opt/X11/include"
)

X11_LIBRARY_ROOTS=(
  "/opt/X11/lib"
)

X11_HEADER_PATH="$(find_file_in_roots "X11/Xlib.h" "${X11_INCLUDE_ROOTS[@]}" || true)"
GLX_HEADER_PATH="$(find_file_in_roots "GL/glx.h" "${X11_INCLUDE_ROOTS[@]}" || true)"
X11_LIBRARY_PATH="$(find_file_in_roots "libX11.dylib" "${X11_LIBRARY_ROOTS[@]}" || true)"
GL_LIBRARY_PATH="$(find_file_in_roots "libGL.dylib" "${X11_LIBRARY_ROOTS[@]}" || true)"

if [[ -z "$X11_HEADER_PATH" || -z "$GLX_HEADER_PATH" || -z "$X11_LIBRARY_PATH" || -z "$GL_LIBRARY_PATH" ]]; then
  echo "Missing required X11/GLX dependency for macOS OTClient build." >&2
  [[ -n "$X11_HEADER_PATH" ]] || echo " - Missing header: X11/Xlib.h" >&2
  [[ -n "$GLX_HEADER_PATH" ]] || echo " - Missing header: GL/glx.h" >&2
  [[ -n "$X11_LIBRARY_PATH" ]] || echo " - Missing library: libX11.dylib" >&2
  [[ -n "$GL_LIBRARY_PATH" ]] || echo " - Missing library: libGL.dylib" >&2
  cat >&2 <<'EOF'

Install XQuartz (recommended on macOS for X11/GLX):
  brew install --cask xquartz

After installation:
  1) Start XQuartz once, then restart your terminal session.
  2) Confirm files exist under /opt/X11 (for example /opt/X11/include/GL/glx.h and /opt/X11/lib/libGL.dylib).
  3) Re-run this script.
EOF
  fail "Cannot continue without GLX/X11 development files."
fi

X11_INCLUDE_DIR="${X11_HEADER_PATH%/X11/Xlib.h}"
GLX_INCLUDE_DIR="${GLX_HEADER_PATH%/GL/glx.h}"
X11_LIBRARY_DIR="$(dirname "$X11_LIBRARY_PATH")"
GL_LIBRARY_DIR="$(dirname "$GL_LIBRARY_PATH")"

append_unique_space_flag CPPFLAGS "-I$X11_INCLUDE_DIR"
append_unique_space_flag CPPFLAGS "-I$GLX_INCLUDE_DIR"
append_unique_space_flag CFLAGS "-I$X11_INCLUDE_DIR"
append_unique_space_flag CFLAGS "-I$GLX_INCLUDE_DIR"
append_unique_space_flag CXXFLAGS "-I$X11_INCLUDE_DIR"
append_unique_space_flag CXXFLAGS "-I$GLX_INCLUDE_DIR"
append_unique_space_flag LDFLAGS "-L$X11_LIBRARY_DIR"
append_unique_space_flag LDFLAGS "-L$GL_LIBRARY_DIR"

if [[ -d "$X11_LIBRARY_DIR/pkgconfig" ]]; then
  append_unique_colon_path PKG_CONFIG_PATH "$X11_LIBRARY_DIR/pkgconfig"
fi
if [[ -d "$GL_LIBRARY_DIR/pkgconfig" ]]; then
  append_unique_colon_path PKG_CONFIG_PATH "$GL_LIBRARY_DIR/pkgconfig"
fi

export CPPFLAGS CFLAGS CXXFLAGS LDFLAGS PKG_CONFIG_PATH

CMAKE_PREFIX_HINTS="${CMAKE_PREFIX_PATH:-}"
CMAKE_INCLUDE_HINTS="${CMAKE_INCLUDE_PATH:-}"
CMAKE_LIBRARY_HINTS="${CMAKE_LIBRARY_PATH:-}"

append_unique CMAKE_PREFIX_HINTS "${X11_INCLUDE_DIR%/include}"
append_unique CMAKE_PREFIX_HINTS "${GLX_INCLUDE_DIR%/include}"
append_unique CMAKE_PREFIX_HINTS "${X11_LIBRARY_DIR%/lib}"
append_unique CMAKE_PREFIX_HINTS "${GL_LIBRARY_DIR%/lib}"

append_unique CMAKE_INCLUDE_HINTS "$X11_INCLUDE_DIR"
append_unique CMAKE_INCLUDE_HINTS "$GLX_INCLUDE_DIR"

append_unique CMAKE_LIBRARY_HINTS "$X11_LIBRARY_DIR"
append_unique CMAKE_LIBRARY_HINTS "$GL_LIBRARY_DIR"

echo "Using X11 include dir: $X11_INCLUDE_DIR"
echo "Using GLX include dir: $GLX_INCLUDE_DIR"
echo "Using X11 library: $X11_LIBRARY_PATH"
echo "Using OpenGL library: $GL_LIBRARY_PATH"

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
if [[ ! -d "$SOURCE_ROOT/src" ]]; then
  fail "OTClient source directory not found at '$SOURCE_ROOT/src'"
fi

generate_gitinfo_header

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
cmake --preset macos-release \
  -D CMAKE_OSX_ARCHITECTURES=arm64 \
  -D OTCLIENT_BUILD_TESTS=OFF \
  -D VCPKG_OVERLAY_TRIPLETS="$OVERLAY_TRIPLETS_DIR" \
  -D VCPKG_OVERLAY_PORTS="$OVERLAY_PORTS_DIR" \
  -D VCPKG_TARGET_TRIPLET=arm64-osx-release \
  -D VCPKG_HOST_TRIPLET=arm64-osx-release \
  -D OPENGL_USE_APPLE_X11=ON \
  -D OPENGL_INCLUDE_DIR="$GLX_INCLUDE_DIR" \
  -D OPENGL_gl_LIBRARY="$GL_LIBRARY_PATH" \
  -D X11_X11_INCLUDE_PATH="$X11_INCLUDE_DIR" \
  -D X11_X11_LIB="$X11_LIBRARY_PATH" \
  -D CMAKE_PREFIX_PATH="$CMAKE_PREFIX_HINTS" \
  -D CMAKE_INCLUDE_PATH="$CMAKE_INCLUDE_HINTS" \
  -D CMAKE_LIBRARY_PATH="$CMAKE_LIBRARY_HINTS" \
  -D CMAKE_C_FLAGS="$CFLAGS" \
  -D CMAKE_CXX_FLAGS="$CXXFLAGS" \
  -D CMAKE_EXE_LINKER_FLAGS="$LDFLAGS"

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
