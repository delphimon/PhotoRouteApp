import SwiftUI

struct ExportView: View {
    let analysis: TripAnalysis
    let albumTitle: String
    
    @State private var gpxOptions = GPXExportOptions()
    
    var body: some View {
        Form {
            Section("GPX Export") {
                Toggle("Include Track", isOn: $gpxOptions.includeTrack)
                Toggle("Include Photo Waypoints", isOn: $gpxOptions.includeWaypoints)
                
                let gpxString = GPXExporter.generateGPX(analysis: analysis, title: albumTitle, options: gpxOptions)
                if let data = gpxString.data(using: .utf8) {
                    ShareLink(
                        item: CSVFile(data: data, filename: "\(sanitizedTitle).gpx", contentType: .xml),
                        preview: SharePreview("\(albumTitle) GPX")
                    ) {
                        Label("Export GPX", systemImage: "square.and.arrow.up")
                    }
                }
            }
            
            Section("CSV Export") {
                let csvString = CSVExporter.generateCSV(analysis: analysis)
                if let data = csvString.data(using: .utf8) {
                    ShareLink(
                        item: CSVFile(data: data, filename: "\(sanitizedTitle).csv", contentType: .commaSeparatedText),
                        preview: SharePreview("\(albumTitle) CSV")
                    ) {
                        Label("Export CSV", systemImage: "tablecells")
                    }
                }
            }
        }
        .navigationTitle("Export")
    }
    
    var sanitizedTitle: String {
        let invalidCharacters = CharacterSet(charactersIn: "\\/:*?\"<>| ")
        return albumTitle.components(separatedBy: invalidCharacters).joined(separator: "-")
    }
}

import UniformTypeIdentifiers

struct CSVFile: Transferable {
    let data: Data
    let filename: String
    let contentType: UTType
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .data) { file in
            file.data
        }
    }
}
