// SunCalculator.swift

import Foundation
import CoreLocation

// Ensure that SunPosition.swift and SunEvent.swift are correctly defined and included in your project.

class SunCalculator {
    enum CalculationError: Error {
        case sunNeverRises
        case sunNeverSets
        case invalidDate
    }
    
    /// Calculates the time of a specific sun event for a given date and location.
    /// - Parameters:
    ///   - date: The date for which to calculate the sun event.
    ///   - sunEvent: The sun event to calculate.
    ///   - location: The geographical location (latitude and longitude).
    /// - Returns: The date and time of the sun event.
    /// - Throws: CalculationError if the sun never rises or sets on the given date/location.
    static func getSunTime(date: Date, sunEvent: SunEvent, location: CLLocationCoordinate2D) throws -> Date {
        // Constants
        let zenith: Double
        let approxTime: Double
        let isDawn: Bool
        let isDusk: Bool
        
        // Time zone handling
        let calendar = Calendar.current
        let timeZone = TimeZone.current
        var dateComponents = calendar.dateComponents(in: timeZone, from: date)
        dateComponents.hour = 12
        dateComponents.minute = 0
        dateComponents.second = 0
        guard let noon = calendar.date(from: dateComponents) else { throw CalculationError.invalidDate }
        
        // Calculate day of the year
        let dayOfYear = dayOfYear(year: calendar.component(.year, from: date),
                                  month: calendar.component(.month, from: date),
                                  day: calendar.component(.day, from: date))
        
        // Convert longitude to hour value
        let lngHour = location.longitude / 15.0
        
        // Determine zenith and approximate time based on sun event
        switch sunEvent {
        case .sunrise, .sunset:
            zenith = 90.833
            if sunEvent == .sunrise {
                approxTime = Double(dayOfYear) + ((6.0 - lngHour) / 24.0)
                isDawn = true
                isDusk = false
            } else {
                approxTime = Double(dayOfYear) + ((18.0 - lngHour) / 24.0)
                isDawn = false
                isDusk = true
            }
        case .civilDawn, .civilDusk:
            zenith = 96.0
            if sunEvent == .civilDawn {
                approxTime = Double(dayOfYear) + ((6.0 - lngHour) / 24.0)
                isDawn = true
                isDusk = false
            } else {
                approxTime = Double(dayOfYear) + ((18.0 - lngHour) / 24.0)
                isDawn = false
                isDusk = true
            }
        case .nauticalDawn, .nauticalDusk:
            zenith = 102.0
            if sunEvent == .nauticalDawn {
                approxTime = Double(dayOfYear) + ((6.0 - lngHour) / 24.0)
                isDawn = true
                isDusk = false
            } else {
                approxTime = Double(dayOfYear) + ((18.0 - lngHour) / 24.0)
                isDawn = false
                isDusk = true
            }
        case .astronomicalDawn, .astronomicalDusk:
            zenith = 108.0
            if sunEvent == .astronomicalDawn {
                approxTime = Double(dayOfYear) + ((6.0 - lngHour) / 24.0)
                isDawn = true
                isDusk = false
            } else {
                approxTime = Double(dayOfYear) + ((18.0 - lngHour) / 24.0)
                isDawn = false
                isDusk = true
            }
        case .solarNoon:
            zenith = 90.0
            approxTime = Double(dayOfYear) + ((12.0 - lngHour) / 24.0)
            isDawn = false
            isDusk = false
        }
        
        // Calculate the Sun's mean anomaly
        let M = (0.9856 * approxTime) - 3.289
        
        // Calculate the Sun's true longitude
        var L = M + (1.916 * sin(degreesToRadians(M))) + (0.020 * sin(2 * degreesToRadians(M))) + 282.634
        L = normalizeDegrees(L)
        
        // Calculate the Sun's right ascension
        var RA = radiansToDegrees(atan(0.91764 * tan(degreesToRadians(L))))
        RA = normalizeDegrees(RA)
        
        // Adjust RA to be in the same quadrant as L
        let Lquadrant = floor(L / 90.0) * 90.0
        let RAquadrant = floor(RA / 90.0) * 90.0
        RA = RA + (Lquadrant - RAquadrant)
        
        // Convert RA to hours
        RA /= 15.0
        
        // Calculate the Sun's declination
        let sinDec = 0.39782 * sin(degreesToRadians(L))
        let cosDec = cos(asin(sinDec))
        
        // Calculate the Sun's local hour angle
        let cosH = (cos(degreesToRadians(zenith)) - (sinDec * sin(degreesToRadians(location.latitude)))) / (cosDec * cos(degreesToRadians(location.latitude)))
        
        if cosH > 1 {
            // The sun never rises on this location (on the specified date)
            throw CalculationError.sunNeverRises
        } else if cosH < -1 {
            // The sun never sets on this location (on the specified date)
            throw CalculationError.sunNeverSets
        }
        
        var H: Double
        if isDawn {
            H = 360.0 - radiansToDegrees(acos(cosH))
        } else if isDusk {
            H = radiansToDegrees(acos(cosH))
        } else if sunEvent == .solarNoon {
            H = 0.0
        } else {
            H = radiansToDegrees(acos(cosH))
        }
        
        // Convert H to hours
        H /= 15.0
        
        // Calculate local mean time of the event
        let T = H + RA - (0.06571 * approxTime) - 6.622
        
        // Adjust back to UTC
        var UT = T - lngHour
        UT = normalizeHours(UT)
        
        // Calculate the local time
        let localTime = UT + Double(timeZone.secondsFromGMT(for: date)) / 3600.0
        
        // Convert UT to Date
        let sunTime = sunTimeFromComponents(date: date, hours: localTime)
        
        return sunTime
    }
    
