//
//  MemoryManager.swift
//  Nomadish
//
//  Created by Riddhi Munjewar on 8/16/25.
//
// MemoryManager.swift

import Foundation

// This class now just holds the food memories in an array while the app is running.
// The next step would be to replace this with API calls to your backend server.
class MemoryManager: ObservableObject {
    @Published var foodMemories: [FoodMemory] = []
    
    init() {
        // In the future, you would call something like `loadMemoriesFromServer()` here.
        loadSampleMemories() // For now, we'll load some fake data to see how it looks.
    }
    
    func addMemory(_ memory: FoodMemory) {
        // In the future, you'd send this to your server.
        // On success, the server would return the saved memory, and you'd add it here.
        foodMemories.append(memory)
    }
    
    func deleteMemory(_ memory: FoodMemory) {
        // In the future, you'd send a DELETE request to your server.
        // On success, you'd remove the memory from the local array.
        foodMemories.removeAll { $0.id == memory.id }
    }
    
    // A function to add some sample data so the map doesn't start empty.
    private func loadSampleMemories() {
        foodMemories = [
            // Sample data here...
        ]
    }
}
