//
//  ContentView.swift
//  Nomadish
//
//  Created by Riddhi Munjewar on 5/26/25.
//

import SwiftUI
import MapKit

// MARK: - Data Models

// Model representing a food memory with location, photo, and metadata
struct FoodMemory: Identifiable {
    let id: UUID // Fixed: was "let id = UUID" - needs to be a type, not a function call
    var coordinate: CLLocationCoordinate2D // GPS coordinates of the memory
    var name: String // Name/description of the food
    var photo: UIImage? // Optional photo of the food
    var dateAdded: Date // When the memory was created
    var notes: String // Personal notes about the experience
    var rating: Int // Rating from 1-5 stars
    
    // Initializer for creating new memories
    init(coordinate: CLLocationCoordinate2D, name: String, photo: UIImage?, dateAdded: Date, notes: String = "", rating: Int = 3) {
        self.id = UUID() // Fixed: Generate new UUID instance
        self.coordinate = coordinate
        self.name = name
        self.photo = photo
        self.dateAdded = dateAdded
        self.notes = notes // Fixed: was assigning notes to itself
        self.rating = rating // Fixed: was assigning rating to itself
    }
    
    // Initializer for loading from saved data (preserves existing ID)
    init(id: UUID, coordinate: CLLocationCoordinate2D, name: String, photo: UIImage?, dateAdded: Date, notes: String = "", rating: Int = 3) {
        self.id = id // Use existing ID
        self.coordinate = coordinate
        self.name = name
        self.photo = photo
        self.dateAdded = dateAdded
        self.notes = notes
        self.rating = rating
    }
}

// MARK: - Memory Manager

// ObservableObject class to manage food memories with persistence
class MemoryManager: ObservableObject {
    @Published var foodMemories: [FoodMemory] = [] // Published array triggers UI updates when changed
    
    private let userDefaults = UserDefaults.standard // Access to persistent storage
    private let memoriesKey = "SavedFoodMemories" // Key for storing memories in UserDefaults
    
    // Initialize and load existing memories from storage
    init() {
        loadMemories() // Load saved memories when app starts
    }
    
    // Add a new memory to the collection and save to storage
    func addMemory(_ memory: FoodMemory) {
        foodMemories.append(memory) // Add to local array
        saveMemories() // Persist to storage
    }
    
    // Remove a memory from the collection and save changes
    func deleteMemory(_ memory: FoodMemory) {
        foodMemories.removeAll { $0.id == memory.id } // Remove memory with matching ID
        saveMemories() // Update storage
    }
    
    // Private function to save memories to UserDefaults
    private func saveMemories() {
        let memoriesData = foodMemories.map { memory in
            var data: [String: Any] = [ // Dictionary to store memory data
                "id": memory.id.uuidString, // Convert UUID to string for storage
                "latitude": memory.coordinate.latitude, // Store latitude
                "longitude": memory.coordinate.longitude, // Store longitude
                "name": memory.name, // Store food name
                "dateAdded": memory.dateAdded, // Store creation date
                "notes": memory.notes, // Store personal notes
                "rating": memory.rating // Store rating
            ]
            
            // Convert and save photo as data if it exists
            if let photo = memory.photo, // Check if photo exists
               let photoData = photo.jpegData(compressionQuality: 0.8) { // Convert to JPEG data with 80% quality
                data["photoData"] = photoData // Add photo data to dictionary
            }
            
            return data // Return dictionary for this memory
        }
        
        userDefaults.set(memoriesData, forKey: memoriesKey) // Save array to UserDefaults
    }
    