    /// Calculates the sun's altitude and azimuth for a given time and location.
    /// - Parameters:
    ///   - date: The date and time for which to calculate the sun's position.
    ///   - location: The geographical location (latitude and longitude).
    /// - Returns: A SunPosition struct containing the sun's altitude and azimuth.
    /// - Throws: CalculationError if calculations cannot be performed.
    static func getSunPosition(date: Date, location: CLLocationCoordinate2D) throws -> SunPosition {
        // Reference: NOAA Solar Calculator
        // Simplified implementation based on standard solar position algorithms
        
        let calendar = Calendar.current
        let timeZone = TimeZone.current
        var dateComponents = calendar.dateComponents(in: timeZone, from: date)
        
        guard let year = dateComponents.year,
              let month = dateComponents.month,
              let day = dateComponents.day,
              let hour = dateComponents.hour,
              let minute = dateComponents.minute,
              let second = dateComponents.second else {
            throw CalculationError.invalidDate
        }
        
        // Calculate the day of the year
        let n = dayOfYear(year: year, month: month, day: day)
        
        // Convert longitude to hour value and calculate an approximate time
        let lngHour = location.longitude / 15.0
        
        // Calculate the fractional year in radians
        let gamma = 2.0 * Double.pi / 365.0 * (Double(n) - 1.0 + (Double(hour) - 12.0) / 24.0)
        
        // Equation of time in minutes
        let eqTime = 229.18 * (0.000075 + 0.001868 * cos(gamma) - 0.032077 * sin(gamma)
                                - 0.014615 * cos(2 * gamma) - 0.040849 * sin(2 * gamma))
        
        // Solar declination in radians
        let decl = 0.006918 - 0.399912 * cos(gamma) + 0.070257 * sin(gamma)
            - 0.006758 * cos(2 * gamma) + 0.000907 * sin(2 * gamma)
            - 0.002697 * cos(3 * gamma) + 0.00148 * sin(3 * gamma)
        
        // Time offset in hours
        let timeOffset = eqTime / 60.0
        
        // True solar time in decimal hours
        let tst = Double(hour) + Double(minute) / 60.0 + Double(second) / 3600.0 + timeOffset - lngHour
        
        // Hour angle in degrees
        var hourAngle = 15.0 * (tst - 12.0)
        if hourAngle < -180 {
            hourAngle += 360.0
        } else if hourAngle > 180 {
            hourAngle -= 360.0
        }
        let hourAngleRad = degreesToRadians(hourAngle)
        
        // Solar zenith angle in radians
        let latRad = degreesToRadians(location.latitude)
        let zenith = acos(sin(latRad) * sin(decl) + cos(latRad) * cos(decl) * cos(hourAngleRad))
        let zenithDeg = radiansToDegrees(zenith)
        
        // Solar elevation angle
        let altitude = 90.0 - zenithDeg
        
        // Calculate solar azimuth angle
        let azimuth = acos((sin(decl) * cos(latRad) - cos(decl) * sin(latRad) * cos(hourAngleRad)) / cos(zenith))
        var azimuthDeg = radiansToDegrees(azimuth)
        
        if hourAngle > 0 {
            azimuthDeg = 360.0 - azimuthDeg
        }
        
        // Handle cases where sun never rises or sets
        if zenithDeg < 90.0 && zenithDeg > -90.0 {
            return SunPosition(time: date, altitude: altitude, azimuth: azimuthDeg)
        } else if zenithDeg >= 90.0 {
            throw CalculationError.sunNeverRises
        } else {
            throw CalculationError.sunNeverSets
        }
    }
    
