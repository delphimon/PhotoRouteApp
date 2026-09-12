import SwiftUI
import Photos

/// A view that displays a list of photo albums from the user's photo library.
///
/// `AlbumPickerView` uses `PhotoLibraryService` to fetch and list albums.
/// Selecting an album navigates the user to the `MapScreenView` to view the route.
struct AlbumPickerView: View {
    /// The photo library service responsible for fetching albums and requesting authorization.
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
