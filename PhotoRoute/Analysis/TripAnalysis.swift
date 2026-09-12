import Foundation
import CoreLocation

struct TripAnalysis {
    let albumId: String
    var points: [PhotoPoint]
    var segments: [RouteSegment]
    var gpxTrackPoints: [GPXTrackPoint]?
    var simplifiedGpxTrackPoints: [GPXTrackPoint]?
    var timelineInterpolator: RouteInterpolator?
    
    init(albumId: String, points: [PhotoPoint], segments: [RouteSegment], gpxTrackPoints: [GPXTrackPoint]?, simplifiedGpxTrackPoints: [GPXTrackPoint]?) {
        self.albumId = albumId
        self.points = points
        self.segments = segments
        self.gpxTrackPoints = gpxTrackPoints
        self.simplifiedGpxTrackPoints = simplifiedGpxTrackPoints
        
        if let gpx = gpxTrackPoints, !gpx.isEmpty {
            self.timelineInterpolator = RouteInterpolator(trackPoints: gpx)
        } else if !points.isEmpty {
            let pts = points.map { GPXTrackPoint(coordinate: $0.coordinate, altitude: $0.altitude, time: $0.creationDate) }
            self.timelineInterpolator = RouteInterpolator(trackPoints: pts)
        } else {
            self.timelineInterpolator = nil
        }
    }
    
    var validPointCount: Int {
        points.count
    }
    
    var totalDistanceMeters: Double {
        segments.reduce(0) { $0 + $1.distanceMeters }
    }
    
    var totalDistanceMiles: Double {
        totalDistanceMeters / 1609.34
    }
    
    var durationString: String {
        guard let first = points.first, let last = points.last else { return "0s" }
        let interval = last.creationDate.timeIntervalSince(first.creationDate)
        
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: interval) ?? "0s"
    }
}
