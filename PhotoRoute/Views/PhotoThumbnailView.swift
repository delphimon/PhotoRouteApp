import SwiftUI
import Photos

/// A view that asynchronously loads and displays a thumbnail for a given photo point.
///
/// Intended to be used as a map annotation marker.
struct PhotoThumbnailView: View {
    /// The photo point containing the asset identifier.
    let point: PhotoPoint
    
    /// The loaded image thumbnail, or nil if still loading.
    @State private var thumbnail: UIImage?
    
    var body: some View {
        Group {
            if let img = thumbnail {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .shadow(radius: 2)
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray)
                    .frame(width: 40, height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .shadow(radius: 2)
            }
        }
        .task {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        let fetchOptions = PHFetchOptions()
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [point.id], options: fetchOptions)
        guard let asset = assets.firstObject else { return }
        
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .fastFormat // Use fast format for map markers
        
        manager.requestImage(for: asset, targetSize: CGSize(width: 120, height: 120), contentMode: .aspectFill, options: options) { image, _ in
            if let img = image {
                DispatchQueue.main.async {
                    self.thumbnail = img
                }
            }
        }
    }
}
