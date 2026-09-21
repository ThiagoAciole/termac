# Termac

A native macOS terminal built with SwiftUI and SwiftTerm. Local tabs, splits, and a focused keyboard-driven workflow.

## Features

- **Split Panes** — Split horizontally or vertically, drag to resize, zoom into any pane
- **Tabs** — Multiple tabs per session with session persistence across relaunches
- **Command Palette** (⌘P) — Fuzzy search across tabs and terminal commands
- **Terminal Search** (⌘F) — Floating search bar with match navigation
- **Terminal History** (⇧⌘H) — Browse, search, and export terminal output
- **Claude Code Integration** — Status notifications inside terminal tabs
- **Auto-Update** — Built-in Sparkle updates

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘T | New Tab |
| ⌘D | Split Right |
| ⇧⌘D | Split Down |
| ⌘F | Find in Terminal |
| ⌘P | Command Palette |
| ⇧⌘H | Terminal History |
| ⌘+/⌘- | Font Size |

## Requirements

- macOS 15.0+
- Apple Silicon or Intel

## Build from Source

```bash
# Install dependencies
brew install xcodegen create-dmg

# Generate Xcode project
xcodegen generate

# Build
xcodebuild -project Termac.xcodeproj -scheme Termac -configuration Release build
```

## Tech Stack

- **SwiftUI** + **Swift 6.0** — UI and concurrency
- **[SwiftTerm](https://github.com/migueldeicaza/SwiftTerm)** — Terminal emulation
- **[Sparkle](https://sparkle-project.org/)** — Auto-update

## Download

Get the latest release from the [Releases](https://github.com/MengnanTech/Termac/releases) page.

## License

[MIT](LICENSE)
