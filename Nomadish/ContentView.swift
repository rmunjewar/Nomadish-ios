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
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
        
    // Use the new ViewModel instead of MemoryManager
    @StateObject private var viewModel = MemoriesViewModel()
    @StateObject private var locationManager = LocationManager()
    
    @State private var selectedMemory: FoodMemory?
    @State private var newPinCoordinate: CLLocationCoordinate2D?
    @State private var isShowingAddMemorySheet = false
    @State private var isShowingSettings = false
    @State private var selectedTab = 0
    
    @State private var searchText = ""
    @State private var showingSearchAlert = false
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    
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
        TabView(selection: $selectedTab) {
            // Map Tab
            mapTab
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("Map")
                }
                .tag(0)
            
            // Memories Tab
            memoriesTab
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Memories")
                }
                .tag(1)
            
            // Stats Tab
            statsTab
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Stats")
                }
                .tag(2)
        }
        .accentColor(.purple)
        .sheet(isPresented: $isShowingAddMemorySheet) {
            if let coordinate = newPinCoordinate {
                AddMemoryView(
                    coordinate: coordinate,
                    onSave: { newMemory, photo in
                        guard let photo = photo else { return }
                        
                        Task {
                            await viewModel.addMemory(newMemory, photo: photo)
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
                    Task {
                        await viewModel.deleteMemory(memory)
                    }
                    selectedMemory = nil
                }
            }
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsView()
        }
        .alert("Location Not Found", isPresented: $showingSearchAlert, actions: { Button("OK") {} }, message: { Text("Could not find a location for '\(searchText)'.") })
        .task {
            await viewModel.fetchMemories()
        }
    }
    
    // MARK: - Map Tab
    
    private var mapTab: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    // Enhanced Search Bar with Results
                    VStack(spacing: 0) {
                        HStack {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                TextField("Search for restaurants, cafes...", text: $searchText)
                                    .onChange(of: searchText) { _ in
                                        if searchText.count > 2 {
                                            searchForLocation()
                                        }
                                    }
                                if !searchText.isEmpty {
                                    Button(action: { searchText = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(15)
                        }
                        .padding(.horizontal)
                        
                        // Search Results Dropdown
                        if !searchResults.isEmpty && !searchText.isEmpty {
                            ScrollView {
                                LazyVStack(spacing: 0) {
                                    ForEach(searchResults, id: \.self) { item in
                                        Button(action: {
                                            selectSearchResult(item)
                                        }) {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(item.name ?? "Unknown Location")
                                                        .font(.headline)
                                                        .foregroundColor(.primary)
                                                    if let locality = item.placemark.locality {
                                                        Text(locality)
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                    }
                                                }
                                                Spacer()
                                                Image(systemName: "location.fill")
                                                    .foregroundColor(.blue)
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                        }
                                        .buttonStyle(.plain)
                                        .background(Color(.systemBackground))
                                        
                                        if item != searchResults.last {
                                            Divider()
                                                .padding(.leading, 16)
                                        }
                                    }
                                }
                            }
                            .background(Color(.systemBackground))
                            .cornerRadius(15)
                            .shadow(radius: 5)
                            .padding(.horizontal)
                            .frame(maxHeight: 200)
                        }
                    }
                    .background(Color(.systemBackground))
                    .zIndex(1)
                    
                    // Enhanced Map View
                    MapReader { proxy in
                        Map(position: $position, interactionModes: .all) {
                            UserAnnotation()
                            
                            ForEach(viewModel.foodMemories) { memory in
                                Annotation(memory.name, coordinate: memory.coordinate) {
                                    Button(action: { selectedMemory = memory }) {
                                        VStack(spacing: 2) {
                                            Image(systemName: "fork.knife.circle.fill")
                                                .font(.title2)
                                                .foregroundColor(.white)
                                                .background(Color.purple)
                                                .clipShape(Circle())
                                                .shadow(radius: 3)
                                            Text(memory.name)
                                                .font(.caption2).bold()
                                                .foregroundColor(.black)
                                                .padding(4)
                                                .background(.white.opacity(0.9))
                                                .cornerRadius(8)
                                                .shadow(radius: 1)
                                        }
                                    }
                                }
                            }
                        }
                        .mapStyle(.standard(elevation: .realistic))
                        .onTapGesture { screenCoord in
                            if let mapCoord = proxy.convert(screenCoord, from: .local) {
                                newPinCoordinate = mapCoord
                                isShowingAddMemorySheet = true
                            }
                        }
                        .onMapCameraChange { context in
                            mapRegion = context.region
                        }
                    }
                    
                    // Map Control Buttons
                    VStack {
                        HStack {
                            Spacer()
                            VStack(spacing: 12) {
                                // Zoom In Button
                                Button(action: zoomIn) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .frame(width: 44, height: 44)
                                        .background(Color.blue)
                                        .clipShape(Circle())
                                        .shadow(radius: 3)
                                }
                                
                                // Zoom Out Button
                                Button(action: zoomOut) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .frame(width: 44, height: 44)
                                        .background(Color.blue)
                                        .clipShape(Circle())
                                        .shadow(radius: 3)
                                }
                                
                                // Center on User Button
                                Button(action: centerMapOnUserLocation) {
                                    Image(systemName: "location.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .frame(width: 44, height: 44)
                                        .background(Color.green)
                                        .clipShape(Circle())
                                        .shadow(radius: 3)
                                }
                            }
                            .padding(.trailing, 16)
                        }
                        Spacer()
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
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: { isShowingAddMemorySheet = true }) {
                            Image(systemName: "plus.circle.fill")
                        }
                        
                        Button(action: { isShowingSettings = true }) {
                            Image(systemName: "gearshape.fill")
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Memories Tab
    
    private var memoriesTab: some View {
        NavigationStack {
            List {
                ForEach(viewModel.foodMemories) { memory in
                    MemoryRowView(memory: memory) {
                        selectedMemory = memory
                    }
                }
            }
            .navigationTitle("Food Memories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isShowingAddMemorySheet = true }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
        }
    }
    
    // MARK: - Stats Tab
    
    private var statsTab: some View {
        NavigationStack {
            StatsView(memories: viewModel.foodMemories)
                .navigationTitle("Statistics")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Functions
    
    private func searchForLocation() {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.resultTypes = [.pointOfInterest, .address]
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            isSearching = false
            
            if let error = error {
                print("Search error: \(error)")
                showingSearchAlert = true
                return
            }
            
            searchResults = response?.mapItems ?? []
        }
    }
    
    private func selectSearchResult(_ item: MKMapItem) {
        let coordinate = item.placemark.coordinate
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        
        withAnimation(.easeInOut(duration: 0.5)) {
            position = .region(region)
        }
        
        searchText = item.name ?? ""
        searchResults.removeAll()
    }
    
    private func zoomIn() {
        let newSpan = MKCoordinateSpan(
            latitudeDelta: mapRegion.span.latitudeDelta * 0.5,
            longitudeDelta: mapRegion.span.longitudeDelta * 0.5
        )
        let newRegion = MKCoordinateRegion(center: mapRegion.center, span: newSpan)
        
        withAnimation(.easeInOut(duration: 0.3)) {
            position = .region(newRegion)
        }
    }
    
    private func zoomOut() {
        let newSpan = MKCoordinateSpan(
            latitudeDelta: mapRegion.span.latitudeDelta * 2.0,
            longitudeDelta: mapRegion.span.longitudeDelta * 2.0
        )
        let newRegion = MKCoordinateRegion(center: mapRegion.center, span: newSpan)
        
        withAnimation(.easeInOut(duration: 0.3)) {
            position = .region(newRegion)
        }
    }
    
    /// Animates the map back to the user's current location.
    private func centerMapOnUserLocation() {
        withAnimation(.easeInOut(duration: 0.5)) {
            position = .userLocation(fallback: .automatic)
        }
    }
}

// MARK: - Memory Row View

struct MemoryRowView: View {
    let memory: FoodMemory
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Photo thumbnail
                if let photo = memory.photo {
                    Image(uiImage: photo)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipped()
                        .cornerRadius(8)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .foregroundColor(.gray)
                        )
                }
                
                // Memory details
                VStack(alignment: .leading, spacing: 4) {
                    Text(memory.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(memory.dateAdded.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= memory.rating ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundColor(star <= memory.rating ? .yellow : .gray)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
        }
    }


#Preview {
    ContentView()
}
