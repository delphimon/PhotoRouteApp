import Foundation
import CoreLocation

/// Utility for simplifying a geographic path using the Ramer-Douglas-Peucker algorithm.
struct RouteSimplifier {
    
    /// Simplifies an array of GPX track points.
    /// - Parameters:
    ///   - points: The raw GPX track points.
    ///   - toleranceMeters: The maximum perpendicular distance in meters a point can deviate from the simplified line to be considered redundant.
    /// - Returns: A simplified array of GPX track points.
    static func simplify(_ points: [GPXTrackPoint], toleranceMeters: Double) -> [GPXTrackPoint] {
        guard points.count > 2 else { return points }
        
        var maxDistance: Double = 0
        var index = 0
        
        let start = points.first!.coordinate
        let end = points.last!.coordinate
        
        for i in 1..<(points.count - 1) {
            let dist = perpendicularDistance(point: points[i].coordinate, start: start, end: end)
            if dist > maxDistance {
                maxDistance = dist
                index = i
            }
        }
        
        if maxDistance > toleranceMeters {
            let left = simplify(Array(points[0...index]), toleranceMeters: toleranceMeters)
            let right = simplify(Array(points[index...(points.count - 1)]), toleranceMeters: toleranceMeters)
            
            var result = left
            result.removeLast()
            result.append(contentsOf: right)
            return result
        } else {
            return [points.first!, points.last!]
        }
    }
    
    /// Calculates the perpendicular distance in meters from a point to a line segment defined by start and end points.
    private static func perpendicularDistance(point: CLLocationCoordinate2D, start: CLLocationCoordinate2D, end: CLLocationCoordinate2D) -> Double {
        // Convert to ECEF (Earth-Centered, Earth-Fixed) or simply use a quick cross-track distance formula
        // For simplicity and speed over short distances, we can use an equirectangular approximation
        let R = 6371000.0 // Earth radius in meters
        
        let lat1 = start.latitude * .pi / 180
        let lon1 = start.longitude * .pi / 180
        let lat2 = end.latitude * .pi / 180
        let lon2 = end.longitude * .pi / 180
        let lat3 = point.latitude * .pi / 180
        let lon3 = point.longitude * .pi / 180
        
        // Haversine distance from start to end
        let dLon12 = lon2 - lon1
        let dLat12 = lat2 - lat1
        let a = sin(dLat12/2)*sin(dLat12/2) + cos(lat1)*cos(lat2)*sin(dLon12/2)*sin(dLon12/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        let distanceStartEnd = R * c
        
        if distanceStartEnd == 0 {
            // Start and end are the same point
            let dLon13 = lon3 - lon1
            let dLat13 = lat3 - lat1
            let a3 = sin(dLat13/2)*sin(dLat13/2) + cos(lat1)*cos(lat3)*sin(dLon13/2)*sin(dLon13/2)
            let c3 = 2 * atan2(sqrt(a3), sqrt(1-a3))
            return R * c3
        }
        
        // Cross-track distance
        // dxt = asin(sin(d13/R)*sin(θ13-θ12)) * R
        // where d13 is distance from start to point 3, θ is bearing
        
        // Let's compute bearings
        let y13 = sin(lon3 - lon1) * cos(lat3)
        let x13 = cos(lat1) * sin(lat3) - sin(lat1) * cos(lat3) * cos(lon3 - lon1)
        let bearing13 = atan2(y13, x13)
        
        let y12 = sin(lon2 - lon1) * cos(lat2)
        let x12 = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(lon2 - lon1)
        let bearing12 = atan2(y12, x12)
        
        let dLon13 = lon3 - lon1
        let dLat13 = lat3 - lat1
        let a13 = sin(dLat13/2)*sin(dLat13/2) + cos(lat1)*cos(lat3)*sin(dLon13/2)*sin(dLon13/2)
        let d13 = 2 * atan2(sqrt(a13), sqrt(1-a13)) // angular distance
        
        let dxt = asin(sin(d13) * sin(bearing13 - bearing12))
        return abs(dxt * R)
    }
}
