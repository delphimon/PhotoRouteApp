# PhotoRoute: Functional Specification

## Product Overview
PhotoRoute solves a common problem for outdoor enthusiasts and travelers: reconstructing the path of a trip without having recorded a continuous GPS track. It leverages the EXIF metadata (timestamps and coordinates) embedded in photos taken on an iPhone or digital camera. 

## Core Workflows

### 1. Album Selection
Upon granting Photo Library access, the user is presented with a list of all their Photo Albums, including user-created albums and smart albums (Favorites, Recents). Selecting an album kicks off the analysis.

### 2. Analysis & Map Visualization
The app parses the photos in the background. It extracts locations and timestamps, sorts them chronologically, and attempts to segment them into logical routes. 
- **Map Rendering**: The route is drawn as a blue polyline connecting the photos.
- **Photo Waypoints**: Photos are displayed as thumbnail markers on the map. To prevent visual clutter and lag, thumbnails are dynamically clustered into numbered badges as the user zooms out.
- **Scrubbing**: A timeline slider at the bottom of the map allows the user to scrub forward and backward in time. A yellow "playhead" marker moves along the route, interpolating its position exactly.

### 3. Merging External GPX Tracks
Often, users have a rough GPS track from a Garmin or Apple Watch, but it doesn't contain their high-quality DSLR photos (which might lack GPS). 
- The user can tap "Load GPX Tracker" and select an XML `.gpx` file via the iOS Document Picker.
- The app parses the GPX track, drawing it on the map instead of the jagged point-to-point lines.
- **Crucially**, any photo in the album that *lacked* GPS metadata is given an estimated location by interpolating its timestamp against the GPX track points.

### 4. Photo Inspection & Exclusion
Tapping a photo thumbnail (or cluster) on the map opens a bottom sheet with detailed diagnostics (exact timestamp, altitude, latitude/longitude). If a photo has a wildly inaccurate GPS reading causing a spike in the route, the user can toggle "Exclude from route" to recalculate the path without it.

### 5. Exporting
Once the user is satisfied with the reconstructed route and interpolated photo locations, they can export the data to share or open in dedicated mapping software (like Gaia GPS or CalTopo):
- **GPX Export**: Creates a standard `.gpx` file containing the simplified track `<trk>` and the photo locations as waypoints `<wpt>`.
- **CSV Export**: Creates a spreadsheet of the photo metadata (Filename, Date, Latitude, Longitude, Altitude, IsInterpolated).

### 6. Persistence
The user can save a trip. Saved trips appear in the sidebar/root menu and remember the GPX track data and user-excluded photos, allowing them to instantly view the trip later without re-importing the GPX file.
