# SatellitesApp

A native Swift satellite tracking application for macOS, iOS, and tvOS. Tracks satellites in real-time using SGP4/SDP4 orbit propagation algorithms.

Currently configured to track **USA-247 (NROL-39)**, an NRO reconnaissance satellite launched in December 2013.

## Features

- Real-time satellite position tracking with 1-second updates
- Interactive map with satellite ground track visualization
- Geodetic coordinates (latitude, longitude, altitude)
- Topocentric position (azimuth, elevation, range) from observer location
- Orbital parameters display (period, inclination)
- Sliding info panel with mission patch and satellite details

## Requirements

- macOS 14.0+ / iOS 17.0+ / tvOS 17.0+
- Xcode 16.0+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

## Installation

### 1. Install XcodeGen

Using Homebrew:

```bash
brew install xcodegen
```

Or using Mint:

```bash
mint install yonaskolb/xcodegen
```

### 2. Clone the Repository

```bash
git clone <repository-url>
cd satellites-app
```

### 3. Generate Xcode Project

```bash
xcodegen generate
```

This creates `SatellitesApp.xcodeproj` from the `project.yml` configuration.

### 4. Open in Xcode

```bash
open SatellitesApp.xcodeproj
```

### 5. Build and Run

Select the `SatellitesApp` scheme and your target device/simulator, then build and run (Cmd+R).

## Project Structure

```
satellites-app/
├── project.yml                           # XcodeGen configuration
├── Sources/
│   ├── SatellitesApp/                    # Main application target
│   │   ├── App.swift                     # Entry point
│   │   ├── ViewModels/
│   │   │   └── SatelliteViewModel.swift  # Observable view model
│   │   ├── Views/
│   │   │   ├── ContentView.swift
│   │   │   ├── SatelliteTrackingView.swift
│   │   │   └── GroundTrackMapView.swift
│   │   └── Resources/
│   │       └── Assets.xcassets/          # Mission patch images
│   └── SatellitesKit/                    # Core tracking library
│       ├── SatelliteTracker.swift        # SGP4 propagation wrapper
│       ├── Models/
│       │   └── TrackedSatellite.swift    # Data models
│       └── Utilities/
│           ├── Constants.swift           # WGS-84 constants
│           └── CoordinateTransform.swift # Coordinate conversions
└── Tests/
    └── SatellitesKitTests/               # Unit tests
```

## Dependencies

- [SatelliteKit](https://github.com/gavineadie/SatelliteKit) - SGP4/SDP4 orbit propagation library

Dependencies are managed via Swift Package Manager and are resolved automatically when opening the Xcode project.

## Running Tests

```bash
xcodebuild test -scheme SatellitesKit -destination 'platform=macOS'
```

Or use Cmd+U in Xcode to run all tests.

## Configuration

### Changing the Tracked Satellite

Edit `Sources/SatellitesKit/SatelliteTracker.swift` to modify the TLE data in the `TrackedSatellite` extension. TLE data can be obtained from:

- [CelesTrak](https://celestrak.org/NORAD/elements/)
- [N2YO](https://www.n2yo.com/)
- [Space-Track](https://www.space-track.org/) (requires registration)

### Changing the Observer Location

The default observer location is San Francisco. Modify the `GroundStation.sanFrancisco` static property in `TrackedSatellite.swift` or call `viewModel.setObserver()` with custom coordinates.

## Architecture

The app follows a modular architecture:

- **SatellitesKit**: Platform-agnostic framework containing all orbital mechanics and tracking logic
- **SatellitesApp**: SwiftUI application layer with views and view models

This separation allows the core tracking functionality to be reused across different UI implementations.

## License

NROL-39 mission patch image is in the public domain (U.S. government work).

## References

- [SatelliteKit GitHub](https://github.com/gavineadie/SatelliteKit)
- [SGP4 Algorithm](https://celestrak.org/publications/AIAA/2006-6753/)
- [Two-Line Element Set Format](https://celestrak.org/NORAD/documentation/tle-fmt.php)
- [USA-247 on N2YO](https://www.n2yo.com/satellite/?s=39462)
