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
    let onSave: (FoodMemory) -> Void
    let onCancel: () -> Void
        @State private var memoryName = ""
    @State private var notes = ""
    @State private var rating = 3
    @State private var selectedPhoto: UIImage?
    
   
    @State private var showingImagePicker = false
    @State private var isClassifying = false
    private let foodClassifier = FoodClassifier()
    
    var body: some View {
        NavigationView {
          
            Form {
                Section(header: Text("Photo")) {
                    Button(action: { showingImagePicker = true }) {
                        ZStack {
                            if let photo = selectedPhoto {
                                Image(uiImage: photo)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 200)
                                    .clipped()
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                                    .frame(height: 200)
                                    .overlay(
                                        VStack {
                                            Image(systemName: "camera.fill")
                                            Text("Tap to select a photo")
                                        }
                                        .font(.headline)
                                        .foregroundColor(.gray)
                                    )
                            }
                             "thinking"
                            if isClassifying {
                                Color.black.opacity(0.5)
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(1.5)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                
                Section(header: Text("Details")) {
                    TextField("Dish Name (e.g., Spicy Ramen)", text: $memoryName)
                  
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
                
                Section(header: Text("Rating")) {
                    HStack {
                        Spacer()
                        ForEach(1...5, id: \.self) { star in
                            Button(action: { rating = star }) {
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .foregroundColor(star <= rating ? .yellow : .gray)
                                    .font(.title)
                            }
                        }
                        Spacer()
                    }
                }
            }
            .navigationTitle("New Food Memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save", action: saveMemory)
                        .bold()
                        .disabled(memoryName.isEmpty || selectedPhoto == nil) /
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedPhoto)
            }
            
            .onChange(of: selectedPhoto) { newPhoto in
                guard let photo = newPhoto else { return }
                classifyImage(photo)
            }
        }
    }
    
    private func classifyImage(_ image: UIImage) {
        isClassifying = true
        foodClassifier.classify(image: image) { result in
            isClassifying = false
            if let prediction = result {
                self.memoryName = prediction
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
        onSave(newMemory)
    }
}
