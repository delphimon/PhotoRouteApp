import SwiftUI
import Photos
import SwiftData

/// The root application view that handles Photos authorization, Home screen navigation, and saved trips management.
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \SavedTrip.savedDate, order: .reverse) private var savedTrips: [SavedTrip]
    
    @State private var authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    
    var body: some View {
        Group {
            if authorizationStatus == .authorized || authorizationStatus == .limited {
                NavigationStack {
                    List {
                        Section("Photos") {
                            NavigationLink {
                                AlbumPickerView()
                            } label: {
                                Label("Photo Albums", systemImage: "photo.stack")
                            }
                        }
                        
                        Section("Saved Trips") {
                            if savedTrips.isEmpty {
                                Text("No saved trips yet.")
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(savedTrips) { trip in
                                    NavigationLink {
                                        let dummyAlbum = PhotoAlbum(id: trip.albumId, title: trip.title, assetCount: 0, collection: nil)
                                        MapScreenView(album: dummyAlbum, savedTrip: trip)
                                    } label: {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(trip.title)
                                                .font(.headline)
                                            Text(trip.savedDate.formatted(date: .abbreviated, time: .shortened))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            deleteTrip(trip)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            deleteTrip(trip)
                                        } label: {
                                            Label("Delete Trip", systemImage: "trash")
                                        }
                                    }
                                }
                                .onDelete(perform: deleteTrips)
                            }
                        }
                        
                        Section("About") {
                            Link(destination: URL(string: "https://adventureleader.org/privacy")!) {
                                Label("Privacy Policy", systemImage: "hand.raised")
                            }
                        }
                    }
                    .navigationTitle("PhotoRoute")
                    .toolbar {
                        if !savedTrips.isEmpty {
                            ToolbarItem(placement: .topBarTrailing) {
                                EditButton()
                            }
                        }
                    }
                }
            } else if authorizationStatus == .notDetermined {
                VStack(spacing: 16) {
                    Image(systemName: "photo.stack")
                        .font(.system(size: 60))
                        .foregroundColor(.accentColor)
                    Text("Welcome to PhotoRoute")
                        .font(.title)
                        .bold()
                    Text("PhotoRoute needs access to your photos to reconstruct your trips. Your photos and location data remain on this device.")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .foregroundColor(.secondary)
                    Button("Grant Access") {
                        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                            DispatchQueue.main.async {
                                self.authorizationStatus = status
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "lock.slash")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("Photo Access Required")
                        .font(.title2)
                        .bold()
                    Text("Photo access was denied. Please enable Photos access in Settings to view your photo routes.")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .foregroundColor(.secondary)
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            }
        }
    }
    
    private func deleteTrips(at offsets: IndexSet) {
        for index in offsets {
            let trip = savedTrips[index]
            modelContext.delete(trip)
        }
    }
    
    private func deleteTrip(_ trip: SavedTrip) {
        modelContext.delete(trip)
    }
}
