import XCTest
import CoreLocation
@testable import PhotoRoute

final class RouteInterpolatorTests: XCTestCase {
    func testInterpolation() {
        let formatter = ISO8601DateFormatter()
        let t1 = formatter.date(from: "2026-06-20T14:00:00Z")!
        let t2 = formatter.date(from: "2026-06-20T15:00:00Z")!
        let t3 = formatter.date(from: "2026-06-20T16:00:00Z")!
        
        let p1 = GPXTrackPoint(coordinate: CLLocationCoordinate2D(latitude: 10, longitude: 10), altitude: 100, time: t1)
        let p2 = GPXTrackPoint(coordinate: CLLocationCoordinate2D(latitude: 20, longitude: 20), altitude: 200, time: t3)
        
        let interpolator = RouteInterpolator(trackPoints: [p1, p2])
        
        // Exact match p1
        let result1 = interpolator.interpolateLocation(for: t1)!
        XCTAssertEqual(result1.coordinate.latitude, 10.0)
        
        // Exact match p2
        let result3 = interpolator.interpolateLocation(for: t3)!
        XCTAssertEqual(result3.coordinate.latitude, 20.0)
        
        // Interpolate exact midpoint (t2 is 14:30 relative? No, t2 is 15:00, exact midpoint of 14:00 and 16:00)
        let result2 = interpolator.interpolateLocation(for: t2)!
        XCTAssertEqual(result2.coordinate.latitude, 15.0)
        XCTAssertEqual(result2.coordinate.longitude, 15.0)
        XCTAssertEqual(result2.altitude, 150.0)
        
        // Before bounds
        let t0 = formatter.date(from: "2026-06-20T13:00:00Z")!
        let result0 = interpolator.interpolateLocation(for: t0)!
        XCTAssertEqual(result0.coordinate.latitude, 10.0)
        
        // After bounds
        let t4 = formatter.date(from: "2026-06-20T17:00:00Z")!
        let result4 = interpolator.interpolateLocation(for: t4)!
        XCTAssertEqual(result4.coordinate.latitude, 20.0)
    }
}
