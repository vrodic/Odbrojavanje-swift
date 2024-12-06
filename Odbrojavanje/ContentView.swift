// ContentView.swift

import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var countdownVM = CountdownViewModel()
    @StateObject private var mapVM = MapViewModel()
    
    @State private var selectedSunEvent: SunEvent = .sunrise
    @State private var showMap = false
    @State private var showSunGraph = false
    
    // For Approach 1: Alert
    @State private var showAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Sun Event Picker using MenuPickerStyle
                    Picker("Sun Event", selection: $selectedSunEvent) {
                        ForEach(SunEvent.allCases) { event in
                            Text(event.name).tag(event)
                        }
                    }
                    .pickerStyle(MenuPickerStyle()) // Changed from SegmentedPickerStyle to MenuPickerStyle
                    .padding()
                    .onChange(of: selectedSunEvent) { _ in
                        updateSunTime()
                    }
                    
                    // Date and Time Picker
                    DatePicker("Select Date and Time", selection: $countdownVM.targetDate, displayedComponents: [.date, .hourAndMinute])
                        .padding()
                        .onChange(of: countdownVM.targetDate) { _ in
                            updateSunTime()
                        }
                    
                    // Countdown Display
                    Text("Countdown: \(countdownVM.remainingTime)")
                        .font(.largeTitle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding() 
                    
                    // Progress Bar
                    ProgressView(value: countdownVM.progress)
                        .padding()
                    
                    // Map View Button
                    Button(action: {
                        showMap.toggle()
                    }) {
                        Text("Select Location")
                            .foregroundColor(.blue)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .sheet(isPresented: $showMap) {
                        MapSelectionView(selectedCoordinate: $mapVM.selectedCoordinate)
                    }
                    
                    // Sun Graph Button
                    Button(action: {
                        showSunGraph.toggle()
                    }) {
                        Text("Show Sun Graph")
                            .foregroundColor(.blue)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .sheet(isPresented: $showSunGraph) {
                        // Updated Initializer Call
                        SunGraphView(year: Calendar.current.component(.year, from: countdownVM.targetDate), location: mapVM.selectedCoordinate)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Odbrojavanje")
            .onAppear {
                updateSunTime()
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Sun Event Passed"),
                      message: Text("The selected sun event has already occurred. Countdown has been set to the next occurrence."),
                      dismissButton: .default(Text("OK")))
            }
        }
    }
    
    /// Updates the targetDate based on the selected sun event and location.
    private func updateSunTime() {
        countdownVM.setTargetDate(sunEvent: selectedSunEvent, location: mapVM.selectedCoordinate)
        
        // For Approach 1: Notify the user if the event has passed
        /*
        if let message = countdownVM.alertMessage {
            showAlert = true
        }
        */
    }
}