    /// Calculates the length of the day (time between sunrise and sunset).
    /// - Parameters:
    ///   - date: The date for which to calculate the day length.
    ///   - location: The geographical location (latitude and longitude).
    /// - Returns: The length of the day in seconds.
    /// - Throws: CalculationError if the sun never rises or sets.
    static func calculateDayLength(date: Date, location: CLLocationCoordinate2D) throws -> TimeInterval {
        let sunrise = try getSunTime(date: date, sunEvent: .sunrise, location: location)
        let sunset = try getSunTime(date: date, sunEvent: .sunset, location: location)
        return sunset.timeIntervalSince(sunrise)
    }
    
    /// Calculates the next occurrence of a specific sun event if the current one has passed.
    /// - Parameters:
    ///   - date: The current date.
    ///   - sunEvent: The sun event to calculate.
    ///   - location: The geographical location.
    /// - Returns: The next date and time of the sun event.
    /// - Throws: CalculationError if the sun never rises or sets.
    static func getNextSunTime(after date: Date, sunEvent: SunEvent, location: CLLocationCoordinate2D) throws -> Date {
        var targetDate = date
        var sunTime: Date?
        
        // Loop until we find a sunTime that is after the current date
        for _ in 0..<365 { // Prevent infinite loops; limit to 1 year ahead
            targetDate = Calendar.current.date(byAdding: .day, value: 1, to: targetDate)!
            do {
                sunTime = try getSunTime(date: targetDate, sunEvent: sunEvent, location: location)
                if sunTime! > date {
                    return sunTime!
                }
            } catch {
                // If the sun never rises/sets on this date, skip to next day
                // Alternatively, handle differently based on requirements
                // For simplicity, we'll skip to next day
            }
        }
        
        throw CalculationError.sunNeverRises // Or sunNeverSets based on context
    }
    
    // MARK: - Helper Functions
    
    /// Converts degrees to radians.
    private static func degreesToRadians(_ degrees: Double) -> Double {
        return degrees * .pi / 180.0
    }
    
    /// Converts radians to degrees.
    private static func radiansToDegrees(_ radians: Double) -> Double {
        return radians * 180.0 / .pi
    }
    
    /// Normalizes degrees to be within [0, 360).
    private static func normalizeDegrees(_ degrees: Double) -> Double {
        var deg = degrees
        while deg < 0 { deg += 360 }
        while deg >= 360 { deg -= 360 }
        return deg
    }
    
    /// Normalizes hours to be within [0, 24).
    private static func normalizeHours(_ hours: Double) -> Double {
        var hr = hours
        while hr < 0 { hr += 24 }
        while hr >= 24 { hr -= 24 }
        return hr
    }
    
    /// Creates a Date object from date and fractional hours.
    private static func sunTimeFromComponents(date: Date, hours: Double) -> Date {
        let calendar = Calendar.current
        let hour = Int(hours)
        let minute = Int((hours - Double(hour)) * 60)
        let second = Int((((hours - Double(hour)) * 60) - Double(minute)) * 60)
        
        var components = calendar.dateComponents(in: TimeZone.current, from: date)
        components.hour = hour
        components.minute = minute
        components.second = second
        
        // Handle cases where components might be out of bounds
        if let sunDate = calendar.date(from: components) {
            return sunDate
        } else {
            // Fallback to date at noon if conversion fails
            return date
        }
    }
    
    /// Calculates the day of the year.
    /// - Parameters:
    ///   - year: The year component of the date.
    ///   - month: The month component of the date.
    ///   - day: The day component of the date.
    /// - Returns: The ordinal day of the year (1...366).
    private static func dayOfYear(year: Int, month: Int, day: Int) -> Int {
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        let calendar = Calendar(identifier: .gregorian)
        guard let date = calendar.date(from: dateComponents) else { return 1 }
        return calendar.ordinality(of: .day, in: .year, for: date) ?? 1
    }
}
