import Foundation
import SwiftData

/// A SwiftData model representing a user's saved trip configuration.
/// Stores references to the photo album, imported GPX track, and excluded photos.
@Model
final class SavedTrip {
    /// Unique identifier for the trip.
    var id: String
    /// The local identifier of the associated PhotoKit album.
    var albumId: String
    /// The user-defined title for the trip.
    var title: String
    /// The date the trip was saved.
    var savedDate: Date
    /// A set of photo identifiers that the user has explicitly excluded from the route.
    var excludedAssetIds: [String]
    /// Raw GPX data representing the imported GPS track.
    var gpxData: Data?
    
    /// Initializes a new SavedTrip.
    /// - Parameters:
    ///   - albumId: The PhotoKit album identifier.
    ///   - title: The title of the trip.
    ///   - gpxData: Optional GPX track data.
    init(albumId: String, title: String, gpxData: Data? = nil) {
        self.id = UUID().uuidString
        self.albumId = albumId
        self.title = title
        self.savedDate = Date()
        self.excludedAssetIds = []
        self.gpxData = gpxData
    }
}
