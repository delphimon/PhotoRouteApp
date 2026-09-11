import SwiftUI
import Photos

struct ContentView: View {
    @State private var authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    
    var body: some View {
        NavigationStack {
            Group {
                switch authorizationStatus {
                case .authorized, .limited:
                    AlbumPickerView()
                case .notDetermined:
                    VStack(spacing: 20) {
                        Text("Build a Route From Photos")
                            .font(.largeTitle)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Text("Choose a Photos album and PhotoRoute will use the time and location of your pictures to reconstruct your trip.")
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button("Grant Access") {
                            requestAccess()
                        }
                        .buttonStyle(.borderedProminent)
                        .padding()
                    }
                case .denied, .restricted:
                    VStack {
                        Text("Photo Access Denied")
                            .font(.title)
                        Text("Please enable photo access in Settings to use PhotoRoute.")
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                @unknown default:
                    Text("Unknown authorization status")
                }
            }
            .navigationTitle("PhotoRoute")
        }
    }
    
    private func requestAccess() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                self.authorizationStatus = status
            }
        }
    }
}
