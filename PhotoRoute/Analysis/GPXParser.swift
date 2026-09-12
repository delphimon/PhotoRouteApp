import Foundation
import CoreLocation

/// Represents a single point parsed from a GPX track.
struct GPXTrackPoint: Equatable, Sendable {
    /// The geographic coordinate of the track point.
    let coordinate: CLLocationCoordinate2D
    /// The altitude in meters.
    let altitude: Double?
    /// The timestamp when this point was recorded.
    let time: Date
    
    static func == (lhs: GPXTrackPoint, rhs: GPXTrackPoint) -> Bool {
        return lhs.time == rhs.time && lhs.coordinate.latitude == rhs.coordinate.latitude && lhs.coordinate.longitude == rhs.coordinate.longitude
    }
}

/// A parser for extracting `GPXTrackPoint`s from a raw GPX XML file.
class GPXParser: NSObject, XMLParserDelegate {
    private var trackPoints: [GPXTrackPoint] = []
    
    private var currentLat: Double?
    private var currentLon: Double?
    private var currentEle: Double?
    private var currentTimeStr: String = ""
    
    private var currentElement: String = ""
    private var isInsideTrkpt = false
    
    /// Parses GPX data into an array of track points.
    /// - Parameter data: The raw XML `Data` of the GPX file.
    /// - Returns: An array of `GPXTrackPoint`s, sorted chronologically.
    func parse(data: Data) -> [GPXTrackPoint] {
        trackPoints = []
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return trackPoints.sorted(by: { $0.time < $1.time })
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if elementName == "trkpt" {
            isInsideTrkpt = true
            if let latStr = attributeDict["lat"], let lonStr = attributeDict["lon"] {
                currentLat = Double(latStr)
                currentLon = Double(lonStr)
            }
        } else if elementName == "ele" {
            currentEle = nil
        } else if elementName == "time" {
            currentTimeStr = ""
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard isInsideTrkpt else { return }
        if currentElement == "ele" {
            if let val = Double(string.trimmingCharacters(in: .whitespacesAndNewlines)) {
                currentEle = val
            }
        } else if currentElement == "time" {
            currentTimeStr += string
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "trkpt" {
            if let lat = currentLat, let lon = currentLon {
                let formatter = ISO8601DateFormatter()
                if let date = formatter.date(from: currentTimeStr.trimmingCharacters(in: .whitespacesAndNewlines)) {
                    let pt = GPXTrackPoint(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon), altitude: currentEle, time: date)
                    trackPoints.append(pt)
                }
            }
            isInsideTrkpt = false
            currentLat = nil
            currentLon = nil
            currentEle = nil
            currentTimeStr = ""
        }
        currentElement = ""
    }
}
