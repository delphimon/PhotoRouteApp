import SwiftUI
import Photos

struct PhotoInspectionSheet: View {
    let point: PhotoPoint
    var trip: SavedTrip?
    @ObservedObject var analyzer: TripAnalyzer
    
    @State private var thumbnail: UIImage?
    
    var body: some View {
        VStack(spacing: 20) {
            if let image = thumbnail {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 200)
                    .overlay(ProgressView())
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Photo Details").font(.headline)
                
                LabeledContent("Date", value: point.creationDate.formatted())
                LabeledContent("Latitude", value: String(format: "%.5f", point.latitude))
                LabeledContent("Longitude", value: String(format: "%.5f", point.longitude))
                if let alt = point.altitude {
                    LabeledContent("Altitude", value: String(format: "%.1f m", alt))
                }
                if let fn = point.filename {
                    LabeledContent("Filename", value: fn)
                }
                LabeledContent("Type", value: point.isVideo ? "Video" : "Image")
                
                Toggle("Include in Route", isOn: Binding(
                    get: { !analyzer.settings.excludedIds.contains(point.id) },
                    set: { included in
                        if included {
                            analyzer.settings.excludedIds.remove(point.id)
                        } else {
                            analyzer.settings.excludedIds.insert(point.id)
                        }
                        if let trip = trip {
                            trip.excludedAssetIds = Array(analyzer.settings.excludedIds)
                        }
                    }
                ))
            }
            .padding()
            
            Spacer()
        }
        .padding()
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
        options.deliveryMode = .opportunistic
        
        manager.requestImage(for: asset, targetSize: CGSize(width: 300, height: 300), contentMode: .aspectFill, options: options) { image, _ in
            if let img = image {
                DispatchQueue.main.async {
                    self.thumbnail = img
                }
            }
        }
    }
}
