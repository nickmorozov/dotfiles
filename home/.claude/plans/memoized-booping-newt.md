# Plan: Onboarding Wizard, DMG Packaging, and Landing Page

## Context

The app requires two macOS permissions to function: **Accessibility** (for CGEventTap media key interception) and **Automation** (for osascript control of Focusrite Control 2). Currently, there is no onboarding flow — the app silently fails if permissions aren't granted, with only a console warning. The user wants:

1. A **permission wizard** shown every launch until both permissions are granted, explaining why each is needed and providing buttons to grant them
2. A **DMG build script** for distribution outside the App Store (the app cannot use the App Store due to sandbox restrictions on CGEventTap and osascript)
3. A **landing page** in `site/` for marketing and download

## Deliverable 1: Permission Onboarding Wizard

### New File: `OnboardingView.swift`

A SwiftUI view shown as a sheet/window on every launch until both permissions are confirmed. Two-step flow:

**Step 1 — Accessibility Permission**
- Icon: `lock.shield` or `hand.raised.fill`
- Explanation: "This app intercepts your Mac's volume keys so they control your Focusrite instead of the built-in speakers. This requires Accessibility permission."
- Status indicator: green checkmark if granted, yellow warning if not
- Button: "Grant Accessibility Access" — calls `AXIsProcessTrustedWithOptions` with `kAXTrustedCheckOptionPrompt: true` to trigger the system dialog
- "Open System Settings" fallback link: deep-links to `x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility`

**Step 2 — Automation Permission**
- Icon: `gearshape.2` or `applescript`
- Explanation: "This app controls Focusrite Control 2 using Apple Events automation to read and set your volume levels."
- Status indicator: green checkmark if granted, yellow warning if not
- Button: "Test Automation Access" — runs a lightweight osascript that triggers the system automation permission prompt (e.g., `tell application "System Events" to return name of first process`)
- Note: macOS prompts for Automation permission on first use, so we trigger a benign script

**Permission Check Functions** (in `OnboardingView.swift` or a small helper):
- `isAccessibilityGranted() -> Bool`: calls `AXIsProcessTrusted()` (from ApplicationServices framework)
- `isAutomationGranted() -> Bool`: attempts a lightweight osascript and checks exit code
- `areAllPermissionsGranted() -> Bool`: combines both checks

**Visual Design:**
```
┌─────────────────────────────────────────────┐
│                                             │
│   🔒  Focusrite Volume Control Setup        │
│                                             │
│   Step 1: Accessibility                     │
│   ✅ Granted  (or ⚠️ Required)              │
│   "Intercepts volume keys..."               │
│   [ Grant Accessibility Access ]            │
│                                             │
│   Step 2: Automation                        │
│   ✅ Granted  (or ⚠️ Required)              │
│   "Controls Focusrite Control 2..."         │
│   [ Test Automation Access ]                │
│                                             │
│   ─────────────────────────────             │
│   [ Re-check Permissions ]    [ Continue ]  │
│                                             │
└─────────────────────────────────────────────┘
```

- "Continue" button only enabled when both permissions are granted
- "Re-check Permissions" polls both checks and updates the UI
- A timer also re-checks every 2 seconds while the window is visible (user may grant in System Settings and come back)

### Modified File: `AppDelegate.swift`

In `applicationDidFinishLaunching`:
- **Before** `setupMediaKeyTap()` and `connect()`, check `areAllPermissionsGranted()`
- If **not** all granted → show the onboarding window (NSWindow with NSHostingController)
- Store a reference to the window; dismiss it when permissions are confirmed
- On dismiss → proceed with `setupMediaKeyTap()` and `connect()`
- If **already** granted → skip onboarding, proceed as today

Add a property:
```swift
private var onboardingWindow: NSWindow?
```

Add method:
```swift
func showOnboardingIfNeeded() {
    guard !areAllPermissionsGranted() else {
        proceedAfterOnboarding()
        return
    }
    // Create and show onboarding window
    // On "Continue" button → dismiss window, call proceedAfterOnboarding()
}

func proceedAfterOnboarding() {
    setupMediaKeyTap()
    setupHotkeyManager()
    volumeController.connect()
}
```

