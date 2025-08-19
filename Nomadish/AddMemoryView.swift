//
//  AddMemoryView.swift
//  Nomadish
//
//  Created by Riddhi Munjewar on 8/15/25.
//

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
    
    private let foodClassifier = FoodClassifier()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Photo Section
                    photoSection
                    
                    // Details Section
                    detailsSection
                    
                    // Rating Section
                    ratingSection
                    
                    // Location Preview
                    locationPreviewSection
                    
                    // Save Button
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
                guard let photo = newPhoto else { return }
                classifyImage(photo)
            }
            .task {
                await getLocationName()
            }
        }
    }
    
    // MARK: - View Components
    
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
                    
                    if isClassifying {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.7))
                            .frame(height: 250)
                            .overlay(
                                VStack(spacing: 12) {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(1.5)
                                    Text("Identifying dish...")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                            )
                    }
                }
            }
            .buttonStyle(.plain)
            
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
    
    // MARK: - Computed Properties
    
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
    
    // MARK: - Functions
    
    private func classifyImage(_ image: UIImage) {
        isClassifying = true
        foodClassifier.classify(image: image) { result in
            isClassifying = false
            if let prediction = result {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.memoryName = prediction
                }
            }
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
