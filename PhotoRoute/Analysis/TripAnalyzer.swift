import Foundation
import Photos
import CoreLocation

@MainActor
class TripAnalyzer: ObservableObject {
    @Published var isAnalyzing = false
    @Published var totalCount = 0
    @Published var analyzedCount = 0
    @Published var analysis: TripAnalysis?
    @Published var settings: SegmentationSettings = .default {
        didSet {
            recalculateSegments()
        }
    }
    
    private var allExtractedPoints: [PhotoPoint] = []
    
    func analyze(album: PhotoAlbum) async {
        isAnalyzing = true
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        let assets = PHAsset.fetchAssets(in: album.collection, options: fetchOptions)
        
        totalCount = assets.count
        analyzedCount = 0
        
        let extractedPoints = await Task.detached(priority: .userInitiated) {
            var localPoints: [PhotoPoint] = []
            for i in 0..<assets.count {
                let asset = assets.object(at: i)
                if let location = asset.location, let creationDate = asset.creationDate {
                    // Try to get filename quickly
                    var filename: String? = nil
                    if let resource = PHAssetResource.assetResources(for: asset).first {
                        filename = resource.originalFilename
                    }
                    
                    let point = PhotoPoint(
                        id: asset.localIdentifier,
                        creationDate: creationDate,
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude,
                        altitude: location.altitude,
                        horizontalAccuracy: location.horizontalAccuracy,
                        filename: filename,
                        isVideo: asset.mediaType == .video
                    )
                    localPoints.append(point)
                }
            }
            return localPoints
        }.value
        
        analyzedCount = assets.count
        allExtractedPoints = extractedPoints
        recalculateSegments()
        
        isAnalyzing = false
    }
    
    private func recalculateSegments() {
        let segments = RouteSegmenter.segment(points: allExtractedPoints, settings: settings)
        
        var totalDistance = 0.0
        var duration: TimeInterval = 0
        
        if let first = allExtractedPoints.first, let last = allExtractedPoints.last {
            duration = last.creationDate.timeIntervalSince(first.creationDate)
            
            for i in 1..<allExtractedPoints.count {
                let prev = allExtractedPoints[i-1]
                let curr = allExtractedPoints[i]
                let loc1 = CLLocation(latitude: prev.latitude, longitude: prev.longitude)
                let loc2 = CLLocation(latitude: curr.latitude, longitude: curr.longitude)
                totalDistance += loc2.distance(from: loc1)
            }
        }
        
        analysis = TripAnalysis(
            points: allExtractedPoints,
            segments: segments,
            validPointCount: allExtractedPoints.count,
            totalDistanceMeters: totalDistance,
            duration: duration
        )
    }
}
