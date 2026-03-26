# OTClient on macOS Apple Silicon (arm64)

Yes. It is possible to build and package a native macOS OTClient for Apple Silicon in this repository.

## Scope and assumptions

- Target platform: macOS 14+ on Apple Silicon only (arm64).
- Build type: native arm64 build on Apple Silicon host.
- This plan intentionally excludes Intel and universal binaries.
- Source/build root for OTClient CMake is currently `adventure-ots/clients/windows` (the macOS presets are defined there).

## Why Docker is not enough for native mac app output

- Docker here is great for running stack services (db, backend, frontend, nginx, TFS), but it does not replace macOS app toolchain requirements.
- A production-ready mac app package needs macOS-native steps: `.app` bundle layout, `codesign`, and usually notarization.
- Apple signing/notarization tooling depends on local Apple credentials and host keychain access, which is outside normal Linux container build flow.

## Isolation model (venv-like for C++)

Use a project-local workspace for build artifacts, dependency installs, and cache. Keep this local state outside tracked source files.

Suggested local directories (under repo root):

- `adventure-ots/clients/mac/.local/build`
- `adventure-ots/clients/mac/.local/vcpkg_installed`
- `adventure-ots/clients/mac/.local/vcpkg_cache`
- `adventure-ots/clients/mac/.local/toolchains`
- `adventure-ots/clients/mac/.local/dist`

Activation script example (`adventure-ots/clients/mac/.local/activate-arm64.sh`):

```bash
#!/usr/bin/env bash

# Save previous values for clean deactivation.
export _OLD_VCPKG_ROOT="${VCPKG_ROOT-}"
export _OLD_VCPKG_INSTALLED_DIR="${VCPKG_INSTALLED_DIR-}"
export _OLD_VCPKG_DEFAULT_BINARY_CACHE="${VCPKG_DEFAULT_BINARY_CACHE-}"
export _OLD_CMAKE_TOOLCHAIN_FILE="${CMAKE_TOOLCHAIN_FILE-}"
export _OLD_CMAKE_OSX_ARCHITECTURES="${CMAKE_OSX_ARCHITECTURES-}"
export _OLD_VCPKG_DEFAULT_TRIPLET="${VCPKG_DEFAULT_TRIPLET-}"

export REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
export OTS_CLIENT_SRC="$REPO_ROOT/adventure-ots/clients/windows"
export OTS_MAC_LOCAL="$REPO_ROOT/adventure-ots/clients/mac/.local"

mkdir -p "$OTS_MAC_LOCAL/build" \
				 "$OTS_MAC_LOCAL/vcpkg_installed" \
				 "$OTS_MAC_LOCAL/vcpkg_cache" \
				 "$OTS_MAC_LOCAL/toolchains" \
				 "$OTS_MAC_LOCAL/dist"

# Required variables for reproducible local builds.
export VCPKG_ROOT="$HOME/.local/share/vcpkg"
export VCPKG_INSTALLED_DIR="$OTS_MAC_LOCAL/vcpkg_installed"
export VCPKG_DEFAULT_BINARY_CACHE="$OTS_MAC_LOCAL/vcpkg_cache"
export CMAKE_TOOLCHAIN_FILE="$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake"
export CMAKE_OSX_ARCHITECTURES="arm64"
export VCPKG_DEFAULT_TRIPLET="arm64-osx"

deactivate_otclient_arm64() {
	export VCPKG_ROOT="$_OLD_VCPKG_ROOT"
	export VCPKG_INSTALLED_DIR="$_OLD_VCPKG_INSTALLED_DIR"
	export VCPKG_DEFAULT_BINARY_CACHE="$_OLD_VCPKG_DEFAULT_BINARY_CACHE"
	export CMAKE_TOOLCHAIN_FILE="$_OLD_CMAKE_TOOLCHAIN_FILE"
	export CMAKE_OSX_ARCHITECTURES="$_OLD_CMAKE_OSX_ARCHITECTURES"
	export VCPKG_DEFAULT_TRIPLET="$_OLD_VCPKG_DEFAULT_TRIPLET"

	unset _OLD_VCPKG_ROOT
	unset _OLD_VCPKG_INSTALLED_DIR
	unset _OLD_VCPKG_DEFAULT_BINARY_CACHE
	unset _OLD_CMAKE_TOOLCHAIN_FILE
	unset _OLD_CMAKE_OSX_ARCHITECTURES
	unset _OLD_VCPKG_DEFAULT_TRIPLET
	unset REPO_ROOT OTS_CLIENT_SRC OTS_MAC_LOCAL
	unset -f deactivate_otclient_arm64
}

echo "OTClient arm64 environment activated. Run: deactivate_otclient_arm64"
```

