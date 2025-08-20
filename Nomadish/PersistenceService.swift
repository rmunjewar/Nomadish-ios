// PersistenceService.swift
// Nomadish
//
// Created by Riddhi Munjewar on 8/17/25.
//

import Foundation

/// A service responsible for saving and loading food memories locally.
class PersistenceService {
    
    private let memoriesKey = "FoodMemoriesCache"
    
    func loadMemories() -> [FoodMemory] {
        guard let data = UserDefaults.standard.data(forKey: memoriesKey) else {
            return []
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
