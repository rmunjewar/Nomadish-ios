//
//  ContentView.swift
//  Nomadish
//
//  Created by Riddhi Munjewar on 5/26/25.
//


import SwiftUI
import MapKit

struct ContentView: View {
    
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
        
    // Use the new ViewModel instead of MemoryManager
    @StateObject private var viewModel = MemoriesViewModel()
    @StateObject private var locationManager = LocationManager()
    
    @State private var selectedMemory: FoodMemory?
    @State private var newPinCoordinate: CLLocationCoordinate2D?
    @State private var isShowingAddMemorySheet = false
    
    @State private var searchText = ""
    @State private var showingSearchAlert = false
    
    private var isShowingMemoryDetailSheet: Binding<Bool> {
        Binding(
            get: { selectedMemory != nil },
            set: { isShowing in
                if !isShowing { selectedMemory = nil }
            }
        )
    }

    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack { // Use a ZStack to overlay the loading view
                VStack(spacing: 0) {
                    // Search Bar (no changes)
                    HStack {
                        TextField("Search for a place...", text: $searchText)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .onSubmit(searchForLocation)
                        
                        Button(action: searchForLocation) {
                            Image(systemName: "magnifyingglass").padding()
                        }
                    }
                    .padding(.horizontal)
                    
                    // The main map view (use viewModel.foodMemories)
                    MapReader { proxy in
                        Map(position: $position) {
                            UserAnnotation()
                            
                            ForEach(viewModel.foodMemories) { memory in // Changed here
                                Annotation(memory.name, coordinate: memory.coordinate) {
                                    Button(action: { selectedMemory = memory }) {
                                        VStack(spacing: 2) {
                                            Image(systemName: "fork.knife.circle.fill")
                                                .font(.title)
                                                .foregroundColor(.white)
                                                .background(Color.purple)
                                                .clipShape(Circle())
                                                .shadow(radius: 3)
                                            Text(memory.name)
                                                .font(.caption).bold().foregroundColor(.black)
                                                .padding(4).background(.white.opacity(0.8))
                                                .cornerRadius(5)
                                        }
                                    }
                                }
                            }
                        }
                        .onTapGesture { screenCoord in
                            if let mapCoord = proxy.convert(screenCoord, from: .local) {
                                newPinCoordinate = mapCoord
                                isShowingAddMemorySheet = true
                            }
                        }
                    }
                }
                
                // Show a loading overlay when the ViewModel is busy
                if viewModel.isLoading {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    ProgressView("Working...")
                        .tint(.white)
                        .scaleEffect(1.5)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                }
            }
            .navigationTitle("Nomadish 🗺️")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: centerMapOnUserLocation) {
                        Image(systemName: "location.fill")
                    }
                }
            }
            .sheet(isPresented: $isShowingAddMemorySheet) {
                if let coordinate = newPinCoordinate {
                    // We need a new onSave closure that provides both the memory AND the photo
                    AddMemoryView(
                        coordinate: coordinate,
                        onSave: { newMemory, photo in // <-- CHANGE THIS CLOSURE
                            // Make sure we have a photo to upload
                            guard let photo = photo else { return }
                            
                            Task {
                                // Pass both the memory and photo to the view model
                                await viewModel.addMemory(newMemory, photo: photo) // <-- CHANGE THIS CALL
                            }
                            isShowingAddMemorySheet = false
                        },
                        onCancel: { isShowingAddMemorySheet = false }
                    )
                }
            }
            .sheet(isPresented: isShowingMemoryDetailSheet) {
                if let memory = selectedMemory {
                    MemoryDetailView(memory: memory) {
                        // Call the async deleteMemory function
                        Task {
                            await viewModel.deleteMemory(memory)
                        }
                        selectedMemory = nil
                    }
                }
            }
            .alert("Location Not Found", isPresented: $showingSearchAlert, actions: { Button("OK") {} }, message: { Text("Could not find a location for '\(searchText)'.") })
            .task {
                // .task is the modern way to call an async function when a view appears.
                await viewModel.fetchMemories()
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
