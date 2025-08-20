import SwiftUI
import CoreLocation

struct AddMemoryView: View {
    let coordinate: CLLocationCoordinate2D
    let onSave: (FoodMemory, UIImage?) -> Void
    let onCancel: () -> Void
    
    @State private var memoryName = ""
    @State private var notes = ""
    @State private var rating = 3
    @State private var selectedPhoto: UIImage?
    
    @State private var showingImagePicker = false
    @State private var isClassifying = false
    @State private var showingLocationAlert = false
    @State private var locationName = ""
    @State private var classificationResult: ClassificationResult?
    
    @StateObject private var foodClassifier = FoodClassifier()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    photoSection
                    detailsSection
                    ratingSection
                    locationPreviewSection
                    saveButton
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("New Food Memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
                        .foregroundColor(.red)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedPhoto)
            }
            .onChange(of: selectedPhoto) { newPhoto in
                if let photo = newPhoto {
                    memoryName = ""
                    classificationResult = nil
                    foodClassifier.reset()
                    foodClassifier.classify(image: photo) { result in
                        self.classificationResult = result
                        if let result = result {
                            self.memoryName = result.name
                        }
                    }
                } else {
                    memoryName = ""
                    classificationResult = nil
                }
            }
            .task {
                await getLocationName()
            }
        }
    }
    
    private var photoSection: some View {
        VStack(spacing: 16) {
            Text("Food Photo")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button(action: { showingImagePicker = true }) {
                ZStack {
                    if let photo = selectedPhoto {
                        Image(uiImage: photo)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 250)
                            .clipped()
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.blue, lineWidth: 3)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray6))
                            .frame(height: 250)
                            .overlay(
                                VStack(spacing: 12) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                    Text("Tap to select a photo")
                                        .font(.headline)
                                        .foregroundColor(.gray)
                                    Text("We'll automatically identify the dish!")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                            )
                    }
                    
                    if foodClassifier.isClassifying {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.7))
                            .frame(height: 250)
                            .overlay(
                                VStack(spacing: 12) {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(1.5)
                                    Text("Analyzing food...")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Text("Using AI to identify your dish")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            )
                    }
                }
            }
            .buttonStyle(.plain)
            
            if let result = classificationResult {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.purple)
                        Text("AI Analysis Results")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    
                    VStack(spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(result.name)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Text(result.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("\(Int(result.confidence * 100))%")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(confidenceColor(result.confidence))
                                
                                Text(foodClassifier.getConfidenceDescription(result.confidence))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        if !result.alternatives.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Alternative suggestions:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 8) {
                                    ForEach(result.alternatives, id: \.self) { alternative in
                                        Button(action: {
                                            memoryName = alternative
                                        }) {
                                            Text(alternative)
                                                .font(.caption)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color.blue.opacity(0.1))
                                                .foregroundColor(.blue)
                                                .cornerRadius(8)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                }
            }
            
            if let photo = selectedPhoto {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Photo selected")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
    }
    
    private var detailsSection: some View {
        VStack(spacing: 16) {
            Text("Details")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Dish Name")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("e.g., Spicy Ramen, Margherita Pizza", text: $memoryName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.body)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes & Memories")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
    
    private var ratingSection: some View {
        VStack(spacing: 16) {
            Text("How was it?")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { star in
                        Button(action: { rating = star }) {
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .foregroundColor(star <= rating ? .yellow : .gray)
                                .font(.system(size: 32))
                                .scaleEffect(star == rating ? 1.2 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: rating)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Text(ratingText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
    
    private var locationPreviewSection: some View {
        VStack(spacing: 16) {
            Text("Location")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(locationName.isEmpty ? "Getting location..." : locationName)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Text(String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "location.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
    
    private var saveButton: some View {
        Button(action: saveMemory) {
            HStack {
                Image(systemName: "heart.fill")
                Text("Save Memory")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(canSave ? Color.blue : Color.gray)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
        .disabled(!canSave)
        .padding(.top, 8)
    }
    
    private var canSave: Bool {
        !memoryName.isEmpty && selectedPhoto != nil
    }
    
    private var ratingText: String {
        switch rating {
        case 1: return "Not great"
        case 2: return "Could be better"
        case 3: return "Good"
        case 4: return "Really good!"
        case 5: return "Amazing!"
        default: return "Select rating"
        }
    }
    
    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence > 0.8 {
            return .green
        } else if confidence > 0.5 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func getLocationName() async {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                let name = placemark.name ?? placemark.thoroughfare ?? placemark.locality ?? "Unknown Location"
                await MainActor.run {
                    self.locationName = name
                }
            }
        } catch {
            print("Geocoding error: \(error)")
            await MainActor.run {
                self.locationName = "Unknown Location"
            }
        }
    }
    
    private func saveMemory() {
        let newMemory = FoodMemory(
            name: memoryName,
            dateAdded: Date(),
            notes: notes,
            rating: rating,
            photo: selectedPhoto,
            coordinate: coordinate
        )
        onSave(newMemory, selectedPhoto)
    }
}
