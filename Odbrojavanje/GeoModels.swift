// GeoModels.swift

import Foundation
import CoreLocation

struct Coordinate: Codable {
    var latitude: Double
    var longitude: Double
}

struct Polygon: Codable {
    var coordinates: [Coordinate]
}

struct Country: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var polygons: [Polygon]
}

typealias WorldMap = [Country]

// GeoJSON Structures

struct GeoJSONFeatureCollection: Codable {
    let type: String
    let features: [GeoJSONFeature]
}

struct GeoJSONFeature: Codable {
    let type: String
    let properties: GeoJSONProperties
    let geometry: GeoJSONGeometry
}

struct GeoJSONProperties: Codable {
    let name: String
}

enum GeometryType: String, Codable {
    case polygon = "Polygon"
    case multiPolygon = "MultiPolygon"
}

enum GeoJSONGeometryCoordinates: Codable {
    case polygon([[Double]])
    case multiPolygon([[[Double]]])
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        // Try to decode MultiPolygon first
        if let multiPolygon = try? container.decode([[[Double]]].self) {
            self = .multiPolygon(multiPolygon)
            return
        }
        // Then try Polygon
        if let polygon = try? container.decode([[Double]].self) {
            self = .polygon(polygon)
            return
        }
        throw DecodingError.typeMismatch(GeoJSONGeometryCoordinates.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for geometry coordinates"))
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .multiPolygon(let multiPolygon):
            try container.encode(multiPolygon)
        case .polygon(let polygon):
            try container.encode(polygon)
        }
    }
}

struct GeoJSONGeometry: Codable {
    let type: GeometryType
    let coordinates: GeoJSONGeometryCoordinates
}
