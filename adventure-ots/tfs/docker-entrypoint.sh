#!/bin/sh
set -eu

KEY_FILE="${TFS_KEY_FILE:-/srv/keys/key.pem}"
KEY_TMP="/tmp/tfs-key.pem"
TFS_EXPECTED_KEY_BITS="${TFS_EXPECTED_KEY_BITS:-1024}"
LINK_PATH="/srv/key.pem"
PUB_PATH="/srv/key.pem.pub"

is_valid_key() {
  [ -f "$1" ] || return 1
  openssl rsa -in "$1" -check -noout >/dev/null 2>&1
}

get_key_bits() {
  openssl rsa -in "$1" -text -noout 2>/dev/null \
    | sed -n 's/Private-Key: (\([0-9][0-9]*\) bit.*/\1/p' \
    | head -n 1
}

ensure_key_dir() {
  mkdir -p "$(dirname "$KEY_FILE")"
}

generate_key() {
  echo ">> Generating RSA key at $KEY_FILE (${TFS_EXPECTED_KEY_BITS}-bit)"
  openssl genrsa -traditional -out "$KEY_TMP" "$TFS_EXPECTED_KEY_BITS" >/dev/null 2>&1
  chmod 600 "$KEY_TMP"
  mv "$KEY_TMP" "$KEY_FILE"
}

ensure_key_dir

if ! is_valid_key "$KEY_FILE"; then
  echo ">> RSA key missing or invalid, generating a fresh key.pem"
  generate_key
fi

KEY_BITS="$(get_key_bits "$KEY_FILE")"
if [ "$KEY_BITS" != "$TFS_EXPECTED_KEY_BITS" ]; then
  echo ">> RSA key size mismatch (have ${KEY_BITS:-unknown}, expected $TFS_EXPECTED_KEY_BITS). Regenerating key.pem"
  generate_key
fi

# TFS loads key.pem from /srv, so keep a stable link to the persisted key path.
ln -sf "$KEY_FILE" "$LINK_PATH"

# Export public key for diagnostics and client sync workflows.
openssl rsa -in "$KEY_FILE" -pubout -out "$PUB_PATH" >/dev/null 2>&1 || true

exec /bin/tfs
