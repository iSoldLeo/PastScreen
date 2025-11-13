# 📸 ScreenSnap

**Ultra-fast screenshots for developers**

macOS app with optimized workflow: Capture → ⌘V → Paste into your IDE!

[![Version](https://img.shields.io/badge/version-1.1-blue.svg)](https://github.com/augiefra/ScreenSnap/releases/tag/v1.1)
[![Platform](https://img.shields.io/badge/platform-macOS%2013.0%2B-lightgrey.svg)](https://www.apple.com/macos)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

## ✨ What's New in v1.1

- 🎨 **Modern Onboarding** : Liquid glass interface with 4 animated pages
- 🌍 **Multilingual** : Full support for FR/EN/ES/DE/IT
- 🖼️ **Dock Toggle** : Choose to show or hide the Dock icon
- 📐 **Improved Preferences** : Larger and optimized interface
- 🧹 **Cleanup** : Removed non-functional settings

## 🚀 Features

- 📸 **Area Capture** : Interactive selection with translucent overlay
- 🖥️ **Full Screen Capture** : One click to capture everything
- ⚡ **Ultra-fast** : ⌘⇧5 → Capture → ⌘V → Pasted!
- 📋 **Auto-copy** : Direct to clipboard for your IDEs
- 🧹 **Auto-cleanup** : Temp files cleared on reboot
- 🔔 **Notifications** : Click to open in Finder
- 🎨 **Modern Interface** : Liquid glass onboarding Apple-style
- 🌍 **Multilingual** : French, English, Spanish, German, Italian
- ⚙️ **Customizable** : Format, sound, shortcuts, storage, Dock

## 💾 Installation

### From DMG (Recommended)

1. **Download** : [ScreenSnap-1.1.dmg](https://github.com/augiefra/ScreenSnap/releases/latest)
2. **Mount** the DMG
3. **Drag** `ScreenSnap.app` to `Applications`
4. **Launch** from Applications
5. **Grant** permissions (Screen Recording + Accessibility)

### From Source

```bash
git clone https://github.com/augiefra/ScreenSnap
cd ScreenSnap
open ScreenSnap.xcodeproj
```

Then: `Product → Archive → Export`

## 🎯 Usage

### Keyboard Shortcuts

- **⌘⇧5** : Capture area (default shortcut)
- **Click menu bar icon** : Open full menu

### Menu Bar

- 📸 Capture Area ⌘⇧5
- 🖥️ Capture Full Screen
- 📁 Show Last Screenshot
- ⚙️ Preferences...
- ❌ Quit ScreenSnap

### Developer Workflow

```
1. ⌘⇧5 (or click menu bar)
2. Select the area to capture
3. ⌘V in Cursor/VSCode/Zed
   → Image pasted directly!
```

**Perfect for:**
- Pasting screenshots into Claude Code, Cursor, Zed, VSCode
- Sharing bugs on Slack, Discord, Linear, GitHub Issues
- Documenting in Figma, Notion, Obsidian

## ⚙️ Configuration

### General Tab
- ✅ Show icon in Dock
- ✅ Copy to clipboard (auto)
- 🔊 Play sound on capture
- 📋 Show startup tutorial

### Capture Tab
- 🖼️ **Format** : PNG (lossless) or JPEG (compressed)
- ⌨️ **Shortcut** : Customizable (default ⌘⇧5)
- 🎹 Enable global shortcut

### Storage Tab
- 💾 **Save to disk** : Optional
- 📁 **Folder** : Temp (auto-cleaned) or permanent
- 🗑️ **Clear folder** : Manual cleanup

## 🌍 Supported Languages

ScreenSnap automatically detects system language:

- 🇫🇷 **Français** - Full interface + onboarding
- 🇬🇧 **English** - Full interface + onboarding
- 🇪🇸 **Español** - Full interface + onboarding
- 🇩🇪 **Deutsch** - Full interface + onboarding
- 🇮🇹 **Italiano** - Full interface + onboarding

## 🛠️ Development

### Prerequisites
- macOS 13.0+ (Ventura)
- Xcode 15+
- Swift 5.9+

### Project Structure

```
ScreenSnap/
├── ScreenSnap/
│   ├── ScreenSnapApp.swift           # AppKit entry point
│   ├── Models/
│   │   └── AppSettings.swift         # Singleton settings
│   ├── Views/
│   │   ├── SettingsView.swift        # SwiftUI preferences
│   │   ├── ModernOnboardingView.swift     # Liquid glass onboarding
│   │   └── ModernOnboardingWindow.swift   # Window manager
│   ├── Services/
│   │   ├── ScreenshotService.swift   # Core capture logic
│   │   └── HotKeyManager.swift       # Global hotkeys
│   ├── Utils/
│   │   └── Logger.swift              # Debug logging
│   └── *.lproj/                      # Localizations
│       └── Localizable.strings
└── SelectionWindow.swift             # Capture overlay
```

### Technologies

- **SwiftUI** : Modern interface (onboarding, preferences)
- **AppKit** : Menu bar, windows, selection overlay
- **Carbon API** : Global keyboard shortcuts
- **CGDisplayImage** : Native screen capture
- **NSPasteboard** : Clipboard management
- **UserDefaults** : Settings persistence

### Build

```bash
# Debug
xcodebuild -scheme ScreenSnap -configuration Debug build

# Release
xcodebuild -scheme ScreenSnap -configuration Release build
```

### Create DMG

```bash
# Install create-dmg
brew install create-dmg

# Build Release
xcodebuild -scheme ScreenSnap -configuration Release build

# Copy app
cp -R ~/Library/Developer/Xcode/DerivedData/.../ScreenSnap.app ~/Desktop/

# Create DMG
create-dmg \
  --volname "ScreenSnap" \
  --background "dmg-background.png" \
  --window-size 600 400 \
  --icon-size 100 \
  --app-drop-link 425 190 \
  "ScreenSnap-1.1.dmg" \
  "~/Desktop/ScreenSnap.app"
```

## 📝 Required Permissions

### Screen Recording
**Why?** To capture screen content

**How?** System Settings → Privacy & Security → Screen Recording → ✅ ScreenSnap

### Accessibility
**Why?** For global keyboard shortcut ⌘⇧5

**How?** System Settings → Privacy & Security → Accessibility → ✅ ScreenSnap

⚠️ **These permissions are automatically requested on first launch**

## ✨ Why ScreenSnap?

### vs. macOS Native Capture
| Native | ScreenSnap |
|--------|------------|
| ❌ Files accumulate on Desktop | ✅ Auto-cleanup on reboot |
| ❌ No custom shortcuts | ✅ Configurable shortcuts |
| ❌ Basic interface | ✅ Modern liquid glass onboarding |

### vs. Other Screenshot Apps
| Other Apps | ScreenSnap |
|------------|------------|
| ❌ Complex interface | ✅ Simple and fast |
| ❌ No auto-cleanup | ✅ Optimized "disposable" workflow |
| ❌ Single language | ✅ Multilingual (5 languages) |
| ❌ Cluttered Dock | ✅ Menu bar only mode |

### Developer-Optimized Workflow

```
Problem: Capture bug → Find file → Send it
Solution: ⌘⇧5 → ⌘V → Already pasted in Slack!

Problem: Screenshots everywhere on Desktop
Solution: Auto-cleanup on reboot → Always clean Desktop

Problem: Complex interface with 20 options
Solution: 3 clicks max to configure, instant workflow
```

## 🤝 Contributing

Contributions are welcome!

1. **Fork** the project
2. **Create** a branch (`git checkout -b feature/improvement`)
3. **Commit** (`git commit -m 'feat: Add feature'`)
4. **Push** (`git push origin feature/improvement`)
5. **Open** a Pull Request

### Guidelines

- Clean Swift code (SwiftLint)
- Tests for new features
- Documentation in English
- Conventional commit messages (feat/fix/docs/refactor)

## 📄 License

MIT License - See [LICENSE](LICENSE)

## 🔗 Useful Links

- **Documentation** : [CLAUDE.md](CLAUDE.md)
- **Releases** : [GitHub Releases](https://github.com/augiefra/ScreenSnap/releases)
- **Issues** : [GitHub Issues](https://github.com/augiefra/ScreenSnap/issues)
- **Changelog** : See releases for complete history

## 🎉 Changelog v1.1

### Added
- ✨ Modern onboarding with liquid glass effect and 4 animated pages
- 🌍 Complete multilingual support (FR/EN/ES/DE/IT)
- 🖼️ Toggle to show/hide Dock icon
- 📐 Larger preferences window (600x500)

### Improved
- 🧹 Cleaned up preferences (removed non-functional options)
- 🎨 Onboarding interface with spring animations
- 📝 Native translations for all languages

### Technical
- Fluid SwiftUI animations
- NSLocalizedString for i18n
- VisualEffectBlur for liquid glass
- Backward compatibility via typealias

---

**Version** : 1.1
**Build** : 3
**Compatibility** : macOS 13.0+ (Ventura, Sonoma, Sequoia)
**Author** : Eric COLOGNI
**License** : MIT
