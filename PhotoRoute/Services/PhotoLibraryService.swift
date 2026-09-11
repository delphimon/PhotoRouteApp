import Foundation
import Photos

@MainActor
class PhotoLibraryService: ObservableObject {
    @Published var albums: [PhotoAlbum] = []
    
    func fetchAlbums() async {
        var fetchedAlbums: [PhotoAlbum] = []
        
        let userAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil)
        
        for i in 0..<userAlbums.count {
            let collection = userAlbums.object(at: i)
            let fetchOptions = PHFetchOptions()
            let assets = PHAsset.fetchAssets(in: collection, options: fetchOptions)
            
            if assets.count > 0 {
                fetchedAlbums.append(PhotoAlbum(
                    id: collection.localIdentifier,
                    title: collection.localizedTitle ?? "Untitled",
                    assetCount: assets.count,
                    collection: collection
                ))
            }
        }
        
        for i in 0..<smartAlbums.count {
            let collection = smartAlbums.object(at: i)
            let fetchOptions = PHFetchOptions()
            let assets = PHAsset.fetchAssets(in: collection, options: fetchOptions)
            
            if assets.count > 0 {
                fetchedAlbums.append(PhotoAlbum(
                    id: collection.localIdentifier,
                    title: collection.localizedTitle ?? "Untitled",
                    assetCount: assets.count,
                    collection: collection
                ))
            }
        }
        
        self.albums = fetchedAlbums
    }
}
