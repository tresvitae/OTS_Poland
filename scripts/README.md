# Scripts

## test-client.ps1

`scripts/test-client.ps1` verifies freshly packaged OTClient bundles without touching your local install:

- Extracts `aac-frontend/public/downloads/windows/adventure-ots-client-windows.zip` (or a custom `-ZipPath`) into `%TEMP%/otclient-test-*`.
- Streams OTClient stdout/stderr in real time so GPU info and fatal module errors are visible even if the process never exits cleanly.
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
