//
//  ContentView.swift
//  Nomadish
//
//  Created by Riddhi Munjewar on 5/26/25.
//

import SwiftUI
import MapKit
//import FirebaseFirestone
import FirebaseStorage

struct FoodMemory: Identifiable {
    let id: UUID
    var coordinate: CLLocationCoordinate2D
    var name: String
    var photo: UIImage?
    var dateAdded: Date
    var notes: String
    var rating: Int
    
    init(coordinate: CLLocationCoordinate2D, name: String, photo: UIImage?, dateAdded: Date, notes: String = "", rating: Int = 3) {
        self.id = UUID()
        self.coordinate = coordinate
        self.name = name
        self.photo = photo
        self.dateAdded = dateAdded
        self.notes = notes
        self.rating = rating
    }
    
    init(id: UUID, coordinate: CLLocationCoordinate2D, name: String, photo: UIImage?, dateAdded: Date, notes: String = "", rating: Int = 3) {
        self.id = id
        self.coordinate = coordinate
        self.name = name
        self.photo = photo
        self.dateAdded = dateAdded
        self.notes = notes
        self.rating = rating
    }
}

class MemoryManager: ObservableObject {
    @Published var foodMemories: [FoodMemory] = []
    
    private let userDefaults = UserDefaults.standard
    private let memoriesKey = "SavedFoodMemories"
    
    init() {
        loadMemories()
    }
    
    func addMemory(_ memory: FoodMemory) {
        foodMemories.append(memory)
        saveMemories()
    }
    
    func deleteMemory(_ memory: FoodMemory) {
        foodMemories.removeAll { $0.id == memory.id }
        saveMemories()
    }
    
    private func saveMemories() {
        let memoriesData = foodMemories.map { memory in
            var data: [String: Any] = [
                "id": memory.id.uuidString,
                "latitude": memory.coordinate.latitude,
                "longitude": memory.coordinate.longitude,
                "name": memory.name,
                "dateAdded": memory.dateAdded,
                "notes": memory.notes,
                "rating": memory.rating
            ]
            
            if let photo = memory.photo,
               let photoData = photo.jpegData(compressionQuality: 0.8) {
                data["photoData"] = photoData
            }
            
            return data
        }
        
        userDefaults.set(memoriesData, forKey: memoriesKey)
    }
    
    private func loadMemories() {
        guard let memoriesData = userDefaults.array(forKey: memoriesKey) as? [[String: Any]] else {
            return
        }
        
        foodMemories = memoriesData.compactMap { data in
            guard let idString = data["id"] as? String,
                  let id = UUID(uuidString: idString),
                  let latitude = data["latitude"] as? Double,
                  let longitude = data["longitude"] as? Double,
                  let name = data["name"] as? String,
                  let dateAdded = data["dateAdded"] as? Date else {
                return nil
            }
            
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let notes = data["notes"] as? String ?? ""
            let rating = data["rating"] as? Int ?? 3
            
            var photo: UIImage?
            if let photoData = data["photoData"] as? Data {
                photo = UIImage(data: photoData)
            }
            
            return FoodMemory(
                id: id,
                coordinate: coordinate,
                name: name,
                photo: photo,
                dateAdded: dateAdded,
                notes: notes,
                rating: rating
            )
        }
    }
}

struct ContentView: View {
    
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.07, longitudeDelta: 0.07)
        )
    )

    
    @StateObject private var memoryManager = MemoryManager()
    @State private var selectedMemory: FoodMemory?
    @State private var showingMemoryDetail = false
    @State private var showingAddMemory = false
    @State private var newPinCoordinate: CLLocationCoordinate2D?
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
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
                
                Map(position: $position) {
                    ForEach(memoryManager.foodMemories) { memory in
                        Annotation(memory.name, coordinate: memory.coordinate) {
                            Button(action: {
                                selectedMemory = memory
                                showingMemoryDetail = true
                            }) {
                                if let photo = memory.photo {
                                    Image(uiImage: photo)
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
                .ignoresSafeArea()
                .onTapGesture { location in
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
                        memoryManager.addMemory(memory)
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
                        memory: memory,
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
    }
    
    func searchForLocation() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let coordinate = response?.mapItems.first?.placemark.coordinate else {
                print("No results found for: \(searchText)")
                return
            }
            
            withAnimation(.easeInOut(duration: 1.0)) {
                position = .region(MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.07, longitudeDelta: 0.07)
                ))
            }
        }
    }
    
    func addMemoryAtCurrentLocation() {
        let centerCoordinate = getCurrentMapCenter()
        newPinCoordinate = centerCoordinate
        showingAddMemory = true
    }
    
    func addFoodMemoryAt(tapLocation: CGPoint) {
        let centerCoordinate = getCurrentMapCenter()
        newPinCoordinate = centerCoordinate
        showingAddMemory = true
    }
    
    func getCurrentMapCenter() -> CLLocationCoordinate2D {
        return position.region?.center ?? CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    }


}

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
                
                TextField("What were the yummy eats?", text: $memoryName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                TextField("Notes (optional)", text: $notes)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                VStack {
                    Text("Rating")
                        .font(.headline)
                    HStack {
                        ForEach(1...5, id: \.self) { star in
                            Button(action: {
                                rating = star
                            }) {
                                Image(systemName: star <= rating ? "star.fill" : "star")
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
                                dateAdded: Date(),
                                notes: notes,
                                rating: rating
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

struct MemoryDetailView: View {
    let memory: FoodMemory
    let onDelete: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 15) {
                if let photo = memory.photo {
                    Image(uiImage: photo)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                }
                
                Text(memory.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                HStack {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= memory.rating ? "star.fill" : "star")
                            .foregroundColor(star <= memory.rating ? .yellow : .gray)
                    }
                }
                
                if !memory.notes.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Notes:")
                            .font(.headline)
                        Text(memory.notes)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Added: \(memory.dateAdded, formatter: dateFormatter)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Location: \(memory.coordinate.latitude, specifier: "%.4f"), \(memory.coordinate.longitude, specifier: "%.4f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack {
                    Button("Delete") {
                        onDelete()
                    }
                    .foregroundColor(.red)
                    
                    Spacer()
                    
                    Button("Close") {
                        onClose()
                    }
                    .foregroundColor(.blue)
                }
                .padding()
            }
            .padding()
            .navigationTitle("Memory Details")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
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

#Preview {
    ContentView()
}
