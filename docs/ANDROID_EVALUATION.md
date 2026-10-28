# PhotoRoute: Android Port Evaluation

Based on the `FUNCTIONAL_REQUIREMENTS.md` and current iOS architecture, here is an evaluation of the feasibility, architecture mappings, and potential roadblocks for creating a native Android version of PhotoRoute.

## 1. Feasibility Assessment
**Overall Verdict: Highly Feasible.**
There are no iOS-exclusive features or hardware-specific "magic" used in PhotoRoute. The app relies on reading standardized EXIF metadata, mathematically interpolating timestamps, and plotting coordinates. This entire pipeline maps perfectly to modern Android capabilities.

## 2. Architecture & Framework Mapping

| iOS (Current) | Android (Proposed) | Notes |
|---|---|---|
| **SwiftUI** | **Jetpack Compose** | Both are declarative UI frameworks. The UI layout, state management, and bottom sheets will translate 1-to-1. |
| **Swift Concurrency (`Task`)** | **Kotlin Coroutines** | `Task.detached` maps directly to `Dispatchers.Default` for the heavy data-processing pipeline. |
| **SwiftData** | **Room Database** | Room provides a robust SQLite abstraction for saving the Trip metadata and GPX blobs locally. |
| **PhotoKit (`PHAsset`)** | **MediaStore API** | Android groups photos by folders (`BUCKET_DISPLAY_NAME`), which maps to iOS "Albums". |
| **MapKit** | **Google Maps SDK or Mapbox** | Mapbox GL Android or Google Maps Utility Library is recommended. |
| **ShareLink** | **`Intent.ACTION_SEND`** | For exporting the GPX/CSV files to other apps. |

## 3. Potential Advantages on Android

1. **Native Clustering Capabilities**: On iOS 17/18, MapKit lacks a native way to cluster custom `Annotation` views, forcing us to write the custom grid-based `dynamicClusters` step-function. On Android, the Google Maps Utility Library has robust, out-of-the-box native clustering (`ClusterManager`) that is highly optimized in C++, which could actually improve map performance with fewer lines of code.
2. **File System Flexibility**: Android's Scoped Storage and Intent system makes it extremely easy to import a `.gpx` file from the Downloads folder or a connected Garmin device via USB-C without jumping through iOS `SecurityScopedResource` hoops.

## 4. Specific Roadblocks & Considerations

### A. The "Location Privacy" Permissions
Since Android 10 (API 29), just having permission to read photos (`READ_MEDIA_IMAGES`) **does not** give you access to the GPS coordinates embedded in those photos. The coordinates are redacted by the OS for privacy. 
- **Requirement**: You must request a specific, secondary permission called `ACCESS_MEDIA_LOCATION`. 
- **UX Impact**: The onboarding flow will require a two-step permission request, which must be clearly explained to the user so they don't deny it.

### B. Extracting EXIF Altitude and Filenames
On iOS, `PhotoKit` acts as an indexed database that quickly serves `location.altitude` without opening the actual image file.
On Android, the `MediaStore` indexes Latitude and Longitude, but **does not** index Altitude or original filenames as reliably.
- **Impact**: To get the altitude (necessary for a full GPX export), the Android app may need to open an `InputStream` for each photo and use `androidx.exifinterface.media.ExifInterface` to parse the `TAG_GPS_ALTITUDE`. 
- **Mitigation**: Opening 5,000 files via `ExifInterface` will be slower than iOS PhotoKit. The `TripAnalyzer` equivalent in Android will need to aggressively parallelize this using Kotlin Coroutines to maintain a reasonable loading speed.
