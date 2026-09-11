import Foundation

struct TripAnalysis: Sendable {
    let points: [PhotoPoint]
    let segments: [RouteSegment]
    let validPointCount: Int
    let totalDistanceMeters: Double
    let duration: TimeInterval
    
    var totalDistanceMiles: Double {
        totalDistanceMeters * 0.000621371
    }
    
    var durationString: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? ""
    }
}