Use it in each shell:

```bash
source adventure-ots/clients/mac/.local/activate-arm64.sh
```

Deactivate when done:

```bash
deactivate_otclient_arm64
```

## Step-by-step setup (Apple Silicon native)

### 1) Install prerequisites

```bash
# Xcode Command Line Tools (required for clang, SDK, codesign tooling)
xcode-select --install

# Homebrew packages
brew update
brew install cmake ninja git pkg-config sccache

# Verify architecture and toolchain
uname -m
clang --version
cmake --version
ninja --version
```

Expected:

- `uname -m` returns `arm64`.
- `cmake` is 3.22+ (preset file requires at least that).

### 2) Bootstrap vcpkg

Option A (recommended): user-level vcpkg in home directory.

```bash
mkdir -p "$HOME/.local/share"
cd "$HOME/.local/share"
git clone https://github.com/microsoft/vcpkg.git
cd vcpkg
./bootstrap-vcpkg.sh
```

Option B: toolchain folder under your project-local workspace.

```bash
mkdir -p adventure-ots/clients/mac/.local/toolchains
cd adventure-ots/clients/mac/.local/toolchains
git clone https://github.com/microsoft/vcpkg.git
cd vcpkg
./bootstrap-vcpkg.sh
```

If you use Option B, set:

```bash
export VCPKG_ROOT="$(pwd)"
```

### 3) Activate environment

```bash
cd /path/to/OTS_Poland
source adventure-ots/clients/mac/.local/activate-arm64.sh
```

### 4) Configure using existing mac presets from adventure-ots/clients/windows/CMakePresets.json

```bash
cd "$OTS_CLIENT_SRC"

# Optional: inspect available presets
cmake --list-presets

# Configure release build for Apple Silicon
cmake --preset macos-release \
	-D CMAKE_OSX_ARCHITECTURES=arm64 \
	-D VCPKG_TARGET_TRIPLET=arm64-osx
```

Notes:

- The preset already defines `CMAKE_TOOLCHAIN_FILE` from `VCPKG_ROOT`.
- `CMAKE_OSX_ARCHITECTURES=arm64` is explicitly pinned here for clarity.

### 5) Build

```bash
cd "$OTS_CLIENT_SRC"
cmake --build --preset macos-release --parallel "$(sysctl -n hw.logicalcpu)"
```

The current CMake setup writes runtime output to the source directory by default, so verify binary output at:

- `adventure-ots/clients/windows/otclient`

Quick checks:

```bash
file adventure-ots/clients/windows/otclient
otool -L adventure-ots/clients/windows/otclient | head -n 20
```

Expected architecture: `arm64`.

## Packaging plan for mac artifact

The current client CMake config does not define automatic `MACOSX_BUNDLE` packaging. Use a deterministic manual bundle stage.

### 1) Create `OtClient.app` structure

```bash
cd /path/to/OTS_Poland

APP_ROOT="adventure-ots/clients/mac/.local/dist/OtClient.app"
SRC_ROOT="adventure-ots/clients/windows"

rm -rf "$APP_ROOT"
mkdir -p "$APP_ROOT/Contents/MacOS"
mkdir -p "$APP_ROOT/Contents/Resources"
mkdir -p "$APP_ROOT/Contents/Frameworks"

# Main executable
cp "$SRC_ROOT/otclient" "$APP_ROOT/Contents/MacOS/OtClient"
chmod +x "$APP_ROOT/Contents/MacOS/OtClient"

# Runtime resources expected by OTClient
cp -R "$SRC_ROOT/data" "$APP_ROOT/Contents/Resources/data"
cp -R "$SRC_ROOT/modules" "$APP_ROOT/Contents/Resources/modules"
cp -R "$SRC_ROOT/mods" "$APP_ROOT/Contents/Resources/mods"
cp -R "$SRC_ROOT/records" "$APP_ROOT/Contents/Resources/records"
cp "$SRC_ROOT/init.lua" "$APP_ROOT/Contents/Resources/init.lua"
cp "$SRC_ROOT/meta.lua" "$APP_ROOT/Contents/Resources/meta.lua"
cp "$SRC_ROOT/config.ini" "$APP_ROOT/Contents/Resources/config.ini"
cp "$SRC_ROOT/otclientrc.lua" "$APP_ROOT/Contents/Resources/otclientrc.lua"

# Optional if present
if [ -f "$SRC_ROOT/cacert.pem" ]; then
	cp "$SRC_ROOT/cacert.pem" "$APP_ROOT/Contents/Resources/cacert.pem"
fi

cat > "$APP_ROOT/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleName</key><string>OtClient</string>
	<key>CFBundleDisplayName</key><string>OtClient</string>
	<key>CFBundleIdentifier</key><string>com.adventureots.otclient</string>
	<key>CFBundleVersion</key><string>1.0.0</string>
	<key>CFBundleShortVersionString</key><string>1.0.0</string>
	<key>CFBundleExecutable</key><string>OtClient</string>
	<key>CFBundlePackageType</key><string>APPL</string>
	<key>LSMinimumSystemVersion</key><string>14.0</string>
	<key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST
```

