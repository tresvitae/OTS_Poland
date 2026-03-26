# Scripts

## build-otclient-macos-arm64.sh

`scripts/build-otclient-macos-arm64.sh` is the top-level macOS arm64 OTClient build and packaging entrypoint.

- Validates that `adventure-ots/clients/mac/tools/build-and-package-macos-arm64.sh` exists and is executable.
- Executes the macOS build/package flow from the repository root.
- Prints clear success output with canonical ZIP and checksum artifact paths.

**Usage**

```bash
bash scripts/build-otclient-macos-arm64.sh
```

Canonical outputs are written to `adventure-ots/frontend/public/downloads/macos`:

- `adventure-ots-client-macos-arm64.zip`
- `adventure-ots-client-macos-arm64.zip.sha256`

## test-client.ps1

`scripts/test-client.ps1` verifies freshly packaged OTClient bundles without touching your local install:

- Extracts `adventure-ots/frontend/public/downloads/windows/adventure-ots-client-windows.zip` (or a custom `-ZipPath`) into `%TEMP%/otclient-test-*`.
- Prints OTClient startup diagnostics from `otclient.log` (GPU/OpenGL info, fatal module errors, and startup banner), including timeout/failure cases.
- Accepts helper flags:
	- `-EnableDebug` appends `--debug` to the client.
	- `-ClientArgs '--force-opengl --some-flag'` passes extra parameters.
	- `-TimeoutSeconds 20` controls how long to wait before killing the process.
	- `-FailOnTimeout` turns lingering clients into hard failures; omit it to treat a running window as success.
	- `-KeepExtracted` skips cleanup so you can inspect the temp payload.

**Usage**

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-client.ps1 -EnableDebug -TimeoutSeconds 20 -FailOnTimeout
```

Run it after packaging to catch missing modules or DLLs before distributing the zip.
