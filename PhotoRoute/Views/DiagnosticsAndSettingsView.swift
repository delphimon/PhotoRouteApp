import SwiftUI

struct DiagnosticsAndSettingsView: View {
    @Binding var settings: SegmentationSettings
    let analysis: TripAnalysis
    
    var body: some View {
        Form {
            Section("Diagnostics") {
                LabeledContent("Valid Points", value: "\(analysis.validPointCount)")
                LabeledContent("Segments", value: "\(analysis.segments.count)")
                LabeledContent("Total Distance", value: String(format: "%.1f km", analysis.totalDistanceMeters / 1000.0))
                LabeledContent("Duration", value: analysis.durationString)
            }
            
            Section("Segmentation Mode") {
                Picker("Mode", selection: $settings.mode) {
                    Text("Continuous").tag(SegmentationMode.continuous)
                    Text("Smart").tag(SegmentationMode.smart)
                    Text("Custom").tag(SegmentationMode.custom)
                }
                .pickerStyle(.segmented)
            }
            
            if settings.mode == .custom {
                Section("Custom Settings") {
                    HStack {
                        Text("Max Time Gap (hrs)")
                        Spacer()
                        TextField("Hours", value: $settings.maxTimeGapHours, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Max Distance Gap (km)")
                        Spacer()
                        TextField("Km", value: $settings.maxDistanceGapKilometers, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Max Implied Speed (km/h)")
                        Spacer()
                        TextField("Km/h", value: $settings.maxSpeedKmh, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
        }
        .navigationTitle("Diagnostics & Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
