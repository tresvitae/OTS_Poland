# OTClient macOS Download

## Troubleshooting: Gatekeeper Error

If you see an error dialog stating **"You can’t open the application “OtClient” because it may be damaged or incomplete."**, this happens because the downloaded application is currently unsigned and macOS Gatekeeper is blocking it.

To bypass this and mark the application as safe to run, open your Terminal and run the following command, making sure to adjust the path to wherever you extracted the `OtClient.app`:

```bash
xattr -cr /path/to/OtClient.app
```

Once this command is executed, you should be able to double-click and launch the application normally.