### 2) Zip naming convention for frontend downloads

Recommended stable filename:

- `adventure-ots-client-macos-arm64.zip`

Recommended path for website-served artifact:

- `adventure-ots/frontend/public/downloads/macos/adventure-ots-client-macos-arm64.zip`

Create zip:

```bash
cd /path/to/OTS_Poland

ZIP_DIR="adventure-ots/frontend/public/downloads/macos"
ZIP_PATH="$ZIP_DIR/adventure-ots-client-macos-arm64.zip"

mkdir -p "$ZIP_DIR"
ditto -c -k --sequesterRsrc --keepParent \
	"adventure-ots/clients/mac/.local/dist/OtClient.app" \
	"$ZIP_PATH"

ls -lh "$ZIP_PATH"
```

## Automated scripts (arm64)

Use the helper scripts to automate the configure/build/package flow and enforce arm64 packaging checks.

Build and package in one command:

```bash
cd /path/to/OTS_Poland
bash adventure-ots/clients/mac/tools/build-and-package-macos-arm64.sh
```

Package only (when binary already exists):

```bash
cd /path/to/OTS_Poland
bash adventure-ots/clients/mac/tools/package-macos.sh \
	--binary-path adventure-ots/clients/windows/otclient
```

Defaults:

- Output zip: `adventure-ots/frontend/public/downloads/macos/adventure-ots-client-macos-arm64.zip`
- Stage dir: `adventure-ots/clients/mac/dist/macos`
- SHA-256 checksum: enabled by default (`.sha256` file next to the zip)

## CI automation and publishing (macOS arm64)

### Build workflow

- Workflow file: `.github/workflows/otclient-macos-build.yml`
- Triggers:
	- `push` and `pull_request`
	- Path filters:
		- `adventure-ots/clients/windows/**`
		- `adventure-ots/clients/mac/**`
		- `.github/workflows/otclient-macos-build.yml`
- Produced artifact (GitHub Actions artifact upload):
	- Artifact name: `macos-otclient-arm64`
	- Files:
		- `adventure-ots-client-macos-arm64.zip`
		- `adventure-ots-client-macos-arm64.zip.sha256`

### Publish workflow

- Workflow file: `.github/workflows/otclient-macos-publish.yml`
- Triggers:
	- Tag push matching `v*`
	- Manual run via `workflow_dispatch`
- Published release assets:
	- `adventure-ots-client-macos-arm64-<version>.zip`
	- `adventure-ots-client-macos-arm64-<version>.zip.sha256`

Version behavior:

- Tag run (`v*`): `<version>` is the git tag name (for example, `v1.2.0`).
- Manual run (`workflow_dispatch`): `<version>` is `manual-${GITHUB_RUN_NUMBER}` and a prerelease with the same tag is created.

Rollback if a bad artifact is released:

1. Open the affected GitHub Release.
2. Delete both bad assets from that release:
	 - `adventure-ots-client-macos-arm64-<version>.zip`
	 - `adventure-ots-client-macos-arm64-<version>.zip.sha256`
3. Re-run `.github/workflows/otclient-macos-publish.yml` with a fixed commit/version.
4. Confirm the new `.zip` and `.sha256` pair is present and checksum matches before announcing availability.

## Signing and notarization (recommended for distribution)

Prerequisites:

- Active Apple Developer account.
- Developer ID Application certificate installed in login keychain.

### 1) Optional entitlements for LuaJIT/hardened runtime cases

LuaJIT can require JIT-related entitlements under hardened runtime. If the signed app crashes with memory-protection style faults, test with:

```bash
cat > adventure-ots/clients/mac/.local/otclient-entitlements.plist <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.cs.allow-jit</key><true/>
	<key>com.apple.security.cs.allow-unsigned-executable-memory</key><true/>
	<key>com.apple.security.cs.disable-library-validation</key><true/>
</dict>
</plist>
PLIST
```

Only grant these if needed, and validate security posture for your release policy.

### 2) Sign app

