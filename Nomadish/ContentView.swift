//
//  ContentView.swift
//  Nomadish
//
//  Created by Riddhi Munjewar on 5/26/25.
//


import SwiftUI
import MapKit

struct ContentView: View {
    
    // MARK: - State Properties
    
    // The camera position for the map. Starts centered on the user's location.
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    
    // The managers that provide data and services to the view
    @StateObject private var memoryManager = MemoryManager()
    @StateObject private var locationManager = LocationManager()
    
    // State for managing which sheet (detail, add new) is shown
    @State private var selectedMemory: FoodMemory?
    @State private var newPinCoordinate: CLLocationCoordinate2D?
    @State private var isShowingAddMemorySheet = false
    
    // State for the search functionality
    @State private var searchText = ""
    @State private var showingSearchAlert = false
    
    // Computed property to drive the detail sheet presentation
    private var isShowingMemoryDetailSheet: Binding<Bool> {
        Binding(
            get: { selectedMemory != nil },
            set: { isShowing in
                if !isShowing {
                    selectedMemory = nil
                }
            }
        )
    }

    // MARK: - Body
    
    var body: some View {
        NavigationStack { // Use NavigationStack for modern navigation
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    TextField("Search for a place...", text: $searchText)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .onSubmit(searchForLocation) // Allow searching from keyboard
                    
                    Button(action: searchForLocation) {
                        Image(systemName: "magnifyingglass")
                            .padding()
                    }
                }
                .padding(.horizontal)
                
                // The main map view
                MapReader { proxy in
                    Map(position: $position) {
                        // Shows the user's current location with a blue dot
                        UserAnnotation()
                        
                        // Loop through all the food memories and place them on the map
                        ForEach(memoryManager.foodMemories) { memory in
                            Annotation(memory.name, coordinate: memory.coordinate) {
                                // Tappable annotation view
                                Button(action: { selectedMemory = memory }) {
                                    VStack(spacing: 2) {
                                        Image(systemName: "fork.knife.circle.fill")
                                            .font(.title)
                                            .foregroundColor(.white)
                                            .background(Color.purple)
                                            .clipShape(Circle())
                                            .shadow(radius: 3)
                                        Text(memory.name)
                                            .font(.caption)
                                            .bold()
                                            .foregroundColor(.black)
                                            .padding(4)
                                            .background(.white.opacity(0.8))
                                            .cornerRadius(5)
                                    }
                                }
                            }
                        }
                    }
                    // This gesture allows the user to tap anywhere on the map to add a new pin
                    .onTapGesture { screenCoord in
                        if let mapCoord = proxy.convert(screenCoord, from: .local) {
                            newPinCoordinate = mapCoord
                            isShowingAddMemorySheet = true
                        }
                    }
                }
            }
            .navigationTitle("Nomadish 🗺️")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Button to re-center the map on the user
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: centerMapOnUserLocation) {
                        Image(systemName: "location.fill")
                    }
                }
            }
            // Sheet for adding a new memory
            .sheet(isPresented: $isShowingAddMemorySheet) {
                // We must unwrap the optional coordinate
                if let coordinate = newPinCoordinate {
                    AddMemoryView(
                        coordinate: coordinate,
                        onSave: { newMemory in
                            memoryManager.addMemory(newMemory)
                            isShowingAddMemorySheet = false
                        },
                        onCancel: {
                            isShowingAddMemorySheet = false
                        }
                    )
                }
            }
            // Sheet for showing the details of an existing memory
            .sheet(isPresented: isShowingMemoryDetailSheet) {
                if let memory = selectedMemory {
                    MemoryDetailView(memory: memory) {
                        memoryManager.deleteMemory(memory)
                        selectedMemory = nil // This will dismiss the sheet
                    }
                }
            }
            // Alert for when a search yields no results
            .alert("Location Not Found", isPresented: $showingSearchAlert) {
                Button("OK") {}
            } message: {
                Text("Could not find a location for '\(searchText)'. Please try another.")
            }
        }
    }
    
    // MARK: - Functions
    
    /// Uses MKLocalSearch to find a location from the search text and moves the map there.
    private func searchForLocation() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let mapItem = response?.mapItems.first else {
                showingSearchAlert = true
                return
            }
            
            withAnimation {
                position = .region(MKCoordinateRegion(
                    center: mapItem.placemark.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                ))
            }
        }
    }
    
    /// Animates the map back to the user's current location.
    private func centerMapOnUserLocation() {
        withAnimation {
            position = .userLocation(fallback: .automatic)
        }
    }
}

#Preview {
    ContentView()
}
