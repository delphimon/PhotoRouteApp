import Foundation
import Photos

/// Represents a photo album containing a collection of assets.
/// Provides a lightweight representation for the UI to display and select albums.
struct PhotoAlbum: Identifiable {
    /// Unique identifier for the album (usually the localIdentifier from PhotoKit).
    let id: String
    /// The localized title of the album.
    let title: String
    /// The number of assets contained within the album.
    let assetCount: Int
    /// The underlying PHAssetCollection from PhotoKit.
    let collection: PHAssetCollection?
}
