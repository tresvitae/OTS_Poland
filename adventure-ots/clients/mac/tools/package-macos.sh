#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAC_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLIENTS_ROOT="$(cd "$MAC_ROOT/.." && pwd)"
ADVENTURE_ROOT="$(cd "$CLIENTS_ROOT/.." && pwd)"
SOURCE_ROOT="$CLIENTS_ROOT/windows"

DEFAULT_STAGE_DIR="$MAC_ROOT/dist/macos"
DEFAULT_OUTPUT_ZIP="$ADVENTURE_ROOT/frontend/public/downloads/macos/adventure-ots-client-macos-arm64.zip"

BINARY_PATH=""
OUTPUT_ZIP="$DEFAULT_OUTPUT_ZIP"
STAGE_DIR="$DEFAULT_STAGE_DIR"
CHECKSUM="on"

usage() {
  cat <<'EOF'
Usage: package-macos.sh [options]

Options:
  --binary-path PATH   Path to arm64 otclient binary (optional; auto-discovered if omitted)
  --output-zip PATH    Output zip path (optional; default frontend/public/downloads/macos/adventure-ots-client-macos-arm64.zip)
  --stage-dir PATH     Staging directory (optional; default clients/mac/dist/macos)
  --checksum on|off    Create SHA-256 checksum file next to zip (default: on)
  --help               Show this help
EOF
}

fail() {
  echo "Error: $*" >&2
  exit 1
}

resolve_path() {
  local input_path="$1"
  local dir_name
  local base_name

  dir_name="$(dirname "$input_path")"
  base_name="$(basename "$input_path")"
  if [[ -d "$dir_name" ]]; then
    echo "$(cd "$dir_name" && pwd)/$base_name"
    return 0
  fi

  echo "$input_path"
}

