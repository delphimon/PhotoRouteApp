# PhotoRoute: Technical Architecture

This document describes the internal structure, algorithms, and frameworks used in PhotoRoute.

## 1. App Architecture & State Management
PhotoRoute is a native iOS application built using **SwiftUI** and **SwiftData**. 

- **Data Models**: Simple Swift structs (`PhotoPoint`, `RouteSegment`, `GPXTrackPoint`) are used for immutability and thread safety during heavy map analysis. 
- **Persistence**: `SavedTrip` is a `@Model` (SwiftData) class. It persists the album ID, trip title, imported GPX XML data as a `Data` blob, and a list of excluded asset IDs.
- **Concurrency**: Heavy operations like metadata extraction and route simplification are pushed to `Task.detached` to prevent blocking the Main Actor (UI Thread). 

## 2. TripAnalyzer Pipeline
The core engine of the app is `TripAnalyzer.swift`. When an album is loaded, it executes the following pipeline:

1. **Asset Fetching**: Fetches all `PHAsset` objects for the album using PhotoKit.
2. **Metadata Extraction**: Iterates through the assets to extract `creationDate` and `location`. 
   - If a GPX track is provided, photos *without* GPS coordinates are assigned a temporary `(0,0)` coordinate so they are not dropped from memory.
3. **Interpolation**: If a GPX track is present, `RouteInterpolator` performs binary searches against the GPX track points to interpolate exact coordinates and altitude for photos lacking metadata based on their timestamp.
4. **Segmentation**: `RouteSegmenter` breaks the chronological list of photos into discrete `RouteSegment` blocks. By default, gaps > 4 hours or distances > 50km split the route into a new segment (to handle flights or long drives).
5. **Simplification**: High-density GPX tracks are aggressively simplified using the Ramer-Douglas-Peucker algorithm (`RouteSimplifier.swift`). This prevents SwiftUI's `MapPolyline` from locking up the UI thread when rendering multiday tracks with >10,000 points.

## 3. Map Rendering & Dynamic Clustering
SwiftUI's iOS 17 `Map` API does not yet support native annotation clustering. To maintain 60FPS when rendering thousands of photos, `MapScreenView` implements a dynamic step-function grid clustering algorithm.

As the `cameraDistance` (distance of the camera from the ground) changes, the `gridSize` scales logarithmically:
```swift
if cameraDistance < 2000 { gridSize = 0.00005 }      // ~5m
else if cameraDistance < 10000 { gridSize = 0.0002 } // ~20m
...
```
The view groups photos into dictionary keys based on `Int(latitude / gridSize)` and `Int(longitude / gridSize)`. This ensures that clusters remain completely stationary while panning (preventing visual jitter) and naturally break apart into individual thumbnails as the user zooms in.

## 4. Scrubber & Time Interpolation
The timeline slider is bound to a `scrubTime` Double representing seconds since 1970. 
- If a GPX track is loaded, the scrubber interpolates a location precisely along the GPX path for that timestamp.
- If no GPX track is loaded, a fallback "Virtual GPX Track" is constructed by mapping the raw photo coordinates and timestamps, allowing the scrubber to function identically.

## 5. Security & Privacy
The app requires `NSPhotoLibraryUsageDescription`. It operates entirely on-device and does not require an active network connection or third-party servers. Photo thumbnails are loaded aggressively downsampled via `PHImageManager` using the `.fastFormat` delivery mode to ensure minimal memory overhead.
