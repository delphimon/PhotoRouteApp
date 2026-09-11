import Foundation

struct RouteSegment: Identifiable, Sendable {
    let id = UUID()
    let points: [PhotoPoint]
}
