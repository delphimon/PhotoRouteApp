import Foundation
import CoreLocation

struct RouteSegmenter {
    static func segment(points: [PhotoPoint], settings: SegmentationSettings = .default) -> [RouteSegment] {
        guard !points.isEmpty else { return [] }
        
        if settings.mode == .continuous {
            return [RouteSegment(points: points)]
        }
        
        var segments: [RouteSegment] = []
        var currentSegmentPoints: [PhotoPoint] = [points[0]]
        
        for i in 1..<points.count {
            let prev = points[i-1]
            let curr = points[i]
            
            let timeDiff = curr.creationDate.timeIntervalSince(prev.creationDate)
            
            let loc1 = CLLocation(latitude: prev.latitude, longitude: prev.longitude)
            let loc2 = CLLocation(latitude: curr.latitude, longitude: curr.longitude)
            let distanceMeters = loc2.distance(from: loc1)
            let distanceKm = distanceMeters / 1000.0
            
            let hoursDiff = timeDiff / 3600.0
            let impliedSpeedKmh = (hoursDiff > 0) ? (distanceKm / hoursDiff) : 0.0
            
            var shouldSplit = false
            
            if settings.mode == .smart {
                // Smart heuristics
                let largeTimeGap = hoursDiff > 8.0 && distanceKm > 1.0
                let largeDistanceJump = distanceKm > 30.0
                let highSpeed = impliedSpeedKmh > 70.0 && distanceKm > 5.0
                
                if largeTimeGap || largeDistanceJump || highSpeed {
                    shouldSplit = true
                }
            } else if settings.mode == .custom {
                if hoursDiff > settings.maxTimeGapHours {
                    shouldSplit = true
                }
                if distanceKm > settings.maxDistanceGapKilometers {
                    shouldSplit = true
                }
                if impliedSpeedKmh > settings.maxSpeedKmh && distanceKm > 1.0 {
                    shouldSplit = true
                }
            }
            
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
