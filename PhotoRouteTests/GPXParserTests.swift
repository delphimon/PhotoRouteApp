import XCTest
@testable import PhotoRoute

final class GPXParserTests: XCTestCase {
    func testParseGPX() {
        let gpx = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="Test">
          <trk>
            <trkseg>
              <trkpt lat="47.6062" lon="-122.3321">
                <ele>10.5</ele>
                <time>2026-06-20T14:30:00Z</time>
              </trkpt>
              <trkpt lat="47.6063" lon="-122.3322">
                <time>2026-06-20T14:31:00Z</time>
              </trkpt>
            </trkseg>
          </trk>
        </gpx>
        """
        
        let parser = GPXParser()
        let points = parser.parse(data: gpx.data(using: .utf8)!)
        
        XCTAssertEqual(points.count, 2)
        XCTAssertEqual(points[0].coordinate.latitude, 47.6062)
        XCTAssertEqual(points[0].coordinate.longitude, -122.3321)
        XCTAssertEqual(points[0].altitude, 10.5)
        
        let formatter = ISO8601DateFormatter()
        XCTAssertEqual(points[0].time, formatter.date(from: "2026-06-20T14:30:00Z"))
        
        XCTAssertEqual(points[1].coordinate.latitude, 47.6063)
        XCTAssertNil(points[1].altitude)
    }
}