    // Private function to load memories from UserDefaults
    private func loadMemories() {
        guard let memoriesData = userDefaults.array(forKey: memoriesKey) as? [[String: Any]] else {
            return // Exit if no saved data or wrong type
        }
        
        // Transform saved data back into FoodMemory objects
        foodMemories = memoriesData.compactMap { data in // compactMap removes nil values
            guard let idString = data["id"] as? String, // Extract ID string
                  let id = UUID(uuidString: idString), // Convert to UUID
                  let latitude = data["latitude"] as? Double, // Extract latitude
                  let longitude = data["longitude"] as? Double, // Extract longitude
                  let name = data["name"] as? String, // Extract name
                  let dateAdded = data["dateAdded"] as? Date else { // Extract date
                return nil // Return nil if any required field is missing
            }
            
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude) // Create coordinate
            
            // Extract optional fields with defaults
            let notes = data["notes"] as? String ?? "" // Default to empty string
            let rating = data["rating"] as? Int ?? 3 // Default to 3 stars
            
            var photo: UIImage? // Optional photo variable
            if let photoData = data["photoData"] as? Data { // Check if photo data exists
                photo = UIImage(data: photoData) // Convert data back to UIImage
            }
            
            return FoodMemory( // Create FoodMemory instance
                id: id, // Use existing ID
                coordinate: coordinate, // Use created coordinate
                name: name, // Use extracted name
                photo: photo, // Use converted photo
                dateAdded: dateAdded, // Use extracted date
                notes: notes, // Use extracted notes
                rating: rating // Use extracted rating
            )
        }
    }
} // Fixed: Added missing closing brace

// MARK: - Main Content View

struct ContentView: View {
    
    // State for map camera position - starts at San Francisco
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.07, longitudeDelta: 0.07)
        )
    )

    
    @StateObject private var memoryManager = MemoryManager() // Create memory manager instance
    @State private var selectedMemory: FoodMemory? // Currently selected memory for details
    @State private var showingMemoryDetail = false // Controls detail sheet presentation
    @State private var showingAddMemory = false // Controls add memory sheet presentation
    @State private var newPinCoordinate: CLLocationCoordinate2D? // Stores coordinate for new memory
    @State private var searchText = "" // Text in search field
    
    var body: some View {
        NavigationView { // navigation view for toolbar
            VStack(spacing: 0) { // Vertical stack with no spacing
                // Search bar at top
                HStack {
                    TextField("Have a place in mind?", text: $searchText) // Search input field
                        .padding(12) // Inner padding
                        .background(Color(.systemGray6)) // Light gray background
                        .cornerRadius(10) // Rounded corners
                    
                    // Search button
                    Button(action: {
                        searchForLocation() // Trigger location search
                    }) {
                        Image(systemName: "magnifyingglass") // Magnifying glass icon
                            .padding() // Button padding
                            .foregroundColor(.blue) // Blue color
                    }
                }
                .padding() // Outer padding for search bar
                
                // Main map view
                Map(position: $position) {
                    // Display all existing food memories as map annotations
                    ForEach(memoryManager.foodMemories) { memory in
                        Annotation(memory.name, coordinate: memory.coordinate) { // Create annotation with name and coordinate
                            Button(action: {
                                selectedMemory = memory // Set selected memory
                                showingMemoryDetail = true // Show detail sheet
                            }) {
                                // Display photo if available, otherwise show food icon
                                if let photo = memory.photo {
                                    Image(uiImage: photo) // Display user's photo
                                        .resizable() // Make resizable
                                        .aspectRatio(contentMode: .fill) // Fill frame while maintaining aspect ratio
                                        .frame(width: 40, height: 40) // Fixed size
                                        .clipShape(Circle()) // Make circular
                                        .overlay(Circle().stroke(Color.white, lineWidth: 2)) // White border
                                        .shadow(radius: 3) // Drop shadow
                                } else {
                                    Image(systemName: "fork.knife.circle.fill") // Default food icon
                                        .foregroundColor(.red) // Red color
                                        .font(.title2) // Medium size
                                        .shadow(radius: 3) // Drop shadow
                                }
                            }
                        }
                    }
                }
                .ignoresSafeArea() // Map fills entire screen
                .onTapGesture { location in // Handle tap gestures on map
                    addFoodMemoryAt(tapLocation: location) // Add memory at tap location
                }
            }
            .navigationTitle("Nomadish") // App title in navigation bar
            .navigationBarTitleDisplayMode(.inline) // Compact title display
            .toolbar { // Add toolbar items
                ToolbarItem(placement: .navigationBarTrailing) { // Right side of navigation bar
                    Button(action: {
                        addMemoryAtCurrentLocation() // Add memory at current map center
                    }) {
                        Image(systemName: "plus") // Plus icon
                    }
                }
            }
            .sheet(isPresented: $showingAddMemory) { // Sheet for adding new memory
                AddMemoryView(
                    coordinate: newPinCoordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0), // Use stored coordinate or default
                    onSave: { memory in // Callback when memory is saved
                        memoryManager.addMemory(memory) // Fixed: Use memoryManager instead of foodMemories
                        showingAddMemory = false // Hide sheet
                    },
                    onCancel: { // Callback when cancelled
                        showingAddMemory = false // Hide sheet
                    }
                )
            }
            .sheet(isPresented: $showingMemoryDetail) { // Sheet for viewing memory details
                if let memory = selectedMemory { // Check if memory is selected
                    MemoryDetailView(
                        memory: memory, // Pass selected memory
                        onDelete: { // Callback for deletion
                            memoryManager.deleteMemory(memory) // Delete from memory manager
                            showingMemoryDetail = false // Hide sheet
                        },
                        onClose: { // Callback for closing
                            showingMemoryDetail = false // Hide sheet
                        }
                    )
                }
            }
        }
    }
    
    // Function to search for locations using natural language query
    func searchForLocation() {
        let request = MKLocalSearch.Request() // Create search request
        request.naturalLanguageQuery = searchText // Set search query
        
        let search = MKLocalSearch(request: request) // Create search object
        search.start { response, error in // Start search
            guard let coordinate = response?.mapItems.first?.placemark.coordinate else {
                print("No results found for: \(searchText)") // Log if no results
                return
            }
            
            // Animate map to search result location
            withAnimation(.easeInOut(duration: 1.0)) {
                position = .region(MKCoordinateRegion(
                    center: coordinate, // Center on found location
                    span: MKCoordinateSpan(latitudeDelta: 0.07, longitudeDelta: 0.07) // Zoom level
                ))
            }
        }
    }
    
    // Function to add memory at current map center
    func addMemoryAtCurrentLocation() {
        let centerCoordinate = getCurrentMapCenter() // Fixed: was "getCurrentMapcenter" with typo
        newPinCoordinate = centerCoordinate // Store coordinate
        showingAddMemory = true // Show add memory sheet
    }
    
    // Function to handle tap gestures on map (simplified version)
    func addFoodMemoryAt(tapLocation: CGPoint) {
        let centerCoordinate = getCurrentMapCenter() // Get map center
        newPinCoordinate = centerCoordinate // Store coordinate
        showingAddMemory = true // Show add memory sheet
    }
    
    func getCurrentMapCenter() -> CLLocationCoordinate2D {
        // Accessing the region property directly if the position is a region
        return position.region?.center ?? CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    }


}