find_default_binary() {
  local candidate
  local search_root="$SOURCE_ROOT/build/macos-release"
  local default_candidates=(
    "$SOURCE_ROOT/otclient"
    "$search_root/otclient"
    "$search_root/src/otclient"
  )

  for candidate in "${default_candidates[@]}"; do
    if [[ -f "$candidate" ]]; then
      echo "$candidate"
      return 0
    fi
  done

  if [[ -d "$search_root" ]]; then
    candidate="$(find "$search_root" -type f -name otclient | head -n 1 || true)"
    if [[ -n "$candidate" ]]; then
      echo "$candidate"
      return 0
    fi
  fi

  return 1
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

if ! command -v file >/dev/null 2>&1; then
  fail "'file' command is required"
fi
if ! command -v lipo >/dev/null 2>&1; then
  fail "'lipo' command is required"
fi
if ! command -v ditto >/dev/null 2>&1; then
  fail "'ditto' command is required"
fi

if [[ -n "$BINARY_PATH" ]]; then
  BINARY_PATH="$(resolve_path "$BINARY_PATH")"
else
  BINARY_PATH="$(find_default_binary || true)"
fi

if [[ -z "$BINARY_PATH" ]]; then
  fail "Unable to locate otclient binary. Provide --binary-path explicitly."
fi
if [[ ! -f "$BINARY_PATH" ]]; then
  fail "Binary not found at '$BINARY_PATH'"
fi

file_description="$(file "$BINARY_PATH")"
if [[ "$file_description" != *"Mach-O"* ]]; then
  fail "Binary at '$BINARY_PATH' is not a Mach-O executable"
fi

archs="$(lipo -archs "$BINARY_PATH" 2>/dev/null || true)"
if [[ -z "$archs" ]]; then
  fail "Unable to determine binary architecture for '$BINARY_PATH'"
fi
if [[ "$archs" != "arm64" ]]; then
  fail "Binary must be arm64-only. Detected architectures: $archs"
fi

required_directories=("data" "modules")
required_files=("init.lua")

for dir_name in "${required_directories[@]}"; do
  if [[ ! -d "$SOURCE_ROOT/$dir_name" ]]; then
    fail "Required directory missing: $SOURCE_ROOT/$dir_name"
  fi
done

for file_name in "${required_files[@]}"; do
  if [[ ! -f "$SOURCE_ROOT/$file_name" ]]; then
    fail "Required file missing: $SOURCE_ROOT/$file_name"
  fi
done

APP_ROOT="$STAGE_DIR/OtClient.app"
MACOS_DIR="$APP_ROOT/Contents/MacOS"
RESOURCES_DIR="$APP_ROOT/Contents/Resources"

if [[ -z "$STAGE_DIR" || "$STAGE_DIR" == "/" ]]; then
  fail "Refusing to use unsafe stage directory: '$STAGE_DIR'"
fi

rm -rf "$STAGE_DIR"
HELPERS_DIR="$APP_ROOT/Contents/Helpers"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR" "$APP_ROOT/Contents/Frameworks" "$HELPERS_DIR"

# Place the real binary in Contents/Helpers — NOT Contents/MacOS.
# codesign --deep strips or invalidates extra Mach-O files in Contents/MacOS
# that are not the CFBundleExecutable.
cp "$BINARY_PATH" "$HELPERS_DIR/OtClient-bin"
chmod +x "$HELPERS_DIR/OtClient-bin"

# ---------------------------------------------------------------------------
# Build a compiled C launcher stub (OtClient) that bootstraps XQuartz before
# exec'ing the real binary (OtClient-bin).
#
# macOS Gatekeeper requires CFBundleExecutable to be a valid Mach-O binary.
# A shell script wrapper causes "damaged or incomplete" or "executable is
# missing" errors after code signing on macOS Sequoia.
# ---------------------------------------------------------------------------
LAUNCHER_SRC="$STAGE_DIR/OtClient-launcher.c"
cat > "$LAUNCHER_SRC" <<'LAUNCHER_C'
#include <errno.h>
#include <libgen.h>
#include <mach-o/dyld.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

static int xquartz_running(void) {
    return system("pgrep -qx Xquartz >/dev/null 2>&1 || "
                  "pgrep -qx X11.bin >/dev/null 2>&1") == 0;
}

static int wait_for_socket(const char *path, int max_attempts) {
    struct stat st;
    for (int i = 0; i < max_attempts; i++) {
        if (stat(path, &st) == 0) return 1;
        usleep(500000);
    }
    return 0;
}

int main(int argc, char *argv[]) {
    /* Resolve this executable's directory. */
    char exe_path[4096];
    uint32_t size = sizeof(exe_path);
    if (_NSGetExecutablePath(exe_path, &size) != 0) {
        fprintf(stderr, "OtClient: could not resolve executable path\n");
        return 1;
    }
    char resolved[4096];
    if (!realpath(exe_path, resolved)) {
        fprintf(stderr, "OtClient: realpath failed: %s\n", strerror(errno));
        return 1;
    }
    char *dir = dirname(resolved);

    /* cd to the executable directory so relative paths work. */
    if (chdir(dir) != 0) {
        fprintf(stderr, "OtClient: chdir(%s) failed: %s\n", dir, strerror(errno));
    }

    /* --- XQuartz bootstrap ------------------------------------------------ */
    if (!xquartz_running()) {
        if (system("open -a XQuartz >/dev/null 2>&1") != 0) {
            /* Try mdfind fallback. */
            system("mdfind 'kMDItemCFBundleIdentifier == \"org.xquartz.X11\"' "
                   "| head -n 1 | xargs open >/dev/null 2>&1");
        }
        if (!wait_for_socket("/tmp/.X11-unix/X0", 20)) {
            fprintf(stderr,
                    "OtClient: XQuartz display server did not start in time.\n"
                    "Launch XQuartz manually, then re-open OtClient.\n");
            system("osascript -e 'display alert \"XQuartz Required\" "
                   "message \"XQuartz did not start in time.\\n\\n"
                   "Launch XQuartz manually, wait a few seconds, "
                   "then re-open OtClient.\" as critical' 2>/dev/null");
            return 1;
        }
    }

    /* Set DISPLAY if not already present. */
    if (!getenv("DISPLAY")) {
        setenv("DISPLAY", ":0", 0);
    }
    /* Set XAUTHORITY if missing (XQuartz default). */
    if (!getenv("XAUTHORITY")) {
        const char *home = getenv("HOME");
        if (home) {
            char xauth[4096];
            snprintf(xauth, sizeof(xauth), "%s/.Xauthority", home);
            setenv("XAUTHORITY", xauth, 0);
        }
    }
    /* Force indirect GLX rendering.  Apple deprecated hardware OpenGL/DRI,
       so the XQuartz Apple-DRI extension returns BadValue.  Indirect
       rendering uses the software rasteriser instead. */
    if (!getenv("LIBGL_ALWAYS_INDIRECT")) {
        setenv("LIBGL_ALWAYS_INDIRECT", "1", 0);
    }

    /* Build path to the real binary in Contents/Helpers and exec it. */
    char real_bin[4096];
    snprintf(real_bin, sizeof(real_bin), "%s/../Helpers/OtClient-bin", dir);
    argv[0] = real_bin;
    execv(real_bin, argv);

    fprintf(stderr, "OtClient: execv(%s) failed: %s\n", real_bin, strerror(errno));
    return 1;
}
LAUNCHER_C

echo "Compiling native launcher stub..."
clang -arch arm64 \
  -mmacosx-version-min=14.0 \
  -O2 \
  -o "$MACOS_DIR/OtClient" \
  "$LAUNCHER_SRC"
chmod +x "$MACOS_DIR/OtClient"
rm -f "$LAUNCHER_SRC"

for dir_name in "${required_directories[@]}"; do
  cp -R "$SOURCE_ROOT/$dir_name" "$RESOURCES_DIR/$dir_name"
done

for file_name in "${required_files[@]}"; do
  cp "$SOURCE_ROOT/$file_name" "$RESOURCES_DIR/$file_name"
done

optional_directories=("mods" "records")
optional_files=("meta.lua" "config.ini" "otclientrc.lua" "cacert.pem")

for dir_name in "${optional_directories[@]}"; do
  if [[ -d "$SOURCE_ROOT/$dir_name" ]]; then
    cp -R "$SOURCE_ROOT/$dir_name" "$RESOURCES_DIR/$dir_name"
  fi
done

for file_name in "${optional_files[@]}"; do
  if [[ -f "$SOURCE_ROOT/$file_name" ]]; then
    cp "$SOURCE_ROOT/$file_name" "$RESOURCES_DIR/$file_name"
  fi
done

ln -sfn ../Resources/data "$MACOS_DIR/data"
ln -sfn ../Resources/modules "$MACOS_DIR/modules"
ln -sfn ../Resources/init.lua "$MACOS_DIR/init.lua"

link_resource_into_macos() {
  local resource_name="$1"
  if [[ -e "$RESOURCES_DIR/$resource_name" ]]; then
    ln -sfn "../Resources/$resource_name" "$MACOS_DIR/$resource_name"
  fi
}

# Expose additional runtime files from Contents/MacOS because startup resolves
# some paths from the mounted work dir (for example /config.ini).
link_resource_into_macos "config.ini"
link_resource_into_macos "otclientrc.lua"
link_resource_into_macos "meta.lua"
link_resource_into_macos "mods"
link_resource_into_macos "records"
link_resource_into_macos "cacert.pem"

cat > "$APP_ROOT/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>OtClient</string>
  <key>CFBundleDisplayName</key>
  <string>OtClient</string>
  <key>CFBundleIdentifier</key>
  <string>com.adventureots.otclient</string>
  <key>CFBundleVersion</key>
  <string>1.0.0</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0.0</string>
  <key>CFBundleExecutable</key>
  <string>OtClient</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

OUTPUT_ZIP="$(resolve_path "$OUTPUT_ZIP")"
mkdir -p "$(dirname "$OUTPUT_ZIP")"
rm -f "$OUTPUT_ZIP"

# Strip extended attributes (especially quarantine flags) from the bundle before signing.
xattr -cr "$APP_ROOT"

# Ad-hoc code sign the app bundle so Gatekeeper does not reject it with:
# "You can't open the application 'OtClient' because it may be damaged or incomplete."
# The entitlements grant JIT permission required by the LuaJIT runtime.
ENTITLEMENTS_FILE="$STAGE_DIR/OtClient.entitlements"
cat > "$ENTITLEMENTS_FILE" <<'ENTITLEMENTS'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>com.apple.security.cs.allow-jit</key>
  <true/>
  <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
  <true/>
  <key>com.apple.security.cs.disable-library-validation</key>
  <true/>
</dict>
</plist>
ENTITLEMENTS

# Sign each binary individually (inside-out), then seal the bundle.
# Do NOT use --deep: it strips or invalidates extra Mach-O files that are
# not the CFBundleExecutable.
codesign --force --sign - \
  --entitlements "$ENTITLEMENTS_FILE" \
  "$APP_ROOT/Contents/Helpers/OtClient-bin"

codesign --force --sign - \
  --entitlements "$ENTITLEMENTS_FILE" \
  "$APP_ROOT/Contents/MacOS/OtClient"

# Seal the whole bundle (lightweight, no --deep).
codesign --force --sign - "$APP_ROOT"

echo "Ad-hoc code signature applied."
codesign --verify --strict --verbose=2 "$APP_ROOT" 2>&1 || echo "Warning: codesign verify reported issues (non-fatal for ad-hoc)."

rm -f "$ENTITLEMENTS_FILE"

ditto -c -k --sequesterRsrc --keepParent "$APP_ROOT" "$OUTPUT_ZIP"

if [[ "$CHECKSUM" == "on" ]]; then
  checksum_path="$OUTPUT_ZIP.sha256"
  if command -v shasum >/dev/null 2>&1; then
    (
      cd "$(dirname "$OUTPUT_ZIP")"
      shasum -a 256 "$(basename "$OUTPUT_ZIP")" > "$(basename "$checksum_path")"
    )
  elif command -v sha256sum >/dev/null 2>&1; then
    (
      cd "$(dirname "$OUTPUT_ZIP")"
      sha256sum "$(basename "$OUTPUT_ZIP")" > "$(basename "$checksum_path")"
    )
  else
    fail "Neither 'shasum' nor 'sha256sum' is available for checksum generation"
  fi
fi

echo "Packaged macOS client -> $OUTPUT_ZIP"
if [[ "$CHECKSUM" == "on" ]]; then
  echo "Checksum file -> $OUTPUT_ZIP.sha256"
fi
