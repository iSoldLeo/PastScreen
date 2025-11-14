# 🔄 Sparkle Auto-Update Integration for ScreenSnap v1.4

## Prerequisites

Before applying code changes, you MUST add Sparkle via Swift Package Manager in Xcode.

### Step 1: Add Sparkle Package (REQUIRED - Do this first!)

1. Open Xcode:
   ```bash
   cd /Users/ecologni/Desktop/Clemadel/ScreenSnap
   open ScreenSnap.xcodeproj
   ```

2. In Xcode:
   - File → Add Package Dependencies...
   - Package URL: `https://github.com/sparkle-project/Sparkle`
   - Dependency Rule: "Up to Next Major Version" → `2.0.0` < `3.0.0`
   - Click "Add Package"
   - Select "Sparkle" (NOT SparkleCore) → Add Package

3. Verify installation:
   - Check that Sparkle appears in Project Navigator under "Package Dependencies"

### Step 2: Generate EdDSA Keys

```bash
# Download Sparkle tools
cd /tmp
curl -LO https://github.com/sparkle-project/Sparkle/releases/download/2.5.2/Sparkle-2.5.2.tar.xz
tar xf Sparkle-2.5.2.tar.xz

# Generate key pair
./bin/generate_keys
```

**Output example:**
```
A key has been generated and saved in your keychain. Add the public key to your Info.plist:

<key>SUPublicEDKey</key>
<string>abcd1234efgh5678ijkl...</string>

Keep your private key SECRET and backed up!
```

**Important:**
- Copy the PUBLIC key (starts with SUPublicEDKey) - you'll need it for Info.plist
- Save the PRIVATE key securely (1Password/LastPass) - NEVER commit it
- The private key is stored in macOS Keychain under name "Sparkle EdDSA Key"

### Step 3: Apply Code Changes

Once Sparkle package is added in Xcode, apply these modifications:

#### A. ScreenSnapApp.swift - Add Sparkle Import & Controller

Add import at the top:
```swift
import Sparkle
```

Add property to AppDelegate class:
```swift
class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    // ... existing properties ...

    // Sparkle auto-updater
    private var updaterController: SPUStandardUpdaterController?
```

In `applicationDidFinishLaunching`, add after onboarding setup:
```swift
// Initialize Sparkle auto-updater
updaterController = SPUStandardUpdaterController(
    startingUpdater: true,
    updaterDelegate: nil,
    userDriverDelegate: nil
)
NSLog("✅ [SPARKLE] Auto-updater initialized")
```

In `createMenu()`, add menu item after "Preferences...":
```swift
// Check for Updates...
let checkUpdatesItem = NSMenuItem(
    title: NSLocalizedString("menu.check_updates", comment: "Check for Updates..."),
    action: #selector(checkForUpdates),
    keyEquivalent: ""
)
menu.addItem(checkUpdatesItem)

menu.addItem(NSMenuItem.separator())
```

Add method to AppDelegate:
```swift
@objc func checkForUpdates() {
    updaterController?.checkForUpdates(nil)
}
```

#### B. Info.plist - Configure Sparkle

Add these keys:
```xml
<key>SUFeedURL</key>
<string>https://raw.githubusercontent.com/augiefra/ScreenSnap-Distribution/main/appcast.xml</string>

<key>SUPublicEDKey</key>
<string>PASTE_YOUR_PUBLIC_KEY_HERE</string>

<key>SUEnableAutomaticChecks</key>
<true/>

<key>SUAutomaticallyUpdate</key>
<false/>

<key>SUAllowsAutomaticUpdates</key>
<true/>
```

#### C. AppSettings.swift - Add Auto-Update Preference

Add property:
```swift
@AppStorage("autoCheckUpdates") var autoCheckUpdates: Bool = true
```

#### D. SettingsView.swift - Add UI Toggle

In General tab, add:
```swift
// Auto-update toggle
Toggle(isOn: $settings.autoCheckUpdates) {
    Text("Check for updates automatically")
        .font(.system(size: 13))
}
.help("Automatically check for new versions on startup")
```

### Step 4: Create Appcast & Release Script

