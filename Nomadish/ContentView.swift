//
//  ContentView.swift
//  Nomadish
//
//  Created by Riddhi Munjewar on 5/26/25.
//

import SwiftUI
import MapKit

// MARK: Data Models

// Model representing a food memory with location, photo, and metadata
struct FoodMemory: Identifiable {
    let id = UUID
    var coordinate: CLLocationCoordinate2D
    var name: String
    var photo: UIImage?
    var dateAdded: Date
    var notes: String
    var rating: Int
    
    // initializer for creating new memories
    init(coordinate: CLLocationCoordinate2D, name: String, photo: UIImage?, dateAdded: Date) {
        self.id = UUID()
        self.coordinate = coordinate
        self.name = name
        self.photo = photo
        self.dateAdded = dateAdded
        self.notes = notes
        self.rating = rating
    }
    
    // initializer for loading from saved data
    init(id: UUID, coordinate: CLLocationCoordinate2D, name: String, photo: UIImage?, dateAdded: Date) {
        self.id = id
        self.coordinate = coordinate
        self.name = name
        self.photo = photo
        self.dateAdded = dateAdded
        self.notes = notes
        self.rating = rating
    }
}


// MARK: Memory Manager

// obserable object class to manage good memories
class MemoryManager: ObservableObject {
    @Published var foodMemories: [FoodMemory] = [] // published means to swift ui and foodmemories array initializerd
    
    private let userDefaults = UserDefaults.standard // only accesible within class, userdefaults means perstitent storage
    private let memoriesKey = "SavedFoodMemories"
    
    init() {
        loadMemories()
    }
    
    func addMemory(_ memory: FoodMemory) { // function, _ means unnamed parameret,
        foodMemories.append(memory) // appending new memeory to array
        saveMemories() // saving memories
    }
    
    func deleteMemory(_ memory: FoodMemory) {
        foodMemories.removeAll{ $0.id == memory.id} // $0 means each element in array, check with id
        saveMemories()
    }
    
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
            
            // save photo as data if it exists
            if let photo = memory.photo, // if let means just checking tos ee if photo esists
               let photoData = photo.jpegData(compressionQuality: 0.8) { // then the image gets converted to data with 80% of its quality
                data["photoData"] = photoData // photo is added to dictionary
            }
            
            return data //return dictionary
        }
        
        userDefaults.set(memoriesData, forKey: memoriesKey) // saved to userDefaults
    }
    
    private func loadMemories() {
        guard let memoriesData = userDefaults.array(forKey: memoriesKey) as? [[String: Any]] else {
            return // exit if no saved data or wrong type
        }
        
        foodMemories = memoriesData.compactMap { data in // compact map = transforms and filters nil values
            guard let idString = data["id"] as? String, // Extract ID string
                              let id = UUID(uuidString: idString), // Convert to UUID
                              let latitude = data["latitude"] as? Double, // Extract latitude
                              let longitude = data["longitude"] as? Double, // Extract longitude
                              let name = data["name"] as? String, // Extract name
                              let dateAdded = data["dateAdded"] as? Date else { // Extract date
                            return nil // Return nil if any required field is missing
                        }
            
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            //optional fields
            let notes = data["notes"] as? String ?? ""
            let rating = data["rating"] as? Int ?? 3
            
            var photo: UIImage? // declare optional photo variable
            if let photoData = data["photoData"] as? Data { // if photo data exists
                photo = UIImage(data: photoData) // convert data back to uiimage
            }
            
            return FoodMemory(                           // Create and return FoodMemory instance
                            id: id,                                  // Use existing ID
                            coordinate: coordinate,                  // Use created coordinate
                            name: name,                             // Use extracted name
                            photo: photo,                           // Use converted photo
                            dateAdded: dateAdded                    // Use extracted date
                            notes: notes,
                            rating, rating
                        )
    }
}
    
// MARK: Main Content View

struct ContentView: View {
    
