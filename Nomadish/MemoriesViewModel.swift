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
    
    func fetchMemories() async {
        isLoading = true
        let result = await apiService.fetchMemories()
        
        switch result {
        case .success(let memories):
            self.foodMemories = memories
            persistenceService.saveMemories(memories)
        case .failure(let error):
          
            print("Error fetching memories: \(error)")
        }
        
        isLoading = false
    }
    
    func addMemory(_ memory: FoodMemory, photo: UIImage) async {
        isLoading = true
        let result = await apiService.addMemory(memory, photo: photo)
        
        switch result {
        case .success(let savedMemory):
            foodMemories.append(savedMemory)
            persistenceService.saveMemories(foodMemories)
        case .failure(let error):
            print("Error adding memory: \(error)")
            foodMemories.append(memory)
            persistenceService.saveMemories(foodMemories)
        }
        
        isLoading = false
    }
    
    func deleteMemory(_ memory: FoodMemory) async {
        let error = await apiService.deleteMemory(withId: memory.id)
        
        if let error = error {
            print("Error deleting memory: \(error)")
        } else {
          
            foodMemories.removeAll { $0.id == memory.id }
            persistenceService.saveMemories(foodMemories)
        }
    }
}