Current launch sequence calls these individually — refactor to gate them behind onboarding.

## Deliverable 2: DMG Build Script

### New File: `scripts/build-dmg.sh`

A shell script that:

1. **Builds** a Release archive:
   ```bash
   xcodebuild archive \
     -scheme FocusriteVolumeControl \
     -configuration Release \
     -archivePath ./build/FocusriteVolumeControl.xcarchive
   ```

2. **Exports** the archive to a `.app`:
   ```bash
   xcodebuild -exportArchive \
     -archivePath ./build/FocusriteVolumeControl.xcarchive \
     -exportPath ./build/export \
     -exportOptionsPlist ExportOptions.plist
   ```

3. **Creates a DMG** with a drag-to-Applications layout:
   ```bash
   mkdir -p ./build/dmg
   cp -R ./build/export/FocusriteVolumeControl.app ./build/dmg/
   ln -s /Applications ./build/dmg/Applications
   hdiutil create -volname "FocusriteVolumeControl" \
     -srcfolder ./build/dmg \
     -ov -format UDZO \
     ./build/FocusriteVolumeControl.dmg
   ```

4. **Optionally notarizes** (if credentials are provided via env vars):
   ```bash
   if [ -n "$APPLE_ID" ] && [ -n "$TEAM_ID" ] && [ -n "$APP_PASSWORD" ]; then
     xcrun notarytool submit ... --wait
     xcrun stapler staple ...
   fi
   ```

### New File: `ExportOptions.plist`

Required by `xcodebuild -exportArchive`. Minimal content:
```xml
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>destination</key>
    <string>export</string>
</dict>
```

Note: Without a Developer ID certificate, the script will build unsigned. The user can add signing later when they obtain the certificate. The script will include a comment explaining this.

## Deliverable 3: Landing Page

### New Directory: `site/`

A single-page static site with:

**`site/index.html`** — Main page
- Hero section: app name, tagline ("Control your Focusrite volume with keyboard shortcuts"), screenshot/demo
- Features section: media key interception, custom HUD, perceptual volume curve, hotkey support
- Download section: DMG download button (link to GitHub Releases)
- Setup section: brief permission explanation with screenshots
- Footer: GitHub link, license info

**`site/style.css`** — Styling
- Dark theme (matches the app's aesthetic)
- Responsive single-page layout
- Clean typography, minimal design
- macOS-inspired visual style (rounded corners, blur effects via CSS)

**`site/screenshot.png`** — placeholder reference (user can add actual screenshots later)

The landing page will be a self-contained static site deployable to GitHub Pages or any static host. No build tools, no JavaScript frameworks — plain HTML + CSS.

## Files Summary

| Action | File | Purpose |
|--------|------|---------|
| **Create** | `OnboardingView.swift` | Permission wizard SwiftUI view |
| **Modify** | `AppDelegate.swift` | Gate launch on permission check, show onboarding |
| **Create** | `scripts/build-dmg.sh` | DMG build + optional notarization script |
| **Create** | `ExportOptions.plist` | Xcode export configuration |
| **Create** | `site/index.html` | Landing page |
| **Create** | `site/style.css` | Landing page styles |

## Verification

1. **Build**: `xcodebuild -scheme FocusriteVolumeControl -configuration Debug build`
2. **Tests**: `xcodebuild test -scheme FocusriteVolumeControl -configuration Debug`
3. **Onboarding**: Revoke Accessibility permission in System Settings → relaunch app → wizard should appear. Grant permission → wizard should update status. Grant both → "Continue" enables → clicking it proceeds to normal app behavior.
4. **DMG Script**: `bash scripts/build-dmg.sh` → produces `build/FocusriteVolumeControl.dmg`. Mount the DMG → drag app to Applications → launch → verify it works.
5. **Landing Page**: `open site/index.html` in browser → page renders correctly, responsive on mobile widths.
