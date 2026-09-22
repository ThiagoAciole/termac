# Troubleshooting

## Gatekeeper blocks the app

Release builds are self-signed (not notarized). On first open, macOS may refuse to launch the app.

**Recommended:** right-click (or Control-click) `Termac.app` → **Open** → **Open** again. Once is enough.

**Alternative:**

```bash
xattr -dr com.apple.quarantine /path/to/Termac.app
open /path/to/Termac.app
```

To confirm the release signature (Authority **and** leaf fingerprint — CN alone is forgeable):

```bash
codesign -dv --verbose=4 /path/to/Termac.app
# expect Authority=Termac Self-Signed
codesign -d --extract-certificates=/tmp/termac-cert /path/to/Termac.app
openssl x509 -inform DER -in /tmp/termac-cert0 -noout -fingerprint -sha256
# expect SHA256 Fingerprint=82:9B:F9:9F:A6:C3:28:64:98:C3:57:24:04:3A:F2:CD:71:4B:35:BD:D1:C2:88:B7:D8:86:B6:C2:DD:E2:2C:11
rm -f /tmp/termac-cert*
```

Homebrew installs clear quarantine automatically — see [HOMEBREW.md](HOMEBREW.md).

See also the Self-signed builds section in the [README](../README.md) and [SIGNING.md](SIGNING.md).

## Ghostty packages fail to resolve / missing submodule

The app depends on `Vendor/libghostty-spm`. After a clone without `--recurse-submodules`:

```bash
git submodule update --init --recursive
```

Then reopen `Termac.xcodeproj` and build the **termac** scheme.

## Stale libghostty after a submodule bump

If the binary framework looks wrong after updating `Vendor/libghostty-spm`, clean DerivedData for the project (or Product → Clean Build Folder in Xcode) and rebuild.

## Shells fail / no PTY

App sandbox must stay **off** (`ENABLE_APP_SANDBOX = NO`). Termac uses Ghostty’s `.exec` backend to spawn a real login shell; enabling the sandbox breaks that.
