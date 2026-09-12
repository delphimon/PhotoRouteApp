# PhotoRoute

PhotoRoute is a native iOS application built with SwiftUI that reconstructs geographic tracks and routes using the timestamps and GPS locations stored on photos in a user's Apple Photos library.

It is designed for photographers, hikers, backpackers, and travelers who take many photos during a trip but don't want to run a continuous battery-draining GPS tracker. By analyzing the metadata in a selected photo album, PhotoRoute can reconstruct an approximate route, plot it on a map, and export it for use in other mapping software.

## Features

- **Album Integration**: Seamlessly read photos directly from the Apple Photos library using PhotoKit, without duplicating files.
- **Route Reconstruction**: Connect the dots between geotagged photos to draw a path.
- **Track Simplification**: Automatically simplifies routes using the Ramer-Douglas-Peucker algorithm to ensure buttery smooth performance even for trips spanning hundreds of miles and thousands of photos.
- **Dynamic Map Clustering**: Real-time map clustering that exponentially scales grid sizes based on camera distance to maintain 60 FPS performance when visualizing massive datasets.
- **Timeline Scrubber**: A timeline slider that allows the user to scrub back and forth through time to watch their route progress, syncing the playhead with tapped map photos.
- **GPX Track Import**: Merge an external `.gpx` tracker file into your photo album. The app will automatically interpolate locations for photos that are missing GPS metadata by cross-referencing their timestamps against the GPX track!
- **Exports**: Export your synthesized route as a `.gpx` file (including waypoints) or a `.csv` file.
- **Persistence**: Save trips locally to the device using SwiftData for offline reference.

## Requirements
- Xcode 16+
- iOS 18.0+

## Installation

1. Open `PhotoRoute.xcodeproj` in Xcode.
2. Select an iOS 18 Simulator or connect your iPhone.
3. Build and Run (`Cmd + R`).

## Documentation

For a deeper dive into how the app works, see the `docs` folder:
- [Functional Specification](docs/FUNCTIONAL_SPEC.md) - Explains user workflows and app behavior.
- [Technical Architecture](docs/TECHNICAL_ARCHITECTURE.md) - Details the data pipeline, algorithms, and SwiftUI view hierarchy.
