import SwiftUI
import MapKit

struct MapScreenView: View {
    let album: PhotoAlbum
    @StateObject private var analyzer = TripAnalyzer()
    @State private var selectedPoint: PhotoPoint?
    
    var body: some View {
        VStack(spacing: 0) {
            if analyzer.isAnalyzing {
                VStack {
                    Spacer()
                    ProgressView("Analyzing \(analyzer.analyzedCount) of \(analyzer.totalCount) photos...")
                    Spacer()
                }
            } else if let analysis = analyzer.analysis {
                Map {
                    ForEach(analysis.segments, id: \.id) { segment in
                        MapPolyline(coordinates: segment.points.map { $0.coordinate })
                            .stroke(.blue, lineWidth: 3)
                    }
                    
                    ForEach(analysis.points) { point in
                        Annotation("", coordinate: point.coordinate) {
                            Circle()
                                .fill(.red)
                                .frame(width: 8, height: 8)
                                .onTapGesture {
                                    selectedPoint = point
                                }
                        }
                    }
                }
                
                VStack(spacing: 4) {
                    Text("\(analysis.validPointCount) GPS photos")
                        .font(.headline)
                    Text(String(format: "%.1f mi point-to-point", analysis.totalDistanceMiles))
                    Text(analysis.durationString)
                    
                    if analyzer.settings.mode == .smart && analysis.segments.count > 1 {
                        Text("⚠ \(analysis.segments.count - 1) gaps")
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
            } else {
                Text("Failed to analyze trip")
            }
        }
        .navigationTitle(album.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if analyzer.analysis != nil {
                    NavigationLink {
                        DiagnosticsAndSettingsView(settings: $analyzer.settings, analysis: analyzer.analysis!)
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    
                    NavigationLink {
                        ExportView(analysis: analyzer.analysis!, albumTitle: album.title)
                    } label: {
                        Text("Export")
                    }
                }
            }
        }
        .task {
            await analyzer.analyze(album: album)
        }
        .sheet(item: $selectedPoint) { point in
            PhotoInspectionSheet(point: point)
                .presentationDetents([.medium, .large])
        }
    }
}
