import Foundation
import CoreLocation

/// Utility for splitting a contiguous list of `PhotoPoint`s into discrete `RouteSegment`s.
/// Segments are broken when time or distance gaps exceed the configured thresholds.
struct RouteSegmenter {
    
    /// Segments an array of photo points.
    /// - Parameters:
    ///   - points: The chronological array of `PhotoPoint`s.
    ///   - settings: The `SegmentationSettings` defining gap thresholds.
    /// - Returns: An array of `RouteSegment`s.
    static func segment(points: [PhotoPoint], settings: SegmentationSettings) -> [RouteSegment] {
        guard !points.isEmpty else { return [] }
        
        var segments: [RouteSegment] = []
        var currentSegmentPoints: [PhotoPoint] = [points[0]]
        
        for i in 1..<points.count {
            let prev = points[i-1]
            let curr = points[i]
            
            let timeGap = curr.creationDate.timeIntervalSince(prev.creationDate)
            
            let prevLoc = CLLocation(latitude: prev.coordinate.latitude, longitude: prev.coordinate.longitude)
            let currLoc = CLLocation(latitude: curr.coordinate.latitude, longitude: curr.coordinate.longitude)
            let distanceGap = currLoc.distance(from: prevLoc)
            
            let timeGapThreshold = settings.maxTimeGapHours * 3600
            let distanceGapThreshold = settings.maxDistanceGapKilometers * 1000
            
            let shouldSplit = timeGap > timeGapThreshold || distanceGap > distanceGapThreshold
            
            if shouldSplit {
                segments.append(RouteSegment(points: currentSegmentPoints))
                currentSegmentPoints = [curr]
            } else {
                currentSegmentPoints.append(curr)
            }
        }
        
        if !currentSegmentPoints.isEmpty {
            segments.append(RouteSegment(points: currentSegmentPoints))
        }
        
        return segments
    }
}