Create `scripts/create_release.sh`:
```bash
#!/bin/bash

VERSION="$1"
if [ -z "$VERSION" ]; then
    echo "Usage: ./create_release.sh <version>"
    echo "Example: ./create_release.sh 1.4"
    exit 1
fi

echo "🚀 Creating release for ScreenSnap v$VERSION"

# Paths
APP_PATH="build/Build/Products/Release/ScreenSnap.app"
DMG_NAME="ScreenSnap-$VERSION.dmg"
APPCAST_PATH="appcast.xml"

# 1. Build Release
echo "📦 Building Release..."
xcodebuild -scheme ScreenSnap -configuration Release clean build

# 2. Create DMG
echo "💿 Creating DMG..."
hdiutil create -volname "ScreenSnap" -srcfolder "$APP_PATH" -ov -format UDZO "$DMG_NAME"

# 3. Sign DMG with Sparkle
echo "🔐 Signing with Sparkle..."
/tmp/bin/sign_update "$DMG_NAME" -f "$APPCAST_PATH"

# 4. Generate appcast entry
echo "📋 Generating appcast entry..."
/tmp/bin/generate_appcast .

echo "✅ Release ready: $DMG_NAME"
echo "📤 Upload to GitHub Releases and update appcast.xml"
```

### Step 5: Create Initial Appcast

Create `appcast.xml` in distribution repo:
```xml
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
    <channel>
        <title>ScreenSnap Updates</title>
        <link>https://github.com/augiefra/ScreenSnap-Distribution</link>
        <description>Latest updates for ScreenSnap</description>
        <language>en</language>

        <item>
            <title>Version 1.4</title>
            <description>
                <![CDATA[
                    <h2>What's New in v1.4</h2>
                    <ul>
                        <li>🔄 Auto-update system via Sparkle</li>
                        <li>🎨 Native selection window (no more screencapture binary)</li>
                        <li>🔔 Reliable notifications in menu bar-only mode</li>
                        <li>🏗️ Modern ScreenCaptureKit API throughout</li>
                    </ul>
                ]]>
            </description>
            <pubDate>Mon, 14 Jan 2025 12:00:00 +0000</pubDate>
            <sparkle:version>1.4</sparkle:version>
            <sparkle:shortVersionString>1.4</sparkle:shortVersionString>
            <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
            <enclosure
                url="https://github.com/augiefra/ScreenSnap-Distribution/releases/download/v1.4/ScreenSnap-1.4.dmg"
                length="FILESIZE_BYTES"
                type="application/octet-stream"
                sparkle:edSignature="SIGNATURE_HERE" />
        </item>
    </channel>
</rss>
```

### Step 6: Testing

1. Build the app with Sparkle integrated
2. Run the app
3. Check Menu Bar → "Check for Updates..." appears
4. Test update check (should show "No updates available" initially)
5. Create a fake v1.5 release to test download/install flow

### Step 7: Release Workflow

For each new release:
```bash
# 1. Update version in Xcode (Info.plist)
# 2. Build and create DMG
./scripts/create_release.sh 1.4

# 3. Upload DMG to GitHub Releases
# 4. Update appcast.xml with new entry
# 5. Commit and push appcast.xml to distribution repo
```

## Troubleshooting

**"No updates found" even with new version:**
- Check SUFeedURL points to correct appcast.xml
- Verify appcast.xml is accessible (open URL in browser)
- Check version number is higher than current

**"Update signature invalid":**
- Ensure you used correct private key to sign
- Verify SUPublicEDKey matches the keypair

**Updates not checking automatically:**
- Verify SUEnableAutomaticChecks = true in Info.plist
- Check autoCheckUpdates setting in AppSettings

## Security Notes

- **NEVER commit private key to git**
- Store private key in secure vault (1Password/LastPass)
- Private key is in macOS Keychain: "Sparkle EdDSA Key"
- Public key is safe to commit (in Info.plist)
- Always sign releases before publishing

## References

- [Sparkle Documentation](https://sparkle-project.org/documentation/)
- [Sparkle 2 Migration Guide](https://sparkle-project.org/documentation/migration/)
- [EdDSA Signatures](https://sparkle-project.org/documentation/security/)