    // defining the map region
    @State private var position = MapCameraPosition.region(
        MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // San Francisco coordinates
                    span: MKCoordinateSpan(latitudeDelta: 0.07, longitudeDelta: 0.07) // zoom level
                )
    )
    
    @StateObject private var memoryManager = MemoryManager()
    @State private var selectedMemory: FoodMemory?
    @State private var showingMemoryDetail = false
    @State private var showingAddMemory = false
    @State private var newPinCoordinate: CLLocationCoordinate2D?
    @State private var searchText = ""
    
    var body: some View {
        NavigationView { // navigation view for toolbar
            VStack(spacing: 0) {
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
                        .foregroundColor(.blue)
                }
            }
            .padding()
            
            // display the map
            Map(position: $position) {
                // Show all existing food memories as pins
                ForEach(memoryManager.foodMemories) { memory in
                    Annotation(memory.name, coordinate: memory.coordinate) {
                        Button(action: {
                            selectedMemory = memory
                            showingMemoryDetail = true
                        }) {
                            if let photo = memory.photo {
                                Image(uiImage: photo) // displaing user's photo
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                    .shadow(radius: 3)
                            } else {
                                Image(systemName: "fork.knife.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.title2)
                                    .shadow(radius: 3)
                            }
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
        .navigationTitle("Nomadish")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    addMemoryAtCurrentLocation()
                }) {
                    Image(systemName: "plus")
                }
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
        .sheet(isPresented: $showingMemoryDetail) {
            if let memory = selectedMemory {
                MemoryDetailView(
                    memory: memory, // pass selected memory
                    onDelete: {
                        memoryManager.deleteMemory(memory)
                        showingMemoryDetail = false
                    },
                    onClose: {
                        showingMemoryDetail = false
                    }
                )
            }
        }
    }
    
    func searchForLocation() {
        let request = MKLocalSearch.Request() // creating search request
        request.naturalLanguageQuery = searchText
        
        let search = MKLocalSearch(request: request) //creating search object
        search.start { response, error in // starting search
            guard let coordinate = response?.mapItems.first?.placemark.coordinate else {
                print("No results found: \(searchText)")
                return
            }
            
            // animation
            withAnimation {
                position = .region(MKCoordinateRegion(
                    center: coordinate, // Center on found location
                    span: MKCoordinateSpan(latitudeDelta: 0.07, longitudeDelta: 0.07)
                ))
            }
        }
    }
        
        func addMemoryAtCurrentLocation() {
            let centerCoordinate = getCurrentMapcenter()
            newPinCoordinate = centerCoordinate
            showingAddMemory = true
        }
    
    func addFoodMemoryAt(tapLocation: CGPoint) {
        let centerCoordinate = getCurrentMapCenter()
        newPinCoordinate = centerCoordinate
        showingAddMemory = true
    }
    
        func getCurrentMapCenter() -> CLLocationCoordinate2D {
                // Extract center from current map position
                switch position {
                case .region(let region):
                    return region.center // Return region center
                default:
                    return CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194) // Default to San Francisco
                }
            }
}

// MARK: add memory view
    
// New view for adding a memory
struct AddMemoryView: View {
    let coordinate: CLLocationCoordinate2D
    let onSave: (FoodMemory) -> Void
    let onCancel: () -> Void
    
    @State private var memoryName = ""
    @State private var notes = ""
    @State private var rating = 3
    @State private var selectedPhoto: UIImage?
    @State private var showingImagePicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Add Food Memory")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Photo selection area
                Button(action: {
                    showingImagePicker = true
                }) {
                    if let photo = selectedPhoto {
                        Image(uiImage: photo)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 200, height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray5))
                            .frame(width: 200, height: 200)
                            .overlay(
                                VStack {
                                    Image(systemName: "camera")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                    Text("Add Photo")
                                        .foregroundColor(.gray)
                                }
                            )
                    }
                }
                
                TextField("What did you eat here?", text: $memoryName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
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
                                    .foregroundColor(star <= rating ? .purple : .gray)
                                    .font(.title2)
                            }
                        }
                    }
                }
                
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
                            let memory = FoodMemory(
                                coordinate: coordinate,
                                name: memoryName,
                                photo: selectedPhoto,
                                dateAdded: Date()
                            )
                            onSave(memory)
                        }
                    }
                    .foregroundColor(.blue)
                    .disabled(memoryName.isEmpty)
                }
                .padding()
            }
            .padding()
            .navigationTitle("New Memory")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedPhoto)
            }
        }
    }
}

    // MARK: memory detail view
    struct MemoryDetailView: View {
        let memory: FoodMemory
        let onDelete = () -> Void
        let onClose = () -> Void
        
        var body: some View {
            NavigationView {
                Vstack(spacing: 15) {
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
                    Text(memory.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // rating display
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

    
    struct ImagePicker: UIViewControllerRepresentable {
        @Binding var image: UIImage?
        
        func makeUIViewController(context: Context) -> UIImagePickerController {
            let picker = UIImagePickerController()
            picker.delegate = context.coordinator
            picker.sourceType = .photoLibrary
            return picker
        }
        
        func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
        
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }
        
        class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
            let parent: ImagePicker
            
            init(_ parent: ImagePicker) {
                self.parent = parent
            }
            
            func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
                if let image = info[.originalImage] as? UIImage {
                    parent.image = image
                }
                picker.dismiss(animated: true)
            }
        }
    }
    
}
    

#Preview {
    ContentView()
}
