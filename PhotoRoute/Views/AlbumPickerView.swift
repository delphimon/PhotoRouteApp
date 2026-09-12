import SwiftUI
import Photos

struct AlbumPickerView: View {
    @StateObject private var service = PhotoLibraryService()
    
    var body: some View {
        NavigationStack {
            List(service.albums) { album in
                NavigationLink(destination: MapScreenView(album: album)) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(album.title)
                                .font(.headline)
                            Text("\(album.assetCount) assets")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Albums")
            .task {
                await service.fetchAlbums()
            }
        }
    }
}
