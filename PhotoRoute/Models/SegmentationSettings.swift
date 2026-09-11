import Foundation

enum SegmentationMode: Equatable {
    case continuous
    case smart
    case custom
}

struct SegmentationSettings: Equatable {
    var mode: SegmentationMode = .smart
    
    // Custom settings limits
    var maxTimeGapHours: Double = 12.0
    var maxDistanceGapKilometers: Double = 25.0
    var maxSpeedKmh: Double = 60.0
    
    static let `default` = SegmentationSettings()
}
