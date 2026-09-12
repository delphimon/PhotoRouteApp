import Foundation

/// Represents a continuous sequence of photo points forming a track segment.
/// Segments are split when there are significant temporal or spatial gaps.
struct RouteSegment: Identifiable, Sendable {
    /// Unique identifier for the segment.
    let id = UUID()
    /// The sequence of points making up this segment.
    let points: [PhotoPoint]
    
    /// The total distance of this segment in meters.
    var distanceMeters: Double {
        guard points.count > 1 else { return 0 }
        var dist = 0.0
        for i in 0..<(points.count - 1) {
            let p1 = points[i].coordinate
            let p2 = points[i+1].coordinate
            let R = 6371e3
            let phi1 = p1.latitude * .pi / 180
            let phi2 = p2.latitude * .pi / 180
            let dPhi = (p2.latitude - p1.latitude) * .pi / 180
            let dLambda = (p2.longitude - p1.longitude) * .pi / 180
            
            let a = sin(dPhi/2) * sin(dPhi/2) +
                    cos(phi1) * cos(phi2) *
                    sin(dLambda/2) * sin(dLambda/2)
            let c = 2 * atan2(sqrt(a), sqrt(1-a))
            dist += R * c
        }
        return dist
    }
}