// MARK: - Add Memory View

// View for adding a new food memory
struct AddMemoryView: View {
    let coordinate: CLLocationCoordinate2D // Location for the memory
    let onSave: (FoodMemory) -> Void // Callback when saving
    let onCancel: () -> Void // Callback when cancelling
    
    @State private var memoryName = "" // Name of the food/memory
    @State private var notes = "" // Personal notes
    @State private var rating = 3 // Rating from 1-5
    @State private var selectedPhoto: UIImage? // Selected photo
    @State private var showingImagePicker = false // Controls image picker
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Add Food Memory") // Title
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Photo selection area
                Button(action: {
                    showingImagePicker = true // Show image picker
                }) {
                    if let photo = selectedPhoto { // If photo is selected
                        Image(uiImage: photo) // Display selected photo
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 200, height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else { // If no photo selected
                        RoundedRectangle(cornerRadius: 12) // Placeholder rectangle
                            .fill(Color(.systemGray5))
                            .frame(width: 200, height: 200)
                            .overlay(
                                VStack {
                                    Image(systemName: "camera") // Camera icon
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                    Text("Add Photo") // Helper text
                                        .foregroundColor(.gray)
                                }
                            )
                    }
                }
                
                // Food name input
                TextField("What did you eat here?", text: $memoryName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                // Notes input
                TextField("Notes (optional)", text: $notes)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                // Rating picker
                VStack {
                    Text("Rating")
                        .font(.headline)
                    HStack {
                        ForEach(1...5, id: \.self) { star in // Create 5 star buttons
                            Button(action: {
                                rating = star // Set rating
                            }) {
                                Image(systemName: star <= rating ? "star.fill" : "star") // Filled or empty star
                                    .foregroundColor(star <= rating ? .purple : .gray) // Purple stars
                                    .font(.title2)
                            }
                        }
                    }
                }
                
                // Location display
                Text("Location: \(coordinate.latitude, specifier: "%.4f"), \(coordinate.longitude, specifier: "%.4f")")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer() // Push buttons to bottom
                
                // Action buttons
                HStack {
                    Button("Cancel") { // Cancel button
                        onCancel()
                    }
                    .foregroundColor(.red)
                    
                    Spacer()
                    
                    Button("Save") { // Save button
                        if !memoryName.isEmpty { // Check if name is provided
                            let memory = FoodMemory( // Create new memory
                                coordinate: coordinate,
                                name: memoryName,
                                photo: selectedPhoto,
                                dateAdded: Date(),
                                notes: notes, // Fixed: Include notes parameter
                                rating: rating // Fixed: Include rating parameter
                            )
                            onSave(memory) // Call save callback
                        }
                    }
                    .foregroundColor(.blue)
                    .disabled(memoryName.isEmpty) // Disable if name is empty
                }
                .padding()
            }
            .padding()
            .navigationTitle("New Memory") // Navigation title
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingImagePicker) { // Image picker sheet
                ImagePicker(image: $selectedPhoto)
            }
        }
    }
}

