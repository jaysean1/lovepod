# Project Overview

LovePod is an iOS app based on SwiftUI, recreating the classic iPod user experience and visual design, integrated with Spotify services. The project adopts a modular architecture and uses a modern SwiftUI technology stack to achieve a retro interactive experience.

## Development Commands

### Build and Run
```bash
# Build and run the project in the iPhone 16 simulator
xcodebuild -scheme lovepod -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' build

# Open the project with Xcode
open lovepod.xcodeproj

# Clean the build cache
xcodebuild clean -scheme lovepod

# Build and run on the specified simulator
xcodebuild -scheme lovepod -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' build test
```

### Testing
```bash
# Run unit tests
xcodebuild test -scheme lovepod -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16'

# Run UI tests
xcodebuild test -scheme lovepod -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:lovepodUITests
```

### Development Device Requirements
- **Recommended Development Device**: iPhone 16 Simulator
- **Spotify Feature Testing**: Requires a real iOS device (Spotify SDK requirement)
- **iOS Version Requirement**: iOS 15.0+
- **Xcode Version**: Xcode 14.0+

## Architecture Overview

### Core Components Structure
```
lovepod/
├── lovepodApp.swift              # App entry point, handles Spotify auth callback and lifecycle
├── AppState.swift                # Global state management (ObservableObject + Combine)
├── iPodLayout.swift              # Main layout container (screen area + wheel control area)
├── ContentView.swift             # App entry point view
├── DesignSystem.swift            # Design system (colors, fonts, spacing, etc.)
├── HapticManager.swift           # Haptic feedback manager
├── Views/                        # Page view components
├── Spotify Services/             # Spotify integration service layer
└── Assets.xcassets/             # App assets
```

### State Management Architecture
- **AppState**: Singleton pattern for global state management, using `@Published` properties and Combine for a reactive UI.
- **Navigation**: Enum-based page state management (`NavigationPage`).
- **Spotify Integration**: Multi-service collaboration mode (iOS SDK + Web API dual authorization).

### Key Design Patterns     
- **MVVM**: View + ViewModel (AppState) + Model (Spotify Models)
- **Dependency Injection**: Services are injected via `@EnvironmentObject`.
- **Observer Pattern**: Uses the Combine framework for state subscription.

## Spotify Integration

### Prerequisites
- Spotify iOS SDK 3.0.0 is integrated in the `Frameworks/` directory.
- Client ID needs to be configured in `SpotifyService.swift`.
- Bundle URL Scheme: `lovepod://`

### Development Notes
- The Spotify SDK only works on a real device.
- The official Spotify app must be installed.
- Web API calls require a valid access token.

## Important Notes
- Use the iPhone 16 simulator for development.
- Spotify features must be tested on a real device.
- Adhere to the Header Comments specification.
- Prioritize using existing components to avoid reinventing the wheel.
- Maintain the integrity of the AppState singleton pattern.
