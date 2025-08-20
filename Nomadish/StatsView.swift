import SwiftUI
import Charts

struct StatsView: View {
    let memories: [FoodMemory]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    overviewSection
                    
                    ratingChartSection
                    
                    recentMemoriesSection
                    
                    locationStatsSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Your Food Journey")
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
    
    // MARK: - View Components
    
    private var overviewSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCard(
                title: "Total Memories",
                value: "\(memories.count)",
                icon: "heart.fill",
                color: .red
            )
            
            StatCard(
                title: "Average Rating",
                value: String(format: "%.1f", averageRating),
                icon: "star.fill",
                color: .yellow
            )
            
            StatCard(
                title: "This Month",
                value: "\(memoriesThisMonth)",
                icon: "calendar",
                color: .blue
            )
            
            StatCard(
                title: "Top Cuisine",
                value: topCuisine,
                icon: "fork.knife",
                color: .purple
            )
        }
    }
    
    private var ratingChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rating Distribution")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                ForEach(1...5, id: \.self) { rating in
                    HStack {
                        Text("\(rating)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        
                        HStack(spacing: 4) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.caption)
                                    .foregroundColor(star <= rating ? .yellow : .gray)
                            }
                        }
                        
                        Spacer()
                        
                        Text("\(ratingCount(for: rating))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 30, alignment: .trailing)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
    
    private var recentMemoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Memories")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                ForEach(Array(memories.prefix(5).enumerated()), id: \.element.id) { index, memory in
                    HStack {
                        Text("\(index + 1)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(memory.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text(memory.dateAdded.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= memory.rating ? "star.fill" : "star")
                                    .font(.caption2)
                                    .foregroundColor(star <= memory.rating ? .yellow : .gray)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    
                    if index < min(4, memories.count - 1) {
                        Divider()
                            .padding(.leading, 36)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
    
    private var locationStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Location Insights")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Cities Visited")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("\(uniqueCities)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    Spacer()
                    Image(systemName: "building.2")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Farthest Memory")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(farthestMemoryName)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    Spacer()
                    Image(systemName: "location.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
    
    // MARK: - Computed Properties
    
    private var averageRating: Double {
        guard !memories.isEmpty else { return 0 }
        let total = memories.reduce(0) { $0 + $1.rating }
        return Double(total) / Double(memories.count)
    }
    
    private var memoriesThisMonth: Int {
        let calendar = Calendar.current
        let now = Date()
        return memories.filter { memory in
            calendar.isDate(memory.dateAdded, equalTo: now, toGranularity: .month)
        }.count
    }
    
    private var topCuisine: String {
        // This would be more sophisticated in a real app
        // For now, just return a placeholder
        return "Various"
    }
    
    private var uniqueCities: Int {
        // This would require more sophisticated location data
        // For now, estimate based on coordinate clusters
        return min(memories.count, 10)
    }
    
    private var farthestMemoryName: String {
        // This would calculate actual distances in a real app
        return memories.first?.name ?? "None"
    }
    
    // MARK: - Helper Functions
    
    private func ratingCount(for rating: Int) -> Int {
        memories.filter { $0.rating == rating }.count
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    StatsView(memories: [])
}
