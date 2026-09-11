import CoreLocation

struct CSVExporter {
    static func generateCSV(analysis: TripAnalysis) -> String {
        var csv = "sequence,asset_identifier,filename,capture_time_local,capture_time_utc,latitude,longitude,altitude_meters,horizontal_accuracy_meters,media_type,segment_number,distance_from_previous_meters,time_from_previous_seconds,implied_speed_kmh\n"
        
        let localFormatter = DateFormatter()
        localFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let utcFormatter = ISO8601DateFormatter()
        
        var sequence = 1
        var segmentNumber = 1
        
        for segment in analysis.segments {
            var prevPoint: PhotoPoint? = nil
            
            for point in segment.points {
                let identifier = escapeCSV(point.id)
                let filename = escapeCSV(point.filename ?? "")
                let localTime = escapeCSV(localFormatter.string(from: point.creationDate))
                let utcTime = escapeCSV(utcFormatter.string(from: point.creationDate))
                
                let lat = "\(point.latitude)"
                let lon = "\(point.longitude)"
                let alt = point.altitude.map { "\($0)" } ?? ""
                let acc = point.horizontalAccuracy.map { "\($0)" } ?? ""
                let mediaType = point.isVideo ? "video" : "image"
                
                var distStr = ""
                var timeStr = ""
                var speedStr = ""
                
                if let prev = prevPoint {
                    let loc1 = CLLocation(latitude: prev.latitude, longitude: prev.longitude)
                    let loc2 = CLLocation(latitude: point.latitude, longitude: point.longitude)
                    let dist = loc2.distance(from: loc1)
                    let time = point.creationDate.timeIntervalSince(prev.creationDate)
                    let speed = (time > 0) ? (dist / 1000.0) / (time / 3600.0) : 0.0
                    
                    distStr = String(format: "%.2f", dist)
                    timeStr = String(format: "%.0f", time)
                    speedStr = String(format: "%.2f", speed)
                }
                
                let row = "\(sequence),\(identifier),\(filename),\(localTime),\(utcTime),\(lat),\(lon),\(alt),\(acc),\(mediaType),\(segmentNumber),\(distStr),\(timeStr),\(speedStr)\n"
                csv += row
                
                sequence += 1
                prevPoint = point
            }
            segmentNumber += 1
        }
        
        return csv
    }
    
    private static func escapeCSV(_ string: String) -> String {
        if string.contains(",") || string.contains("\"") || string.contains("\n") {
            let escaped = string.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return string
    }
}