// MARK: - Memory Detail View

// View for displaying full memory details
struct MemoryDetailView: View {
    let memory: FoodMemory // Memory to display
    let onDelete: () -> Void // Callback for deletion
    let onClose: () -> Void // Callback for closing
    
    var body: some View {
        NavigationView {
            VStack(spacing: 15) { // Fixed: was "Vstack" - needs capital V
                // Photo display
                if let photo = memory.photo {
                    Image(uiImage: photo) // Display memory photo
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Image(systemName: "fork.knife") // Default food icon
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                }
                
                // Memory name
                Text(memory.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Rating display
                HStack {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= memory.rating ? "star.fill" : "star") // Show filled/empty stars
                            .foregroundColor(star <= memory.rating ? .yellow : .gray)
                    }
                }
                
                // Notes display
                if !memory.notes.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Notes:")
                            .font(.headline)
                        Text(memory.notes)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Date and location info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Added: \(memory.dateAdded, formatter: dateFormatter)") // Format date
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Location: \(memory.coordinate.latitude, specifier: "%.4f"), \(memory.coordinate.longitude, specifier: "%.4f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer() // Push buttons to bottom
                
                // Action buttons
                HStack {
                    Button("Delete") { // Delete button
                        onDelete()
                    }
                    .foregroundColor(.red)
                    
                    Spacer()
                    
                    Button("Close") { // Close button
                        onClose()
                    }
                    .foregroundColor(.blue)
                }
                .padding()
            }
            .padding()
            .navigationTitle("Memory Details") // Navigation title
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // Date formatter for displaying dates
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium // Medium date style
        formatter.timeStyle = .short // Short time style
        return formatter
    }
}

// MARK: - Image Picker

// UIKit wrapper for image picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage? // Binding to selected image
    
    // Create UIImagePickerController
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator // Set delegate
        picker.sourceType = .photoLibrary // Use photo library
        return picker
    }
    
    // Update controller (not needed)
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    // Create coordinator for handling delegates
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // Coordinator class to handle picker delegate methods
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        // Handle image selection
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { // Get selected image
                parent.image = image // Update parent's image binding
            }
            picker.dismiss(animated: true) // Dismiss picker
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView() // Preview the main content view
}
