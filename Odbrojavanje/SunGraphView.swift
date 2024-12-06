// SunGraphView.swift

import SwiftUI
import Charts
import CoreLocation

struct SunGraphView: View {
    var year: Int
    var location: CLLocationCoordinate2D
    
    @StateObject private var viewModel = SunGraphViewModel()
    
    var body: some View {
        VStack {
            Text("Sun Path in \(year)")
                .font(.headline)
                .padding()
            
            if viewModel.sunPositions.isEmpty {
                ProgressView("Loading Sun Data...")
                    .onAppear {
                        viewModel.generateSunPositions(forYear: year, at: location)
                    }
            } else {
                // Aggregate sun positions by time of day to compute average altitude
                let groupedByTime = Dictionary(grouping: viewModel.sunPositions) { position -> DateComponents in
                    let calendar = Calendar.current
                    let components = calendar.dateComponents([.hour, .minute], from: position.time)
                    return components
                }
                
                // Calculate average altitude for each time of day
                let averageAltitudes = groupedByTime.compactMap { (key, positions) -> (time: Date, averageAltitude: Double)? in
                    guard let first = positions.first else { return nil }
                    let calendar = Calendar.current
                    var components = calendar.dateComponents([.year, .month, .day], from: first.time)
                    components.hour = key.hour
                    components.minute = key.minute
                    components.second = 0
                    guard let time = calendar.date(from: components) else { return nil }
                    let avgAltitude = positions.map { $0.altitude }.reduce(0, +) / Double(positions.count)
                    return (time, avgAltitude)
                }
                .sorted { $0.time < $1.time }
                
                // Display the chart
                Chart {
                    ForEach(averageAltitudes, id: \.time) { dataPoint in
                        LineMark(
                            x: .value("Time", dataPoint.time),
                            y: .value("Average Altitude", dataPoint.averageAltitude)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Color.orange)
                        
                        PointMark(
                            x: .value("Time", dataPoint.time),
                            y: .value("Average Altitude", dataPoint.averageAltitude)
                        )
                        .foregroundStyle(Color.orange)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .hour)) { value in
                        AxisValueLabel(format: Date.FormatStyle.dateTime.hour().minute(.twoDigits))
                    }
                }
                .padding()
            }
            
            Spacer()
        }
        .onAppear {
            viewModel.generateSunPositions(forYear: year, at: location)
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: Date())
    }
}

struct SunGraphView_Previews: PreviewProvider {
    static var previews: some View {
        SunGraphView(
            year: 2024,
            location: CLLocationCoordinate2D(latitude: 45.8150, longitude: 15.9819) // Example: Zagreb
        )
    }
}
