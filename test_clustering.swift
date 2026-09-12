import SwiftUI
import MapKit
struct TestMap: View {
    var body: some View {
        Map {
            Annotation("A", coordinate: CLLocationCoordinate2D(), clusteringIdentifier: "photos") {
                Circle()
            }
        }
    }
}
