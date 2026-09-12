import Foundation
import Photos
import Combine

/// A MainActor observable service to interact with Apple's PhotoKit API.
@MainActor
class PhotoLibraryService: ObservableObject {
    /// The available photo albums.
    @Published var albums: [PhotoAlbum] = []
    
    /// Initializes a new service instance.
    init() {}
    
    /// Requests user authorization to access the photo library.
    /// - Returns: `true` if authorized, `false` otherwise.
    func requestAuthorization() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        return status == .authorized || status == .limited
    }
    
    /// Fetches all user-created and smart photo albums.
    func fetchAlbums() async {
        guard await requestAuthorization() else { return }
        
        var fetchedAlbums: [PhotoAlbum] = []
        
        let userAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
        userAlbums.enumerateObjects { (collection, _, _) in
            let fetchOptions = PHFetchOptions()
            let count = PHAsset.fetchAssets(in: collection, options: fetchOptions).count
            if count > 0 {
                fetchedAlbums.append(PhotoAlbum(id: collection.localIdentifier, title: collection.localizedTitle ?? "Unnamed", assetCount: count, collection: collection))
            }
        }
        
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil)
        smartAlbums.enumerateObjects { (collection, _, _) in
            let fetchOptions = PHFetchOptions()
            let count = PHAsset.fetchAssets(in: collection, options: fetchOptions).count
            if count > 0 {
                fetchedAlbums.append(PhotoAlbum(id: collection.localIdentifier, title: collection.localizedTitle ?? "Unnamed", assetCount: count, collection: collection))
            }
        }
        
        self.albums = fetchedAlbums.sorted { $0.title < $1.title }
    }
}
