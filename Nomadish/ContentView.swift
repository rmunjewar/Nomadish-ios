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
    var photo: UIImage?
    var dateAdded: Date
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
                // Show all existing food memories as pins
                ForEach(foodMemories) { memory in
                    Annotation(memory.name, coordinate: memory.coordinate) {
                        Button(action: {
                            // TODO: Show memory details when tapped
                            print("Tapped memory: \(memory.name)")
                        }) {
                            if let photo = memory.photo {
                                Image(uiImage: photo)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            } else {
                                Image(systemName: "fork.knife.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.title2)
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
        search.start { response, error in
            guard let coordinate = response?.mapItems.first?.placemark.coordinate else {
                print("No results found.")
                return
            }
            
            withAnimation {
                position = .region(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.07, longitudeDelta: 0.07)))
            }
        }
    }
    
    func addFoodMemoryAt(tapLocation: CGPoint) {
        // For now, we'll use a simple approach - when user taps, we'll prompt them
        // In a real implementation, convert the tap location to a coordinate
        // This is a simplified version that adds a pin at the current map center
        let centerCoordinate = getCenterCoordinate()
        newPinCoordinate = centerCoordinate
        showingAddMemory = true
    }
    
    func getCenterCoordinate() -> CLLocationCoordinate2D {
        // Get the center of the current map view
        // This is a simplified approach
        return CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    }
}

// New view for adding a memory
struct AddMemoryView: View {
    let coordinate: CLLocationCoordinate2D
    let onSave: (FoodMemory) -> Void
    let onCancel: () -> Void
    
    @State private var memoryName = ""
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
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedPhoto)
            }
        }
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
