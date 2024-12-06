// SunPosition.swift

import Foundation

struct SunPosition: Identifiable {
    let id = UUID()
    let time: Date
    let altitude: Double // in degrees
    let azimuth: Double  // in degrees
}
