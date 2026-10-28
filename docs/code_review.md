# PhotoRoute: Implementation Review & Analysis

This review analyzes the current PhotoRoute codebase against the newly finalized Functional Requirements and Technical Specifications. 

## 1. Critical Violations of Requirements (Must Fix)

### Missing Filename in Exports (FR 3.8.3)
**Analysis**: The functional specification explicitly requires the generated CSV to contain the headers: `Filename, Date, Latitude, Longitude, Altitude, IsInterpolated`. However, in `TripAnalyzer.swift`, the `PhotoPoint` struct is currently instantiated with `filename: nil` for every photo because `PHAsset` does not expose the filename as a top-level property.
**Fix**: Update `TripAnalyzer.processAssets` to fetch the filename using `PHAssetResource.assetResources(for: asset).first?.originalFilename`. Since `assetResources` can be slightly slower, this must remain on the background `Task.detached` to prevent UI hangs.

## 2. Performance & Stability Enhancements

### Synchronous Export Generation UI Freeze
**Analysis**: In `ExportView.swift`, `GPXExporter.generateGPX(...)` and `CSVExporter.generateCSV(...)` are called directly inside the view's `body` property. Because these functions loop over potentially thousands of points and concatenate multi-megabyte strings, doing this synchronously blocks the Main Thread. Worse, because it's inside `body`, it runs *every time* the user toggles a settings switch, causing noticeable UI freezing.
**Fix**: Refactor `ExportView`. Add an asynchronous "Prepare Export" button that runs the generation in a background `Task`. Once the file is written to a temporary URL in the app's cache directory, expose the native `ShareLink` using that `URL`.

### Clustering Overhead During Scrubbing
**Analysis**: In `MapScreenView.swift`, the `dynamicClusters` property computes the entire clustered grid layout (looping over all `points`). Because the timeline slider updates the `@State var scrubTime` variable 60 times a second while being dragged, the entire view body—including the `dynamicClusters` loop—is re-evaluated 60 times a second. This is an enormous CPU waste and battery drain.
**Fix**: Break the dependency loop. The grid clustering should only recalculate when `cameraDistance` crosses one of the step thresholds. This logic should be moved into a `.onChange(of: cameraDistance)` modifier (or into `TripAnalyzer`), storing the clusters in a dedicated `@State` array so scrubbing the timeline does not recompute the map grid.

### Main Thread Blocking in Library Service
**Analysis**: `PhotoLibraryService.fetchAlbums()` is annotated with `@MainActor`. It iterates over all user and smart albums and calls `PHAsset.fetchAssets(in: collection, ...).count`. On devices with massive iCloud Photo Libraries (100k+ photos across dozens of smart albums), these synchronous SQLite queries will cause a noticeable stutter when opening the app.
**Fix**: Offload the `enumerateObjects` and asset counting loops into a detached Task, then `await MainActor.run` to publish the sorted array back to the UI.

## 3. Structural & UX Improvements

### Graceful Fallbacks for Deleted Albums
**Analysis**: `ContentView` launches a saved trip by injecting a dummy album with `assetCount: 0`. `TripAnalyzer` then tries to fetch it by ID. If the user deleted that album from the Photos app between sessions, `TripAnalyzer` will silently fail inside `analyze()`, leaving the user staring at an empty map with no feedback.
**Fix**: If `fetchResult` is nil or empty, `TripAnalyzer` should publish an error state (`analyzer.error = .albumNotFound`), and `MapScreenView` should display a "This album was deleted or modified" error overlay with an option to remove the saved trip.

### Thumbnail Image Request Cancellation
**Analysis**: `PhotoThumbnailView` fetches thumbnails using `PHImageManager`. If the user rapidly pans the map, hundreds of these views are created and destroyed. Currently, the `Task` initiates the fetch but there is no cancellation mechanism if the marker goes off-screen before the image returns.
**Fix**: Store the `PHImageRequestID` returned by `requestImage` and call `manager.cancelImageRequest(requestID)` inside an `.onDisappear` or `Task` cancellation block.

### View-ViewModel Separation
**Analysis**: `MapScreenView` has grown into a "God View". It handles the `fileImporter` side-effects for GPX loading, constructs the `timelineInterpolator`, manages map state, and computes clusters.
**Fix**: To ensure long-term maintainability, `timelineInterpolator` and cluster calculation should be strictly housed within `TripAnalyzer`. `MapScreenView` should act solely as a declarative shell that binds to the ViewModel's state.
