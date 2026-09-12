# PhotoRoute: Detailed Functional Requirements Specification

This document serves as a comprehensive functional specification for the PhotoRoute application. It outlines the exact requirements and behaviors necessary to recreate this application from scratch or port it to another platform (e.g., Android, macOS, Web).

## 1. Product Objective
PhotoRoute reconstructs an approximate geographic track of a trip using the timestamps and GPS locations already stored on photos in the user's native photo library. It allows users to visualize their journey, merge incomplete photo metadata with actual GPS tracker logs, and export the synthesized route.

## 2. Core Principles & Constraints
1. **Privacy-First (On-Device Processing):** No photo data, metadata, or location data may be transmitted to any third-party server. All extraction, parsing, and route calculation must happen locally on the device.
2. **Read-Only Photo Access:** The application must not modify, duplicate, or delete the original photos in the user's library.
3. **Performance at Scale:** The app must remain responsive (targeting 60 FPS for map interactions) even when processing albums with thousands of photos spanning hundreds of miles.

## 3. Detailed Functional Requirements

### 3.1. Data Ingestion (Photo Library)
- **FR 3.1.1 Authorization:** The app must prompt the user for appropriate read access to the native photo library.
- **FR 3.1.2 Album Listing:** The app must list all available user albums (including smart albums like "Recents" or "Favorites") with their respective photo counts.
- **FR 3.1.3 Metadata Extraction:** Upon selecting an album, the app must parse all photos to extract `creationDate`, `latitude`, `longitude`, and `altitude`. 
- **FR 3.1.4 Missing Data Handling:** Photos lacking GPS metadata must still be ingested and held in memory if they possess a valid `creationDate`, so they can be interpolated later if an external track is provided.

### 3.2. Route Processing Pipeline
- **FR 3.2.1 Chronological Sorting:** All ingested photos must be sorted strictly by `creationDate`.
- **FR 3.2.2 Segmentation:** The route must be broken into logical "segments" to prevent drawing straight lines across the globe (e.g., when a user flies home). 
  - *Default Rule:* Split the route if the time gap between consecutive photos exceeds 4 hours, or the physical distance exceeds 50 kilometers.
- **FR 3.2.3 Track Simplification:** To prevent map rendering engines from dropping frames, dense polyline tracks must be aggressively simplified using the Ramer-Douglas-Peucker algorithm or equivalent, ensuring visual fidelity without rendering redundant vertices.

### 3.3. External GPX Integration
- **FR 3.3.1 GPX Import:** The user must be able to import a standard XML `.gpx` file from the local file system.
- **FR 3.3.2 Track Replacement:** If a GPX track is imported, the map must draw the route using the GPX track's `<trkpt>` nodes rather than drawing straight lines between photo waypoints.
- **FR 3.3.3 Location Interpolation:** When a GPX track is loaded, the app must cross-reference the timestamps of the photos. For any photo lacking GPS metadata, the app must calculate an estimated `latitude`, `longitude`, and `altitude` by linearly interpolating between the two closest GPX track points in time.

### 3.4. Map Visualization & UI
- **FR 3.4.1 Map Interface:** The app must display a full-screen interactive map with toggles for Standard, Satellite, and Hybrid layers, as well as a 3D terrain toggle.
- **FR 3.4.2 Dynamic Clustering:** The app must display photos on the map. To prevent visual clutter and UI lag:
  - The map must group nearby photos into numbered cluster badges (e.g., a circle saying "42").
  - The clustering algorithm must be grid-based and dynamically scale its grid size relative to the camera's zoom level / altitude.
  - As the user zooms in, clusters must break apart. When a cluster contains only 1 photo, it should display a square thumbnail of the photo.
- **FR 3.4.3 Thumbnail Loading:** Thumbnails must be loaded asynchronously and heavily downsampled to minimize memory footprint.

### 3.5. Timeline Scrubber
- **FR 3.5.1 Scrubbing Interface:** A slider must be present at the bottom of the map representing the span of time between the first and last photo in the trip.
- **FR 3.5.2 Playhead:** Scrubbing the slider must move a distinct "playhead" marker along the map route, interpolating its physical location based on the selected time.
- **FR 3.5.3 Synchronization:** Tapping a photo thumbnail on the map must instantly snap the timeline scrubber to that photo's exact timestamp.
- **FR 3.5.4 Persistence:** Releasing the scrubber must leave the playhead visible at the chosen time, acting as a persistent marker rather than resetting to the beginning.

### 3.6. Photo Inspection & Exclusion
- **FR 3.6.1 Detail View:** Tapping a photo must reveal a detail sheet showing the image, timestamp, coordinates, and altitude.
- **FR 3.6.2 Exclusion Toggle:** The user must be able to toggle a photo as "Excluded".
- **FR 3.6.3 Recalculation:** Excluding a photo must immediately remove it from the map and trigger a recalculation of the route segments, ensuring that an anomalous GPS reading (e.g., a "Null Island" 0,0 glitch) doesn't ruin the route.

### 3.7. Persistence
- **FR 3.7.1 Local Saving:** The user must be able to save a trip to a local database.
- **FR 3.7.2 Saved State:** A saved trip must retain the Album Identifier, the Trip Title, the binary blob of any imported GPX XML data, and the list of user-excluded photo identifiers.
- **FR 3.7.3 Restoration:** Launching the app must list saved trips. Tapping a saved trip must restore it instantly without requiring the user to re-import the GPX file or re-exclude anomalous photos.

### 3.8. Exporting
- **FR 3.8.1 Share Sheet:** The app must use the native OS share sheet to export generated files.
- **FR 3.8.2 GPX Export:** The app must generate a standard `.gpx` file containing:
  - `<trk>`: The continuous route points.
  - `<wpt>`: Each photo's coordinate and timestamp, including photos whose locations were successfully interpolated.
- **FR 3.8.3 CSV Export:** The app must generate a `.csv` file with the headers: `Filename, Date, Latitude, Longitude, Altitude, IsInterpolated`.
