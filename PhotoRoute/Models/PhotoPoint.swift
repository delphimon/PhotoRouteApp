import Foundation
import CoreLocation

/// Represents a single photo with geographic coordinates and a timestamp.
struct PhotoPoint: Identifiable, Sendable {
    /// The unique identifier of the photo asset.
    let id: String
    /// The geographic coordinate where the photo was taken.
    let coordinate: CLLocationCoordinate2D
    /// The date and time the photo was taken.
    let creationDate: Date
    /// The altitude in meters, if available.
    let altitude: Double?
    /// The filename of the original asset, if available.
    var filename: String? = nil
    /// Accuracy of the location.
    var horizontalAccuracy: Double? = nil
    /// Is the asset a video?
    var isVideo: Bool = false
    
    /// Convenience property for latitude.
    var latitude: Double { coordinate.latitude }
    /// Convenience property for longitude.
    var longitude: Double { coordinate.longitude }
}
