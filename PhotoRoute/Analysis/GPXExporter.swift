import Foundation

/// Utility for converting a `TripAnalysis` into a standard GPX XML format.
struct GPXExporter {
    
    /// Generates GPX XML data representing the analyzed photo route.
    /// - Parameters:
    ///   - analysis: The `TripAnalysis` containing the route segments.
    ///   - albumName: The name of the trip/album to use as the GPX track name.
    /// - Returns: UTF-8 encoded `Data` of the GPX string.
    static func generateGPX(from analysis: TripAnalysis, albumName: String) -> Data {
        var gpx = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="PhotoRoute" xmlns="http://www.topografix.com/GPX/1/1">
          <metadata>
            <name>\(albumName)</name>
          </metadata>
          <trk>
            <name>\(albumName)</name>
        """
        
        let formatter = ISO8601DateFormatter()
        
        for segment in analysis.segments {
            gpx += "\n    <trkseg>"
            for point in segment.points {
                gpx += "\n      <trkpt lat=\"\(point.coordinate.latitude)\" lon=\"\(point.coordinate.longitude)\">"
                if let alt = point.altitude {
                    gpx += "\n        <ele>\(alt)</ele>"
                }
                gpx += "\n        <time>\(formatter.string(from: point.creationDate))</time>"
                gpx += "\n      </trkpt>"
            }
            gpx += "\n    </trkseg>"
        }
        
        gpx += """
        
          </trk>
        </gpx>
        """
        
        return gpx.data(using: .utf8) ?? Data()
    }
}
