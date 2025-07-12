### Project Overview
This is an iOS music player app designed to replicate the classic iPod experience, integrated with Spotify for music streaming. The app aims to provide a nostalgic and focused music listening experience through a retro user interface and click-wheel interaction.

### Architecture
The project is a native iOS application built with SwiftUI. It connects to the Spotify API for music data and playback control.

```
                   +-------------------------+
                   |      LovePod iOS App    |
                   |       (SwiftUI)         |
                   +-----------+-------------+
                               |
                               v
+------------------------------+---------------------------------+
|                                                                |
|  +-------------------------+      +-------------------------+  |
|  |     UI Components       |      |     Business Logic      |  |
|  |  (Views, Controls)      |      |   (State Management)    |  |
|  +-------------------------+      +-------------------------+  |
|                                                                |
+------------------------------+---------------------------------+
                               |
                               v
                   +-----------+-------------+
                   |     Spotify Service     |
                   | (API & SDK Integration) |
                   +-------------------------+
```

### File Structure Convention
```
.
├── doc/                  # Documentation (PRD, design files)
├── lovepod/              # Main application source code
│   ├── Assets.xcassets   # Image assets, icons, colors
│   ├── ContentView.swift # Main view of the app
│   └── lovepodApp.swift  # App entry point
├── lovepod.xcodeproj/    # Xcode project configuration
├── lovepodTests/         # Unit tests
└── lovepodUITests/       # UI tests
```

### Key Technical Details
- **UI Framework**: SwiftUI
- **Audio Service**: Spotify iOS SDK for playback and control.
- **API**: Spotify Web API for fetching playlists and track metadata.
- **Authentication**: OAuth 2.0 for Spotify user authorization.
- **State Management**: Likely to use Combine and `ObservableObject` for managing application state.
- **Design**: The UI/UX is heavily based on the classic iPod, including the iconic click-wheel.

### Development Commands
As this is a standard Xcode project, all development, building, and testing is done through the Xcode IDE.

- **Run/Build**: Use the "Product" -> "Run" (or `Cmd+R`) and "Product" -> "Build" (or `Cmd+B`) menus in Xcode.
- **Test**: Use the "Product" -> "Test" (or `Cmd+U`) menu in Xcode to run both unit and UI tests.

### Build & Testing
- **Device**: A physical iOS device with the Spotify app installed is required for testing, as the Spotify iOS SDK does not work on the simulator.
- **Dependencies**: The SpotifyiOS.framework needs to be included in the project.
- **Configuration**: The project's `Info.plist` must be configured with a Spotify Client ID, a redirect URI, and the necessary URL schemes.

### Other Important Information
- **Spotify App Requirement**: The official Spotify app must be installed on the testing device.
- **API Keys**: A Spotify Developer App needs to be created to get a Client ID for the API.
- **Permissions**: The app will request user permission to access their Spotify data, including playlists.
