//
//  MapSelectionView.swift
//  Odbrojavanje
//
//  Created by Vedran Rodic on 06.12.2024..
//

import SwiftUI
import MapKit

struct MapSelectionView: View {
    @Binding var selectedCoordinate: CLLocationCoordinate2D
    @Environment(\.presentationMode) var presentationMode
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 45.8150, longitude: 15.9819),
        span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
    )
    
    @State private var annotation: MKPointAnnotation?
    
    var body: some View {
        VStack {
            Map(coordinateRegion: $region, annotationItems: [SelectableLocation(coordinate: selectedCoordinate)]) { location in
                MapMarker(coordinate: location.coordinate, tint: .red)
            }
            .onTapGesture { location in
                // Implement tap to set location if needed
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        let location = value.location
                        let coordinate = convertToCoordinate(location: location, in: region)
                        selectedCoordinate = coordinate
                        presentationMode.wrappedValue.dismiss()
                    }
            )
            .frame(height: 400)
            
            Button("Select This Location") {
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
        }
    }
    
    private func convertToCoordinate(location: CGPoint, in region: MKCoordinateRegion) -> CLLocationCoordinate2D {
        let mapWidth = UIScreen.main.bounds.width
        let mapHeight: CGFloat = 400
        let xRatio = location.x / mapWidth
        let yRatio = location.y / mapHeight
        
        let deltaLat = region.span.latitudeDelta
        let deltaLon = region.span.longitudeDelta
        
        let latitude = region.center.latitude + (Double(1 - yRatio) - 0.5) * deltaLat
        let longitude = region.center.longitude + (Double(xRatio) - 0.5) * deltaLon
        
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct SelectableLocation: Identifiable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
}
