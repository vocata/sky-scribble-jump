# Open Source Checklist

Before publishing the repository publicly:

- Review the MIT license holder in `LICENSE`.
- Update `README.md` with screenshots or a gameplay GIF.
- Confirm whether the bundle identifier in `export_presets.cfg` should stay `com.leixueyue.skyscribblejump`.
- Run `make check`.
- Run `make export-macos` and test the exported app locally.
- For public macOS downloads, sign with a Developer ID Application certificate and notarize the build.
- Confirm that all committed assets are intended to be redistributed.
