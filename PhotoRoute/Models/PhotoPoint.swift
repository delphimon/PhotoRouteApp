import Foundation
import CoreLocation

struct PhotoPoint: Identifiable, Sendable {
    let id: String
    let creationDate: Date
    let latitude: Double
    let longitude: Double
    let altitude: Double?
    let horizontalAccuracy: Double?
    let filename: String?
    let isVideo: Bool
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
