import Foundation
import Photos

struct PhotoAlbum: Identifiable {
    let id: String
    let title: String
    let assetCount: Int
    let collection: PHAssetCollection
}
