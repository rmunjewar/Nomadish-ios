// PersistenceService.swift
// Nomadish
//
// Created by Riddhi Munjewar on 8/17/25.
//

import Foundation

/// A service responsible for saving and loading food memories locally.
class PersistenceService {
    
    // A key to identify the saved data in UserDefaults.
    private let memoriesKey = "FoodMemoriesCache"
    
    /// Loads the array of `FoodMemory` from UserDefaults.
    /// - Returns: An array of `FoodMemory` objects, or an empty array if none are found or an error occurs.
    func loadMemories() -> [FoodMemory] {
        guard let data = UserDefaults.standard.data(forKey: memoriesKey) else {
            return [] // No data saved yet
        }
        
        do {
            let decoder = JSONDecoder()
            let memories = try decoder.decode([FoodMemory].self, from: data)
            return memories
        } catch {
            print("Error decoding memories from UserDefaults: \(error)")
            return []
        }
    }
    
    /// Saves an array of `FoodMemory` to UserDefaults.
    /// - Parameter memories: The array of `FoodMemory` objects to save.
    func saveMemories(_ memories: [FoodMemory]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(memories)
            UserDefaults.standard.set(data, forKey: memoriesKey)
        } catch {
            print("Error encoding memories for UserDefaults: \(error)")
        }
    }
}
