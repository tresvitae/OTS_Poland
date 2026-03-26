#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MAC_BUILD_SCRIPT="$REPO_ROOT/adventure-ots/clients/mac/tools/build-and-package-macos-arm64.sh"
ZIP_PATH="$REPO_ROOT/adventure-ots/frontend/public/downloads/macos/adventure-ots-client-macos-arm64.zip"
CHECKSUM_PATH="${ZIP_PATH}.sha256"

fail() {
  echo "Error: $*" >&2
  exit 1
}

if [[ ! -f "$MAC_BUILD_SCRIPT" ]]; then
  fail "Required script not found at '$MAC_BUILD_SCRIPT'. Ensure the repository checkout is complete."
fi

if [[ ! -x "$MAC_BUILD_SCRIPT" ]]; then
  fail "Required script is not executable: '$MAC_BUILD_SCRIPT'. Run: chmod +x '$MAC_BUILD_SCRIPT'"
fi

pushd "$REPO_ROOT" >/dev/null
"$MAC_BUILD_SCRIPT"
popd >/dev/null

if [[ ! -f "$ZIP_PATH" ]]; then
  fail "Build finished but ZIP artifact was not found at '$ZIP_PATH'."
fi

if [[ ! -f "$CHECKSUM_PATH" ]]; then
  fail "Build finished but checksum artifact was not found at '$CHECKSUM_PATH'."
fi

echo "macOS arm64 OTClient package created successfully."
echo "ZIP: $ZIP_PATH"
echo "SHA256: $CHECKSUM_PATH"
