// SunEvent.swift

import Foundation

enum SunEvent: String, CaseIterable, Identifiable {
    case sunrise
    case sunset
    case civilDawn
    case civilDusk
    case nauticalDawn
    case nauticalDusk
    case astronomicalDawn
    case astronomicalDusk
    case solarNoon
    
    var id: String { self.rawValue }
    
    var name: String {
        switch self {
        case .sunrise:
            return "Sunrise"
        case .sunset:
            return "Sunset"
        case .civilDawn:
            return "Civil Dawn"
        case .civilDusk:
            return "Civil Dusk"
        case .nauticalDawn:
            return "Nautical Dawn"
        case .nauticalDusk:
            return "Nautical Dusk"
        case .astronomicalDawn:
            return "Astronomical Dawn"
        case .astronomicalDusk:
            return "Astronomical Dusk"
        case .solarNoon:
            return "Solar Noon"
        }
    }
}
