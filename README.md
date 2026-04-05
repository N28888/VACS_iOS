# VACS Remote iOS

`VACS Remote iOS` is a native SwiftUI shell for the VACS desktop remote-control interface.

It does not reimplement the VACS control surface in SwiftUI. Instead, it opens the desktop app's existing remote UI inside `WKWebView`, so the iPhone/iPad experience stays aligned with the upstream VACS web remote.

## What It Does

- Connects to a VACS desktop instance by address
- Stores recent desktop endpoints locally
- Opens the remote interface full screen in `WKWebView`
- Supports iPhone and iPad
- Preserves the desktop/web remote UI instead of maintaining a second native control implementation

## Current Behavior

- Accepts `IP`, `IP:PORT`, or full `http://` / `https://` URLs
- Defaults to port `9600`
- Shows a trusted-network warning before connecting
- Disables pinch zoom in the embedded remote page
- Uses a custom app icon based on the VACS logo

## Project Structure

- [`VACSRemote`](/Users/yifanjin/Documents/GitHub/vacs_ios/VACSRemote): app source
- [`VACSRemoteTests`](/Users/yifanjin/Documents/GitHub/vacs_ios/VACSRemoteTests): unit and integration-style tests
- [`VACSRemoteUITests`](/Users/yifanjin/Documents/GitHub/vacs_ios/VACSRemoteUITests): UI tests
- [`VACSRemote.xcodeproj`](/Users/yifanjin/Documents/GitHub/vacs_ios/VACSRemote.xcodeproj): Xcode project

## Main Components

- `ConnectionListView`: recent server list and connect flow
- `ConnectionFormView`: add/edit endpoint form
- `RemoteSessionView`: full-screen remote session container
- `EndpointNormalizer`: normalizes address input
- `ConnectionRepository`: persists recent endpoints in `UserDefaults`
- `RemoteWebViewModel`: manages connect/disconnect state
- `WebViewContainer`: hosts the remote UI in `WKWebView`

## Build

Open the project in Xcode:

```bash
open VACSRemote.xcodeproj
```

Or build from the command line:

```bash
xcodebuild -scheme VACSRemote -project VACSRemote.xcodeproj -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build
```

## Requirements

- Xcode 26.0 or newer in the current setup
- iOS deployment target: `26.0`

## Notes On Networking

- The app connects to a VACS desktop remote server over HTTP
- The remote endpoint itself does not provide authentication or encryption
- Only use it on a trusted LAN or trusted VPN path

## Publishing Checklist

Before pushing this repo to GitHub, review the items below:

- `VACSRemote.xcodeproj/project.pbxproj`
  Contains `DEVELOPMENT_TEAM = UKWBW3QP24;`
- `VACSRemote.xcodeproj/project.pbxproj`
  Contains your current bundle identifiers such as `network.vacs.remote.ios`
- `VACSRemote.xcodeproj/project.xcworkspace/xcuserdata/...`
  User-specific Xcode workspace state should usually not be committed
- `.DS_Store`
  Finder metadata should usually not be committed
- `VACSRemoteUITests/VACSRemoteUITests.swift`
  Contains hardcoded loopback test addresses like `127.0.0.1:9600`

None of the above were removed automatically.

## Recommended Git Ignore Entries

Typical entries you may want in `.gitignore`:

```gitignore
.DS_Store
xcuserdata/
*.xcuserstate
```

## Limitations

- This app depends on the VACS desktop app serving its remote web UI
- It is intentionally a thin shell, not a full native reimplementation
- If the upstream remote web UI changes, the in-app experience changes with it

## License

This repository currently does not declare a license. Add one before publishing if you want others to reuse or modify the code.
