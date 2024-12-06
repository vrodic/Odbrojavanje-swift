// CountdownViewModel.swift

import Foundation
import Combine
import CoreLocation

class CountdownViewModel: ObservableObject {
    @Published var currentTime: Date = Date()
    @Published var targetDate: Date = Date()
    @Published var remainingTime: String = "Invalid date or time"
    @Published var progress: Double = 0.0
    @Published var alertMessage: String? = nil // For Approach 1 (optional)
    
    private var timer: AnyCancellable?
    private var startTime: Date = Date()
    private var intervalMilliseconds: Double = 0.0167 // ~60Hz
    
    init() {
        startTimer()
    }
    
    /// Starts the countdown timer with high-frequency updates.
    func startTimer() {
        timer = Timer.publish(every: intervalMilliseconds, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] now in
                self?.updateTime(now: now)
            }
    }
    
    /// Stops the countdown timer.
    func stopTimer() {
        timer?.cancel()
    }
    
    /// Updates the current time, calculates remaining time, and updates progress.
    /// - Parameter now: The current date and time.
    private func updateTime(now: Date) {
        currentTime = now
        
        if targetDate <= now {
            remainingTime = "Time is up!"
            progress = 1.0
            stopTimer()
            return
        }
        
        let interval = targetDate.timeIntervalSince(startTime)
        let progressValue = now.timeIntervalSince(startTime) / interval
        progress = min(max(progressValue, 0.0), 1.0)
        
        let remaining = targetDate.timeIntervalSince(now)
        remainingTime = formatTimeInterval(remaining)
        
        // Optional: Implement logging or additional functionality here.
    }
    
    /// Formats the remaining time interval into a string with milliseconds.
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let ti = Int(interval)
        let milliseconds = Int((interval - Double(ti)) * 1000)
        let seconds = ti % 60
        let minutes = (ti / 60) % 60
        let hours = (ti / 3600) % 24
        let days = ti / 86400
        
        var components: [String] = []
        if days > 0 { components.append("\(days)d") }
        if hours > 0 { components.append("\(hours)h") }
        if minutes > 0 { components.append("\(minutes)m") }
        
        // Format: HH:MM:SS.mmm
        let timeString = String(format: "%02d:%02d:%02d.%03d", hours, minutes, seconds, milliseconds)
        
        if !components.isEmpty {
            return components.joined(separator: " ") + " " + timeString
        } else {
            return timeString
        }
    }
    
    /// Updates the timer interval in milliseconds.
    /// - Parameter milliseconds: The new interval in milliseconds.
    func updateInterval(milliseconds: Double) {
        intervalMilliseconds = milliseconds
        stopTimer()
        startTimer()
    }
    
    /// Sets the target date based on the selected sun event and location.
    /// - Parameters:
    ///   - sunEvent: The selected sun event.
    ///   - location: The selected location.
    func setTargetDate(sunEvent: SunEvent, location: CLLocationCoordinate2D) {
        let now = Date()
        do {
            // Attempt to get the sun time for the selected date
            let sunTime = try SunCalculator.getSunTime(date: targetDate, sunEvent: sunEvent, location: location)
            
            if sunTime > now {
                // Event is in the future; set as target date
                targetDate = sunTime
            } else {
                // Event has already passed; get the next occurrence
                let nextSunTime = try SunCalculator.getNextSunTime(after: now, sunEvent: sunEvent, location: location)
                targetDate = nextSunTime
                
                // Optionally, notify the user (Approach 1)
                /*
                alertMessage = "The selected sun event has already passed. Countdown has been set to the next occurrence."
                */
            }
        } catch SunCalculator.CalculationError.sunNeverRises {
            remainingTime = "Sun never rises on this date/location."
            targetDate = now
            stopTimer()
        } catch SunCalculator.CalculationError.sunNeverSets {
            remainingTime = "Sun never sets on this date/location."
            targetDate = now
            stopTimer()
        } catch {
            remainingTime = "Error calculating sun time."
            targetDate = now
            stopTimer()
        }
    }
}
