# PhotoRoute

PhotoRoute reconstructs an approximate geographic track of a trip using the timestamps and GPS locations already stored on photos in your Apple Photos library. It does not export, download, or copy the original high-resolution photos, working entirely off metadata to preserve storage and speed.

## Architecture Overview

The app is built using Swift and SwiftUI, following an MVVM and clean architecture style.

- **Models**: Simple structures representing `PhotoPoint`s (an asset's geographic and temporal data), `RouteSegment`s, and `SegmentationSettings`.
- **Services**: `PhotoLibraryService` handles PhotoKit interactions, fetching albums and their localized titles safely.
- **Analysis**: `TripAnalyzer` fetches `PHAsset`s and extracts metadata efficiently in the background. `RouteSegmenter` determines where gaps exist and breaks continuous lines based on time, distance, or speed heuristics.
- **Views**: Main interfaces utilizing modern SwiftUI MapKit integration (`MapPolyline`).
- **Export**: Generates valid GPX 1.1 XML and RFC 4180 CSV entirely from metadata coordinates.

## Requirements

- **Xcode Version**: Xcode 16.0 or later (for iOS 18 APIs).
- **Minimum iOS Version**: iOS 18.0

## Build & Run Instructions

1. Open `PhotoRoute.xcodeproj` in Xcode.
2. Select your development team in the project target settings if you plan to install on a physical device.
3. Select an iOS Simulator or your connected iPhone.
4. Hit **Run** (`Cmd + R`).

## Photos Permission

PhotoRoute requires `.readWrite` (or limited) access to your Photo Library to discover your albums, read the `creationDate` and `location` of `PHAsset`s, and fetch small thumbnails. 

**Privacy Statement**: PhotoRoute processes everything strictly locally on your device. It never uploads your photos, GPS coordinates, or routes. The app uses the `NSPhotoLibraryUsageDescription` to explicitly inform you of this behavior.

## Known PhotoKit Limitations

- If you select **Limited Access**, only the specifically selected photos will appear in PhotoRoute, leading to an incomplete or overly segmented route. 
- Original filenames might not be available immediately for photos in iCloud without downloading them. In these cases, the filename column is left blank or replaced with a generic fallback in the export, instead of forcing a full image download.

## Route Segmentation

PhotoRoute does not invent paths between points. It connects points with straight, geodesic lines.
You can configure segmentation in the **Settings (gear icon)**:
- **Continuous**: Connects all photos regardless of gaps.
- **Smart**: The default. Intelligently splits the route if there are multi-hour gaps coupled with significant distance, or suspiciously high implied travel speeds.
- **Custom**: Manually override the maximum allowable time gap, distance gap, and implied speed limits.

## GPX and CSV Export

The GPX export includes track segments (`<trkseg>`) and track points (`<trkpt>`) representing your path, optionally alongside photo waypoints. The CSV export contains detailed point-by-point tabular data including distance and speed from the previous point. All files use UTC time and standard escaping.

## Testing

To run the unit tests, select the `PhotoRouteTests` scheme in Xcode and press `Cmd + U`. The test suite verifies the segmentation logic against various mock photo points (large gaps, dense tracking, missing altitude).
