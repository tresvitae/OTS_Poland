#!/bin/sh
set -eu

KEY_FILE="/srv/key.pem"
KEY_TMP="/tmp/tfs-key.pem"

is_valid_key() {
  [ -f "$1" ] || return 1
  grep -q "^-----BEGIN RSA PRIVATE KEY-----$" "$1" && \
    grep -q "^-----END RSA PRIVATE KEY-----$" "$1"
}

if ! is_valid_key "$KEY_FILE"; then
  echo ">> RSA key missing or invalid, generating a fresh key.pem"
  openssl genrsa -out "$KEY_TMP" 2048 >/dev/null 2>&1
  chmod 600 "$KEY_TMP"
  mv "$KEY_TMP" "$KEY_FILE"
fi

exec /bin/tfs
