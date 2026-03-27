# macOS ARM64 OTClient Debugging Context

This document chronicles the comprehensive debugging process for the macOS ARM64 `OTClient` port. It serves as a historical record of the system-level restrictions (Provenance, Gatekeeper) and runtime display architectures (X11/XQuartz, GLX) encountered, and the technical solutions implemented to overcome them.

## 1. Goal
The primary objective was to enable the `adventure-ots` OTClient to build, package, and run natively on macOS ARM64 without crashing due to missing display contexts, while navigating macOS Sequoia's strict security protocols.

---

## 2. Phase I: The X11 Display Server Missing (`SIGABRT`)
**Symptoms:**
- The compiled `.app` crashed immediately on launch with: `Unable to open X11 display (DISPLAY='<unset>')`.
- The C++ backend (`x11window.cpp` / `platformwindow.cpp`) defaults to `X11Window` on macOS due to the lack of a native Cocoa windowing implementation.
- macOS Finder/Spotlight launches do not inherit terminal environment variables.

**Resolution:**
- **Injected Launcher Wrapper:** Modified `package-macos.sh` to package a launcher root.
- The launcher detects XQuartz (`/Applications/Utilities/XQuartz.app`), auto-starts it if missing, waits for the `/tmp/.X11-unix/X0` socket, and exports `DISPLAY=:0` and `XAUTHORITY=~/.Xauthority` before executing the game binary.

---

## 3. Phase II: Provenance Execution Locks (`Operation not permitted`)
**Symptoms:**
- During automated builds, `build-otclient-macos-arm64.sh` failed with `mkdir: Operation not permitted` on the `.local/` and `dist/` directories.
- The terminal process lacked permissions to delete or modify these directories.

**Root Cause:**
- macOS Sequoia's `com.apple.provenance` extended attribute. Directories created by an unnotarized/unapproved AI agent terminal environment are quarantined by system integrity protection, preventing even `sudo` from modifying them from within that same restricted context.

**Resolution - Manual Build Process Requirement:**
When rebuilding after pulling new code or making changes, the user MUST manually run these commands from their native, unrestricted terminal to clear the locked directories:

```bash
# 1. Clean the provenance-locked directories manually
rm -rf /Users/patrykfuta/code/OTS_Poland/adventure-ots/clients/mac/.local
rm -rf /Users/patrykfuta/code/OTS_Poland/adventure-ots/clients/mac/dist

# 2. Recreate them clean
mkdir -p /Users/patrykfuta/code/OTS_Poland/adventure-ots/clients/mac/.local
mkdir -p /Users/patrykfuta/code/OTS_Poland/adventure-ots/clients/mac/dist

# 3. Trigger the build script
cd /Users/patrykfuta/code/OTS_Poland
bash scripts/build-otclient-macos-arm64.sh 2>&1 | tee /tmp/otclient-build.log
```

---

## 4. Phase III: Gatekeeper "Damaged or Incomplete" Errors
**Symptoms:**
- After solving the `SIGABRT` via the shell wrapper, macOS Gatekeeper rejected `OtClient.app` with: *"You can't open the application 'OtClient' because it may be damaged or incomplete."*
- Applying `xattr -cr` stripped quarantine but the error persisted.
- A secondary error occurred: *"The application cannot be opened because its executable is missing."*

**Root Cause:**
- macOS requires locally built apps to have at least an **ad-hoc code signature**.
- `package-macos.sh` was using `codesign --options runtime` (Hardened Runtime) recursively (`--deep`) on the app bundle.
- **Critical Failure:** The `CFBundleExecutable` was a bash script (`OtClient`), not a Mach-O binary. Hardened runtime + shell script launcher is fatally rejected by macOS Sequoia Gatekeeper. Furthermore, `codesign --deep` purged the actual game binary (`OtClient-bin`) from `Contents/MacOS/` because it wasn't the registered main executable.

