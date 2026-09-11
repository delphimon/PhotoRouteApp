import Foundation

struct GPXExportOptions {
    var includeTrack: Bool = true
    var includeWaypoints: Bool = false
}

struct GPXExporter {
    static func generateGPX(analysis: TripAnalysis, title: String, options: GPXExportOptions) -> String {
        var gpx = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        gpx += "<gpx version=\"1.1\" creator=\"PhotoRoute\" xmlns=\"http://www.topografix.com/GPX/1/1\">\n"
        gpx += "  <metadata>\n"
        gpx += "    <name>\(escapeXML(title))</name>\n"
        gpx += "  </metadata>\n"
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        
        if options.includeWaypoints {
            for point in analysis.points {
                gpx += "  <wpt lat=\"\(point.latitude)\" lon=\"\(point.longitude)\">\n"
                if let ele = point.altitude {
                    gpx += "    <ele>\(ele)</ele>\n"
                }
                gpx += "    <time>\(formatter.string(from: point.creationDate))</time>\n"
                let name = point.filename ?? "Photo"
                gpx += "    <name>\(escapeXML(name))</name>\n"
                gpx += "  </wpt>\n"
            }
        }
        
        if options.includeTrack {
            gpx += "  <trk>\n"
            gpx += "    <name>\(escapeXML(title))</name>\n"
            for segment in analysis.segments {
                gpx += "    <trkseg>\n"
                for point in segment.points {
                    gpx += "      <trkpt lat=\"\(point.latitude)\" lon=\"\(point.longitude)\">\n"
                    if let ele = point.altitude {
                        gpx += "        <ele>\(ele)</ele>\n"
                    }
                    gpx += "        <time>\(formatter.string(from: point.creationDate))</time>\n"
                    gpx += "      </trkpt>\n"
                }
                gpx += "    </trkseg>\n"
            }
            gpx += "  </trk>\n"
        }
        
        gpx += "</gpx>\n"
        return gpx
    }
    
    private static func escapeXML(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}
