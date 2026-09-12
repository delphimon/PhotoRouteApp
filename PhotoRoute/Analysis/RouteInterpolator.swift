import Foundation
import CoreLocation

/// Represents a geographic location interpolated from a GPS track based on a timestamp.
struct InterpolatedLocation {
    let coordinate: CLLocationCoordinate2D
    let altitude: Double?
}

/// Utility for interpolating precise geographic coordinates for an arbitrary timestamp,
/// based on an existing chronological sequence of GPX track points.
struct RouteInterpolator {
    let trackPoints: [GPXTrackPoint]
    
    /// Initializes a new interpolator with the given track points.
    /// - Parameter trackPoints: A chronologically sorted array of `GPXTrackPoint`s.
    init(trackPoints: [GPXTrackPoint]) {
        self.trackPoints = trackPoints
    }
    
    /// Interpolates the location and altitude for a given date.
    /// Uses binary search to find the bounding track points and performs linear interpolation.
    /// - Parameter date: The timestamp to interpolate for.
    /// - Returns: An `InterpolatedLocation` if the date falls within the track bounds, otherwise `nil`.
    func interpolateLocation(for date: Date) -> InterpolatedLocation? {
        guard !trackPoints.isEmpty else { return nil }
        
        if date <= trackPoints.first!.time { return InterpolatedLocation(coordinate: trackPoints.first!.coordinate, altitude: trackPoints.first!.altitude) }
        if date >= trackPoints.last!.time { return InterpolatedLocation(coordinate: trackPoints.last!.coordinate, altitude: trackPoints.last!.altitude) }
        
        var low = 0
        var high = trackPoints.count - 1
        
        while low <= high {
            let mid = (low + high) / 2
            if trackPoints[mid].time == date {
                return InterpolatedLocation(coordinate: trackPoints[mid].coordinate, altitude: trackPoints[mid].altitude)
            } else if trackPoints[mid].time < date {
                low = mid + 1
            } else {
                high = mid - 1
            }
        }
        
        let p1 = trackPoints[high]
        let p2 = trackPoints[low]
        
        let totalDuration = p2.time.timeIntervalSince(p1.time)
        guard totalDuration > 0 else {
            return InterpolatedLocation(coordinate: p1.coordinate, altitude: p1.altitude)
        }
        
        let offset = date.timeIntervalSince(p1.time)
        let ratio = offset / totalDuration
        
        let lat = p1.coordinate.latitude + (p2.coordinate.latitude - p1.coordinate.latitude) * ratio
        let lon = p1.coordinate.longitude + (p2.coordinate.longitude - p1.coordinate.longitude) * ratio
        
        var alt: Double? = nil
        if let a1 = p1.altitude, let a2 = p2.altitude {
            alt = a1 + (a2 - a1) * ratio
        }
        
        return InterpolatedLocation(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon), altitude: alt)
    }
}
