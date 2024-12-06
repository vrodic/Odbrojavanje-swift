// SunGraphViewModel.swift

import Foundation
import CoreLocation

class SunGraphViewModel: ObservableObject {
    @Published var sunPositions: [SunPosition] = []
    
    /// Generates sun positions for the entire year at specified intervals (e.g., every hour).
    /// - Parameters:
    ///   - year: The year for which to generate sun positions.
    ///   - location: The geographical location.
    ///   - intervalMinutes: The interval between points in minutes.
    func generateSunPositions(forYear year: Int, at location: CLLocationCoordinate2D, intervalMinutes: Int = 60) {
        sunPositions = []
        
        let calendar = Calendar.current
        let timeZone = TimeZone.current
        
        // Define the start and end dates of the year
        var startComponents = DateComponents()
        startComponents.year = year
        startComponents.month = 1
        startComponents.day = 1
        startComponents.hour = 0
        startComponents.minute = 0
        startComponents.second = 0
        
        var endComponents = DateComponents()
        endComponents.year = year
        endComponents.month = 12
        endComponents.day = 31
        endComponents.hour = 23
        endComponents.minute = 59
        endComponents.second = 59
        
        guard let startOfYear = calendar.date(from: startComponents),
              let endOfYear = calendar.date(from: endComponents) else {
            return
        }
        
        // Iterate through each day of the year
        var currentDate = startOfYear
        while currentDate <= endOfYear {
            // For each day, iterate through specified intervals
            for minute in stride(from: 0, to: 1440, by: intervalMinutes) { // 1440 minutes in a day
                if let sunDate = calendar.date(byAdding: .minute, value: minute, to: currentDate) {
                    do {
                        let sunPos = try SunCalculator.getSunPosition(date: sunDate, location: location)
                        sunPositions.append(sunPos)
                    } catch SunCalculator.CalculationError.sunNeverRises,
                             SunCalculator.CalculationError.sunNeverSets {
                        // Skip days where the sun never rises or sets
                        continue
                    } catch {
                        // Handle other errors if necessary
                        continue
                    }
                }
            }
            // Move to the next day
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
    }
}
