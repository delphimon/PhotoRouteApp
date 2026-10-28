import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static var gpx: UTType {
        UTType(filenameExtension: "gpx") ?? .xml
    }
}

/// A transferable representation of a generated GPX file with appropriate UTType and suggested filename.
struct ExportedGPXFile: Transferable {
    let gpxString: String
    let filename: String
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .gpx) { file in
            file.gpxString.data(using: .utf8) ?? Data()
        }
        .suggestedFileName { file in
            "\(file.filename).gpx"
        }
    }
}

/// A transferable representation of a generated CSV file with appropriate UTType and suggested filename.
struct ExportedCSVFile: Transferable {
    let csvString: String
    let filename: String
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .commaSeparatedText) { file in
            file.csvString.data(using: .utf8) ?? Data()
        }
        .suggestedFileName { file in
            "\(file.filename).csv"
        }
    }
}

struct ExportView: View {
    let analysis: TripAnalysis
    let albumTitle: String
    
    @State private var gpxOptions = GPXExportOptions()
    
    private var sanitizedTitle: String {
        let clean = albumTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return clean.isEmpty ? "Trip" : clean.replacingOccurrences(of: "/", with: "-")
    }
    
    var body: some View {
        Form {
            Section("GPX Export") {
                Toggle("Include Track", isOn: $gpxOptions.includeTrack)
                Toggle("Include Photo Waypoints", isOn: $gpxOptions.includeWaypoints)
                
                ShareLink(
                    item: ExportedGPXFile(
                        gpxString: GPXExporter.generateGPX(analysis: analysis, title: albumTitle, options: gpxOptions),
                        filename: sanitizedTitle
                    ),
                    preview: SharePreview("\(albumTitle) GPX")
                ) {
                    Label("Export GPX", systemImage: "square.and.arrow.up")
                }
            }
            
            Section("CSV Export") {
                ShareLink(
                    item: ExportedCSVFile(
                        csvString: CSVExporter.generateCSV(analysis: analysis),
                        filename: sanitizedTitle
                    ),
                    preview: SharePreview("\(albumTitle) CSV")
                ) {
                    Label("Export CSV", systemImage: "tablecells")
                }
            }
        }
        .navigationTitle("Export")
    }
}