```bash
APP_PATH="adventure-ots/clients/mac/.local/dist/OtClient.app"
ENTITLEMENTS="adventure-ots/clients/mac/.local/otclient-entitlements.plist"

codesign --force --deep --timestamp --options runtime \
	--entitlements "$ENTITLEMENTS" \
	--sign "Developer ID Application: YOUR_NAME (TEAMID1234)" \
	"$APP_PATH"

codesign --verify --deep --strict --verbose=2 "$APP_PATH"
spctl --assess --type execute --verbose "$APP_PATH"
```

### 3) Notarize and staple

```bash
ZIP_PATH="adventure-ots/frontend/public/downloads/macos/adventure-ots-client-macos-arm64.zip"
APP_PATH="adventure-ots/clients/mac/.local/dist/OtClient.app"

# One-time credential storage
xcrun notarytool store-credentials "adventure-ots-notary" \
	--apple-id "you@example.com" \
	--team-id "TEAMID1234" \
	--password "app-specific-password"

# Submit zip and wait for result
xcrun notarytool submit "$ZIP_PATH" --keychain-profile "adventure-ots-notary" --wait

# Staple notarization ticket to app bundle
xcrun stapler staple "$APP_PATH"

# Re-zip stapled app for distribution
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"
```

## Smoke-test checklist against local stack

Run these checks after build and packaging.

1. Start stack and confirm services:

```bash
cd /path/to/OTS_Poland/adventure-ots
docker compose up -d --build
docker compose ps
```

2. Check web and API through nginx:

```bash
curl -i http://localhost/
curl -i http://localhost/api/health
```

3. Check game endpoint availability:

```bash
nc -vz 127.0.0.1 7171
```

4. Check mac artifact download path (if zip copied to frontend downloads):

```bash
curl -I http://localhost/downloads/macos/adventure-ots-client-macos-arm64.zip
```

5. Launch app locally and validate core flow:

```bash
open adventure-ots/clients/mac/.local/dist/OtClient.app
```

Manual checks:

- Client starts without immediate crash.
- Login server connection succeeds.
- Character list loads.
- World entry works against `127.0.0.1:7171`.

## Troubleshooting matrix

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| `xcode-select: note: no developer tools were found` | Xcode CLT missing | Run `xcode-select --install`, then reopen shell. |
| `Could not find toolchain file ... vcpkg.cmake` | `VCPKG_ROOT` not exported correctly | Re-source activation script and verify `echo "$VCPKG_ROOT"` and `test -f "$CMAKE_TOOLCHAIN_FILE"`. |
| Build resolves x86_64 instead of arm64 | Arch not pinned or shell running under Rosetta | Verify `uname -m` is `arm64`; configure with `-D CMAKE_OSX_ARCHITECTURES=arm64`; avoid Rosetta terminal. |
| `Could NOT find GLEW` or OpenGL link errors | vcpkg triplet/cache mismatch | Remove stale cache under `adventure-ots/clients/mac/.local/vcpkg_cache`, reconfigure with `VCPKG_TARGET_TRIPLET=arm64-osx`. |
| App launches then crashes after signing | Hardened runtime blocks LuaJIT behavior | Re-sign with tested entitlements (`allow-jit`, optionally `allow-unsigned-executable-memory`) and retest. |
| `spctl` rejects app as untrusted | Unsigned or invalid signature | Re-run `codesign --verify --deep --strict --verbose=2` and sign with valid Developer ID cert. |
| Login works but game world connect fails | Local stack not fully healthy or wrong world IP | Confirm `docker compose ps`, check `gameserver` logs, and keep client target on `127.0.0.1:7171`. |
| Client shows missing sprites/things | Required game data not in package | Ensure `data` folder in app bundle includes protocol 10.98 assets before zipping. |

## Next integration tasks for maintainers

1. Add frontend download UI support for mac artifact route and filename (currently frontend page targets Windows zip only).
2. Add a dedicated packaging helper script for mac (parallel to current Windows packaging flow) under `adventure-ots/clients/mac`.
3. Add CI job on `macos-14` runner to compile `macos-release` preset and publish artifact.
4. Add checksum generation (`sha256`) for mac zip and publish alongside download.
5. Define release signing policy (cert owner, entitlements policy, notarization credentials handling).
6. Add a lightweight regression script that verifies app bundle structure and smoke checks against local stack.

## Operational notes

- First clean build can take significantly longer due dependency resolution and compilation.
- Keep local signing credentials and app-specific passwords outside git and outside shared shell history.
- If build state becomes inconsistent, remove only local cache/build directories under `adventure-ots/clients/mac/.local` and re-run configure/build.