**Resolution:**
1. **Migrated to Compiled C Launcher:** Replaced the bash shell script wrapper in `package-macos.sh` with a compiled C program (`clang -arch arm64`) that performs the exact same XQuartz bootstrap logic. Now, `CFBundleExecutable` is a valid Mach-O binary.
2. **Re-Architected App Bundle:** Moved the real game binary (`OtClient-bin`) out of `Contents/MacOS/` into `Contents/Helpers/OtClient-bin` to shield it from being purged by codesign routines.
3. **Fixed Code Signing:** Removed `--deep` and `--options runtime`. The script now signs the helper binary first, then the C launcher, and finally seals the bundle `OtClient.app` natively, keeping LuaJIT entitlements intact.

---

## 5. Phase IV: XQuartz GLX Context Creation (`BadValue Apple-DRI`)
**Symptoms:**
- The app launched successfully and bootstrapped XQuartz, but crashed silently in the background. Terminal execution revealed:
  ```text
  X Error of failed request:  BadValue (integer parameter out of range for operation)
  Major opcode of failed request:  129 (Apple-DRI)
  ```

**Root Cause:**
- Apple deprecated hardware OpenGL and the Direct Rendering Infrastructure (DRI) on Apple Silicon.
- When XQuartz attempts to initialize hardware-accelerated GLX, the `Apple-DRI` extension (opcode 129) throws a `BadValue` exception.
- The default Xlib error handler intercepts this and immediately triggers `exit(1)`, killing the client before it can fall back to software/indirect rendering.

**Resolution:**
1. **Forced Indirect Rendering:** Updated the C launcher to globally inject `export LIBGL_ALWAYS_INDIRECT=1`.
2. **XQuartz Preference Toggle:** Required the user to run `defaults write org.xquartz.X11 enable_iglx -bool true` and fully restart XQuartz (`killall Xquartz xinit X11.bin`), to enable software GLX bridging.
3. **Custom Xlib Error Handler (C++ Fix):** Modified `adventure-ots/clients/windows/src/framework/platform/x11window.cpp` to trap and ignore the Xlib crash:
   - Added `XSetErrorHandler(...)` immediately after `XOpenDisplay()`.
   - The handler intercepts `BadValue` thrown by internal expansion opcodes (`request_code >= 128`, targeting Apple-DRI).
   - Instead of terminating the host process, the error is swallowed (returning `0`), allowing the `glXChooseFBConfig` software fallback paths to survive.

---

## 6. Recommendations & Next Steps
As of the current state, the C++ error handler has been implemented in the source code but the binary has not yet been rebuilt to include this fix. The immediate next sequence of actions should be:

### A. Full C++ Rebuild (Required)
The source code modifications to `x11window.cpp` require a full compilation to take effect. 
1. Manually clear the provenance-locked `.local` and `dist` directories.
2. Run `scripts/build-otclient-macos-arm64.sh`.

### B. Verify XQuartz GLX Context
Once the app launches without the `BadValue` crash:
- **Watch the rendering:** Does the game render correctly using indirect GLX software rasterization? Software GLX might have lower performance.
- **Check for `GLXBadContext`:** If a `GLXBadContext` error appears after the Apple-DRI error is suppressed, it means XQuartz's indirect GLX implementation cannot fulfill the requested framebuffer configuration (`attrList` in `internalChooseGLVisual()`).

### C. Fallback: Native SDL2/Cocoa Backend (Long-Term)
If XQuartz software rendering is too slow or fails to provide a valid context:
- The `X11Window` backend on macOS is a technical legacy debt.
- **Recommendation:** Implement a native `MacWindow` backend using standard SDL2 or GLFW, which natively bridge to Apple's Metal/OpenGL frameworks, removing the XQuartz dependency entirely from the macOS build.

rm -rf adventure-ots/clients/mac/.local adventure-ots/clients/mac/dist
bash scripts/build-otclient-macos-arm64.sh
adventure-ots/clients/mac/dist/macos/OtClient.app
