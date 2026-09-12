import SwiftUI
import MapKit
import SwiftData

/// Represents a dynamically clustered group of photos for map rendering.
struct PhotoCluster: Identifiable {
    /// The unique grid-based ID for the cluster.
    let id: String
    /// The map coordinate of the cluster (typically matching the first point).
    var coordinate: CLLocationCoordinate2D
    /// The total number of photos grouped in this cluster.
    var count: Int
    /// A representative photo point for the cluster, used for thumbnail display.
    var firstPoint: PhotoPoint
}

/// The main map interface for displaying the reconstructed photo route, clusters, and timeline scrubber.
struct MapScreenView: View {
    let album: PhotoAlbum
    var savedTrip: SavedTrip? = nil
    
    @Environment(\.modelContext) private var modelContext
    @StateObject private var analyzer = TripAnalyzer()
    @State private var selectedPoint: PhotoPoint?
    @State private var cameraDistance: Double = 100000
    @State private var mapCameraPosition: MapCameraPosition = .automatic
    
    @State private var mapStyle: AppMapStyle = .standard
    @State private var is3D: Bool = false
    @State private var isImportingGPX = false
    
    @State private var scrubTime: Double? = nil
    @State private var isScrubbing = false
    
    var computedMapStyle: MapStyle {
        let elevation: MapStyle.Elevation = is3D ? .realistic : .flat
        switch mapStyle {
        case .standard: return .standard(elevation: elevation)
        case .satellite: return .imagery(elevation: elevation)
        case .hybrid: return .hybrid(elevation: elevation)
        }
    }
    
    private var dynamicClusters: [PhotoCluster] {
        guard let points = analyzer.analysis?.points, !points.isEmpty else { return [] }
        
        let gridSize: Double
        if cameraDistance < 2000 {
            gridSize = 0.00005
        } else if cameraDistance < 10000 {
            gridSize = 0.0002
        } else if cameraDistance < 50000 {
            gridSize = 0.001
        } else if cameraDistance < 200000 {
            gridSize = 0.005
        } else {
            gridSize = 0.02
        }
        
        var grid: [String: PhotoCluster] = [:]
        for p in points {
            let gridX = Int(p.latitude / gridSize)
            let gridY = Int(p.longitude / gridSize)
            let key = "\(gridX)_\(gridY)"
            
            if var existing = grid[key] {
                existing.count += 1
                grid[key] = existing
            } else {
                let cluster = PhotoCluster(id: key, coordinate: p.coordinate, count: 1, firstPoint: p)
                grid[key] = cluster
            }
        }
        return Array(grid.values)
    }
    
    @MapContentBuilder
    private var routeContent: some MapContent {
        if let gpxPoints = analyzer.analysis?.simplifiedGpxTrackPoints, !gpxPoints.isEmpty {
            MapPolyline(coordinates: gpxPoints.map { $0.coordinate })
                .stroke(.blue, lineWidth: 3)
        } else if let segments = analyzer.analysis?.segments {
            ForEach(segments, id: \.id) { segment in
                MapPolyline(coordinates: segment.points.map { $0.coordinate })
                    .stroke(.blue, lineWidth: 3)
            }
        }
    }
    
    @MapContentBuilder
    private var annotationContent: some MapContent {
        ForEach(dynamicClusters) { cluster in
            Annotation("", coordinate: cluster.coordinate) {
                if cluster.count == 1 || cameraDistance < 2000 {
                    PhotoThumbnailView(point: cluster.firstPoint)
                        .onTapGesture {
                            selectedPoint = cluster.firstPoint
                            scrubTime = cluster.firstPoint.creationDate.timeIntervalSince1970
                        }
                } else {
                    Text("\(cluster.count)")
                        .font(.caption.bold())
                        .foregroundColor(.black)
                        .padding(6)
                        .background(Circle().fill(.white).shadow(radius: 2))
                }
            }
        }
    }
    
