// MapViewModel.swift

import Foundation
import Combine
import MapKit
import CoreLocation // Add this import

class MapViewModel: ObservableObject {
    @Published var worldMap: WorldMap = []
    @Published var selectedCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 45.8150, longitude: 15.9819) // Zagreb
    
    init() {
        loadWorldMapData()
    }
    
    func loadWorldMapData() {
        // Load GeoJSON
        guard let url = Bundle.main.url(forResource: "world", withExtension: "geo.json") else {
            print("GeoJSON file not found.")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let geoJSON = try decoder.decode(GeoJSONFeatureCollection.self, from: data)
            var countries: WorldMap = []
            
            for feature in geoJSON.features {
                let countryName = feature.properties.name
                var polygons: [Polygon] = []
                
                switch feature.geometry.coordinates {
                case .polygon(let coords):
                    let polygon = Polygon(coordinates: coords.map { coord in
                        Coordinate(latitude: coord[1], longitude: coord[0])
                    })
                    polygons.append(polygon)
                case .multiPolygon(let multiCoords):
                    for coords in multiCoords {
                        let polygon = Polygon(coordinates: coords.map { coord in
                            Coordinate(latitude: coord[1], longitude: coord[0])
                        })
                        polygons.append(polygon)
                    }
                }
                
                let country = Country(name: countryName, polygons: polygons)
                countries.append(country)
            }
            
            self.worldMap = countries
        } catch {
            print("Error loading GeoJSON: \(error)")
        }
    }
}
