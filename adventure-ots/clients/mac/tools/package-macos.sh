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

rm -rf "$STAGE_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR" "$APP_ROOT/Contents/Frameworks"

cp "$BINARY_PATH" "$MACOS_DIR/OtClient"
chmod +x "$MACOS_DIR/OtClient"

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