    @MapContentBuilder
    private var scrubberContent: some MapContent {
        if let time = scrubTime {
            let date = Date(timeIntervalSince1970: time)
            if let loc = analyzer.analysis?.timelineInterpolator?.interpolateLocation(for: date) {
                Annotation("Scrubber", coordinate: loc.coordinate) {
                    Circle()
                        .fill(.yellow)
                        .frame(width: 16, height: 16)
                        .overlay(Circle().stroke(.black, lineWidth: 2))
                        .shadow(radius: 3)
                }
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if analyzer.isAnalyzing {
                VStack {
                    Spacer()
                    ProgressView("Analyzing \(analyzer.analyzedCount) of \(analyzer.totalCount) photos...")
                    Spacer()
                }
            } else if let analysis = analyzer.analysis {
                Map(position: $mapCameraPosition) {
                    routeContent
                    annotationContent
                    scrubberContent
                }
                .mapStyle(computedMapStyle)
                .mapControls {
                    MapCompass()
                    MapPitchToggle()
                    MapUserLocationButton()
                    MapScaleView()
                }
                .onMapCameraChange(frequency: .continuous) { context in
                    cameraDistance = context.camera.distance
                }
                
                // Timeline Scrubber
                if let first = analysis.points.first?.creationDate, let last = analysis.points.last?.creationDate, first < last {
                    VStack(spacing: 4) {
                        if let time = scrubTime {
                            let date = Date(timeIntervalSince1970: time)
                            Text(date.formatted())
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(
                            value: Binding(
                                get: { scrubTime ?? first.timeIntervalSince1970 },
                                set: { newValue in
                                    scrubTime = newValue
                                    let date = Date(timeIntervalSince1970: newValue)
                                    if let loc = analysis.timelineInterpolator?.interpolateLocation(for: date) {
                                        mapCameraPosition = .camera(MapCamera(centerCoordinate: loc.coordinate, distance: 5000, pitch: is3D ? 60 : 0))
                                    }
                                }
                            ),
                            in: first.timeIntervalSince1970...last.timeIntervalSince1970,
                            onEditingChanged: { editing in
                                isScrubbing = editing
                            }
                        )
                    }
                    .padding()
                    .background(Color(.systemBackground))
                }
                
                VStack(spacing: 4) {
                    Text("\(analysis.validPointCount) GPS photos")
                        .font(.headline)
                    Text(String(format: "%.1f mi point-to-point", analysis.totalDistanceMiles))
                    Text(analysis.durationString)
                }
                .padding(.horizontal)
                .padding(.bottom)
                .background(Color(.systemBackground))
            } else {
                Text("Failed to analyze trip")
            }
        }
        .navigationTitle(album.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    if savedTrip == nil {
                        Button("Save Trip") {
                            let newTrip = SavedTrip(albumId: album.id, title: album.title)
                            modelContext.insert(newTrip)
                        }
                    }
                    
                    Button("Load GPX Tracker") {
                        isImportingGPX = true
                    }
                    
                    Picker("Map Style", selection: $mapStyle) {
                        ForEach(AppMapStyle.allCases, id: \.self) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    Toggle("3D Terrain", isOn: $is3D)
                } label: {
                    Image(systemName: "map")
                }
            }
            
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
            var pts: [GPXTrackPoint]? = nil
            if let data = savedTrip?.gpxData {
                pts = GPXParser().parse(data: data)
            }
            if let excluded = savedTrip?.excludedAssetIds {
                analyzer.settings.excludedIds = Set(excluded)
            }
            await analyzer.analyze(album: album, gpxTrackPoints: pts)
        }
        .sheet(item: $selectedPoint) { point in
            PhotoInspectionSheet(point: point, trip: savedTrip, analyzer: analyzer)
                .presentationDetents([.medium, .large])
        }
        .fileImporter(isPresented: $isImportingGPX, allowedContentTypes: [.xml]) { result in
            do {
                let url = try result.get()
                if url.startAccessingSecurityScopedResource() {
                    let data = try Data(contentsOf: url)
                    let parser = GPXParser()
                    let trackPoints = parser.parse(data: data)
                    
                    if let trip = savedTrip {
                        trip.gpxData = data
                    }
                    
                    Task {
                        await analyzer.applyGPXTrack(trackPoints)
                    }
                    url.stopAccessingSecurityScopedResource()
                }
            } catch {
                print("Failed to load GPX: \(error)")
            }
        }
    }
}
