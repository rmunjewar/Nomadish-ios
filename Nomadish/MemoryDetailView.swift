// MemoryDetailView.swift
// Nomadish
//
// Created by Riddhi Munjewar on 8/16/25.
//

import SwiftUI
import CoreLocation
import MapKit

struct MemoryDetailView: View {
    let memory: FoodMemory
    let onDelete: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var showingDeleteAlert = false
    @State private var showingMap = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Hero Photo Section
                    photoSection
                    
                    // Memory Details Section
                    detailsSection
                    
                    // Notes Section
                    if !memory.notes.isEmpty {
                        notesSection
                    }
                    
                    // Location Section
                    locationSection
                    
                    // Action Buttons
                    actionButtons
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Food Memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .alert("Delete Memory", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this food memory? This action cannot be undone.")
        }
    }
    
    // MARK: - View Components
    
    private var photoSection: some View {
        VStack(spacing: 0) {
            if let localPhoto = memory.photo {
                Image(uiImage: localPhoto)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 250)
                    .clipped()
                    .overlay(
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.3)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            } else if let imageUrlString = memory.imageUrl, let imageUrl = URL(string: imageUrlString) {
                AsyncImage(url: imageUrl) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 250)
                            .clipped()
                            .overlay(
                                LinearGradient(
                                    colors: [.clear, .black.opacity(0.3)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    case .failure:
                        placeholderView
                    case .empty:
                        ProgressView()
                            .frame(height: 250)
                            .background(Color(.systemGray5))
                    @unknown default:
                        placeholderView
                    }
                }
            } else {
                placeholderView
            }
            
            // Dish Name Overlay
            VStack(spacing: 8) {
                Text(memory.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // Rating Stars
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= memory.rating ? "star.fill" : "star")
                            .foregroundColor(star <= memory.rating ? .yellow : .white.opacity(0.6))
                            .font(.title3)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial)
            .cornerRadius(15)
            .offset(y: -30)
        }
    }
    
    private var placeholderView: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .frame(height: 250)
            .overlay(
                VStack(spacing: 12) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("No Photo Available")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
            )
    }
    
    private var detailsSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Date Added")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    Text(memory.dateAdded.formatted(date: .abbreviated, time: .shortened))
                        .font(.headline)
                }
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Rating")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    Text("\(memory.rating)/5")
                        .font(.headline)
                        .foregroundColor(.orange)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(memory.notes)
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
    
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Location")
                .font(.headline)
                .foregroundColor(.primary)
            
            Button(action: { showingMap = true }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Coordinates")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        Text(String(format: "%.4f, %.4f", memory.coordinate.latitude, memory.coordinate.longitude))
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    Spacer()
                    Image(systemName: "map.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showingMap) {
            LocationMapView(coordinate: memory.coordinate, title: memory.name)
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: { showingDeleteAlert = true }) {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Delete Memory")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.red)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Location Map View

struct LocationMapView: View {
    let coordinate: CLLocationCoordinate2D
    let title: String
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Map(position: .constant(.region(MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )))) {
                Annotation(title, coordinate: coordinate) {
                    VStack(spacing: 2) {
                        Image(systemName: "fork.knife.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .background(Color.purple)
                            .clipShape(Circle())
                        Text(title)
                            .font(.caption)
                            .padding(4)
                            .background(.white)
                            .cornerRadius(4)
                    }
                }
            }
            .navigationTitle("Location")
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
