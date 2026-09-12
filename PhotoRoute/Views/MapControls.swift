import SwiftUI

/// Map styles available in the application for MapKit.
enum AppMapStyle: String, CaseIterable {
    /// Standard vector street map.
    case standard = "Standard"
    /// Satellite imagery without labels.
    case satellite = "Satellite"
    /// Satellite imagery with street labels overlaid.
    case hybrid = "Hybrid"
}
