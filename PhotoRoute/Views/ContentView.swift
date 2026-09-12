import SwiftUI
import Photos
import SwiftData

/// Represents an item selected in the sidebar navigation.
enum SidebarItem: Hashable {
    /// The main photo albums view.
    case albums
    /// A specifically saved trip using its persistent identifier string.
    case savedTrip(String)
}

/// The root application view that handles Photos authorization and navigation structure.
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var savedTrips: [SavedTrip]
    
    @State private var authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    @State private var selection: SidebarItem? = .albums
    
    var body: some View {
        Group {
            if authorizationStatus == .authorized || authorizationStatus == .limited {
                NavigationSplitView {
                    List(selection: $selection) {
                        Section("Photos") {
                            NavigationLink(value: SidebarItem.albums) {
                                Label("Photo Albums", systemImage: "photo.stack")
                            }
                        }
                        
                        Section("Saved Trips") {
                            if savedTrips.isEmpty {
                                Text("No saved trips yet.")
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(savedTrips) { trip in
                                    NavigationLink(value: SidebarItem.savedTrip(trip.id)) {
                                        Label(trip.title, systemImage: "map")
                                    }
                                }
                            }
                        }
                    }
                    .navigationTitle("PhotoRoute")
                } detail: {
                    if let selection = selection {
                        switch selection {
                        case .albums:
                            AlbumPickerView()
                        case .savedTrip(let id):
                            if let trip = savedTrips.first(where: { $0.id == id }) {
                                // Dummy album for now, ideally we fetch the real album title and re-analyze
                                let dummyAlbum = PhotoAlbum(id: trip.albumId, title: trip.title, assetCount: 0, collection: nil)
                                MapScreenView(album: dummyAlbum, savedTrip: trip)
                            }
                        }
                    } else {
                        Text("Select an item")
                            .foregroundColor(.secondary)
                    }
                }
            } else if authorizationStatus == .notDetermined {
                VStack {
                    Text("PhotoRoute needs access to your photos to reconstruct your trip.")
                        .multilineTextAlignment(.center)
                        .padding()
                    Button("Grant Access") {
                        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                            DispatchQueue.main.async {
                                self.authorizationStatus = status
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                VStack {
                    Text("Photo access was denied. Please enable it in Settings.")
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            }
        }
    }
}
