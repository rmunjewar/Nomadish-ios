//
//  ContentView.swift
//  Nomadish
//
//  Created by Riddhi Munjewar on 5/26/25.
//

import SwiftUI
import MapKit

struct FoodMemory: Identifiable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
    var name: String
}

struct ContentView: View {
    
    // defining the map region
    @State private var position = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // defining where
            span: MKCoordinateSpan(latitudeDelta: 0.07, longitudeDelta: 0.07) // defining how zoomed in
        )
    )
    
    @State private var foodMemories: [FoodMemory] = []
    @State private var showingAddMemory = false
    @State private var newPinCoordinate: CLLocationCoordinate2D?
    
    
    @State private var searchText = ""
    
    var body: some View {
        VStack {
            HStack {
                TextField("Have a place in mind?", text: $searchText)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                
                Button(action: {
                    searchForLocation()
                }) {
                    Image(systemName: "magnifyingglass")
                        .padding()
                }
            }
            .padding()
            
            // display the map
            Map(position: $position) {
                ForEach(foodMemories) { memory in
                    
                    Annotation(memory.name, coordinate: memory.coordinate) {
                        Button(action: {
                                                    // TODO: Show memory details when tapped
                                                    print("Tapped memory: \(memory.name)")
                                                }) {
                            Image(systemName: "fork.knife.circle.fill")
                                .foregroundColor(.purple)
                                .font(.title2)
                        }
                    
                    }
                    
                }
                
            }
            .ignoresSafeArea() // fills the entire screen
            .onTapGesture { location in
                // Convert tap location to coordinate
                addFoodMemoryAt(tapLocation: location)
            }
        }
        .sheet(isPresented: $showingAddMemory) {
            AddMemoryView(
                coordinate: newPinCoordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0),
                onSave: { memory in
                    foodMemories.append(memory)
                    showingAddMemory = false
                },
                onCancel: {
                    showingAddMemory = false
                }
            )
        }
    }
    
    func searchForLocation() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        
        let search = MKLocalSearch(request: request)
        // search is seidng a request to apple's servers, and runs block when finished
        search.start { response, error in // gblock ives response and error
            guard let coordinate =
                    // response might be nil so ? to access safely
                    // .mapItems.first gets first search result
                    // .placemark.coordinate gets actual location
                    // guard let ... else is if any part is missing, exit early (need this value to exist else can't continue
                    
                    response?.mapItems.first?.placemark.coordinate else {
                print("No results found.")
                return
            }
            
            withAnimation {
                position = .region(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.7, longitudeDelta: 0.7)))
            }
        }
    }
    
    func addFoodMemoryAt(tapLocation: CGPoint) {
            // For now, we'll use a simple approach - when user taps, we'll prompt them
            // In a real implementation, you'd convert the tap location to a coordinate
            // This is a simplified version that adds a pin at the current map center
            let centerCoordinate = getCenterCoordinate()
            newPinCoordinate = centerCoordinate
            showingAddMemory = true
        }
        
        func getCenterCoordinate() -> CLLocationCoordinate2D {
            // Get the center of the current map view
            // This is a simplified approach - in practice you'd want to get the actual center
            return CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        }
}

// new view for adding memeory

struct AddMemoryView: View {
    let coordinate: CLLocationCoordinate2D
    let onSave: (FoodMemory) -> Void
    let onCancel: () -> Void
    
    @State private var memoryName = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Add Food Memory")
                    .font(.title2)
                    .fontWeight(.bold)
                TextField("What are the yum eats?", text: $memoryName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                Text("Location: \(coordinate.latitude, specifier: "%.4f"), \(coordinate.longitude, specifier: "%.4f")")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                Spacer()
                
                HStack {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(.red)
                    
                    Spacer()
                    
                    Button("Save") {
                        if !memoryName.isEmpty {
                            let memory = FoodMemory(coordinate: coordinate, name: memoryName)
                            onSave(memory)
                        }
                    }
                    .foregroundColor(.blue)
                    .disabled(memoryName.isEmpty)
                                    }
                                    .padding()
                                }
                                .padding()
                            }
                        }
                    }

                    #Preview {
                        ContentView()
                    }

