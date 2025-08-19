//
//  MemoriesViewModel.swift
//  Nomadish
//
//  Created by Riddhi Munjewar on 8/16/25.
//

import Foundation
import SwiftUI

/// The main ViewModel responsible for managing the state and business logic for food memories.
@MainActor // Ensures that any updates to @Published properties happen on the main thread.
class MemoriesViewModel: ObservableObject {
    
    @Published var foodMemories: [FoodMemory] = []
    @Published var isLoading: Bool = false
    
    private let apiService: APIService
    private let persistenceService: PersistenceService
    
    init(apiService: APIService = APIService(), persistenceService: PersistenceService = PersistenceService()) {
        self.apiService = apiService
        self.persistenceService = persistenceService
        self.foodMemories = persistenceService.loadMemories()
    }
    
    /// Fetches the latest memories from the server and updates the local cache.
    func fetchMemories() async {
        isLoading = true
        let result = await apiService.fetchMemories()
        
        switch result {
        case .success(let memories):
            // Update the UI with the fresh data.
            self.foodMemories = memories
            // Save the new data to the local cache.
            persistenceService.saveMemories(memories)
        case .failure(let error):
            // In a real app, you would show an error alert to the user.
            print("Error fetching memories: \(error)")
            // For now, use cached data if available
        }
        
        isLoading = false
    }
    
    /// Adds a new memory by sending it to the server and updating the local state.
    func addMemory(_ memory: FoodMemory, photo: UIImage) async {
        isLoading = true
        let result = await apiService.addMemory(memory, photo: photo)
        
        switch result {
        case .success(let savedMemory):
            // Add the new memory to our local array.
            foodMemories.append(savedMemory)
            // Update the local cache.
            persistenceService.saveMemories(foodMemories)
        case .failure(let error):
            print("Error adding memory: \(error)")
            // If server fails, add to local cache for now
            foodMemories.append(memory)
            persistenceService.saveMemories(foodMemories)
        }
        
        isLoading = false
    }
    
    /// Deletes a memory from the server and updates the local state.
    func deleteMemory(_ memory: FoodMemory) async {
        let error = await apiService.deleteMemory(withId: memory.id)
        
        if let error = error {
            print("Error deleting memory: \(error)")
        } else {
            // If the server deletion was successful, remove it from our local array.
            foodMemories.removeAll { $0.id == memory.id }
            // Update the local cache.
            persistenceService.saveMemories(foodMemories)
        }
    }
}
