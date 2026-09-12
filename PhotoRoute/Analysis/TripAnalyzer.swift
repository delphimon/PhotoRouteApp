import Foundation
import Photos
import Combine

/// A MainActor observable class responsible for analyzing photo albums, extracting GPS data,
/// parsing GPX tracks, and generating a `TripAnalysis` for the UI to consume.
@MainActor
class TripAnalyzer: ObservableObject {
    /// The resulting analysis generated from the album and GPX track.
    @Published var analysis: TripAnalysis?
    /// Indicates whether the analyzer is currently processing data.
    @Published var isAnalyzing = false
    /// The number of photos that have been processed so far.
    @Published var analyzedCount = 0
    /// The total number of photos in the album.
    @Published var totalCount = 0
    /// Settings used for segmentation and exclusion logic.
    @Published var settings = SegmentationSettings() {
        didSet {
            recalculateSegments()
        }
    }
    
    private var rawPoints: [PhotoPoint] = []
    private var rawGPXPoints: [GPXTrackPoint]? = nil
    private var albumId: String = ""
    
    /// Analyzes a photo album, optionally integrating GPX track points for missing location interpolation.
    func analyze(album: PhotoAlbum, gpxTrackPoints: [GPXTrackPoint]? = nil) async {
        isAnalyzing = true
        self.albumId = album.id
        self.rawGPXPoints = gpxTrackPoints
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        var fetchResult: PHFetchResult<PHAsset>? = nil
        
        if let collection = album.collection {
            fetchResult = PHAsset.fetchAssets(in: collection, options: fetchOptions)
        } else {
            let collections = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [album.id], options: nil)
            if let collection = collections.firstObject {
                fetchResult = PHAsset.fetchAssets(in: collection, options: fetchOptions)
            }
        }
        
        guard let fetchResult = fetchResult else {
            isAnalyzing = false
            return
        }
        
        self.totalCount = fetchResult.count
        self.analyzedCount = 0
        
        let points = await processAssets(fetchResult, gpxPoints: gpxTrackPoints)
        self.rawPoints = points
        
        await recalculateSegmentsAsync()
    }
    
    func recalculateSegments() {
        Task {
            await recalculateSegmentsAsync()
        }
    }
    
    private func recalculateSegmentsAsync() async {
        let activePoints = rawPoints.filter { 
            !self.settings.excludedIds.contains($0.id) && 
            ($0.coordinate.latitude != 0 || $0.coordinate.longitude != 0) 
        }
        let settings = self.settings
        let gpx = self.rawGPXPoints
        
        // Run heavy calculations in background
        let result = await Task.detached { () -> (segments: [RouteSegment], simplified: [GPXTrackPoint]?) in
            let segments = RouteSegmenter.segment(points: activePoints, settings: settings)
            
            // Limit points passed to simplifier if it's too large, or increase tolerance
            var tolerance = 5.0
            if let count = gpx?.count, count > 10000 {
                tolerance = 15.0 // Increase tolerance for massive tracks to speed up simplification
            }
            let simplified = gpx.map { RouteSimplifier.simplify($0, toleranceMeters: tolerance) }
            
            return (segments, simplified)
        }.value
        
        self.analysis = TripAnalysis(
            albumId: self.albumId,
            points: activePoints,
            segments: result.segments,
            gpxTrackPoints: rawGPXPoints,
            simplifiedGpxTrackPoints: result.simplified
        )
        self.isAnalyzing = false
    }
    
    func applyGPXTrack(_ trackPoints: [GPXTrackPoint]) async {
        self.rawGPXPoints = trackPoints
        let interpolator = RouteInterpolator(trackPoints: trackPoints)
        
        let updated = await Task.detached { [rawPoints] in
            var updatedPoints = rawPoints
            for i in 0..<updatedPoints.count {
                if updatedPoints[i].altitude == nil || updatedPoints[i].coordinate.latitude == 0 {
                    if let loc = interpolator.interpolateLocation(for: updatedPoints[i].creationDate) {
                        let old = updatedPoints[i]
                        updatedPoints[i] = PhotoPoint(
                            id: old.id,
                            coordinate: loc.coordinate,
                            creationDate: old.creationDate,
                            altitude: loc.altitude,
                            filename: old.filename,
                            horizontalAccuracy: old.horizontalAccuracy,
                            isVideo: old.isVideo
                        )
                    }
                }
            }
            return updatedPoints
        }.value
        
        self.rawPoints = updated
        await recalculateSegmentsAsync()
    }
    
    private func processAssets(_ fetchResult: PHFetchResult<PHAsset>, gpxPoints: [GPXTrackPoint]?) async -> [PhotoPoint] {
        return await Task.detached {
            var points: [PhotoPoint] = []
            let interpolator = gpxPoints.map { RouteInterpolator(trackPoints: $0) }
            
            for i in 0..<fetchResult.count {
                if i % 50 == 0 {
                    await MainActor.run {
                        self.analyzedCount = i
                    }
                }
                
                let asset = fetchResult.object(at: i)
                guard let creationDate = asset.creationDate else { continue }
                
                var coord: CLLocationCoordinate2D? = asset.location?.coordinate
                var alt: Double? = asset.location?.altitude
                
                if coord == nil || (coord!.latitude == 0 && coord!.longitude == 0) {
                    if let loc = interpolator?.interpolateLocation(for: creationDate) {
                        coord = loc.coordinate
                        alt = loc.altitude
                    } else {
                        // Keep the photo in rawPoints with a dummy coordinate so it can be interpolated later
                        // if a GPX track is loaded. We will filter out (0,0) during segmentation.
                        coord = CLLocationCoordinate2D(latitude: 0, longitude: 0)
                    }
                }
                
                if let validCoord = coord {
                    points.append(PhotoPoint(
                        id: asset.localIdentifier,
                        coordinate: validCoord,
                        creationDate: creationDate,
                        altitude: alt,
                        filename: nil,
                        horizontalAccuracy: asset.location?.horizontalAccuracy,
                        isVideo: asset.mediaType == .video
                    ))
                }
            }
            
            await MainActor.run {
                self.analyzedCount = fetchResult.count
            }
            return points
        }.value
    }
}
