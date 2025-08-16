//
//  MemoryDetailView.swift
//  Nomadish
//
//  Created by Riddhi Munjewar on 8/16/25.
//


import SwiftUI

struct MemoryDetailView: View {
    let memory: FoodMemory
    let onDelete: () -> Void
    
    // Environment property to dismiss the sheet
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            // Using a Form provides a clean, sectioned layout for displaying info
            Form {
                // Section for the photo
                if let photo = memory.photo {
                    Section {
                        Image(uiImage: photo)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .listRowInsets(EdgeInsets()) // Make image fill the width
                    }
                }
                
                // Section for the main details
                Section {
                    // Centered title and rating
                    VStack(spacing: 8) {
                        Text(memory.name)
                            .font(.title)
                            .bold()
                        
                        HStack {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= memory.rating ? "star.fill" : "star")
                                    .foregroundColor(star <= memory.rating ? .yellow : .gray)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical)
                }
                
                // Section for notes if they exist
                if !memory.notes.isEmpty {
                    Section(header: Text("Notes 📝")) {
                        Text(memory.notes)
                    }
                }
                
                // Section for metadata like date and location
                Section(header: Text("Info")) {
                    LabeledContent("Date Added", value: memory.dateAdded.formatted(date: .abbreviated, time: .shortened))
                    LabeledContent("Location", value: "\(memory.coordinate.latitude, specifier: "%.4f"), \(memory.coordinate.longitude, specifier: "%.4f")")
                }
                
                // Section for the delete button
                Section {
                    Button("Delete Memory", role: .destructive, action: onDelete)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
