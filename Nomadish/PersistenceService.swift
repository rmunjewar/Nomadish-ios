//
//  PersistenceService.swift
//  Nomadish
//
//  Created by Riddhi Munjewar on 8/16/25.
//


import Foundation

/// A service dedicated to saving and loading Codable data to the device's file system.
class PersistenceService {
    
    // The URL for the file where memories will be stored.
    private var fileURL: URL {
        do {
            // Gets the app's main document directory URL.
            let directory = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            // Appends our custom filename to the directory path.
            return directory.appendingPathComponent("foodmemories.json")
        } catch {
            // If we can't get the directory, it's a critical error.
            fatalError("Failed to find document directory: \(error.localizedDescription)")
        }
    }
    
    /// Loads an array of FoodMemory from the JSON file.
    /// - Returns: An array of `FoodMemory` or an empty array if the file doesn't exist or fails to decode.
    func loadMemories() -> [FoodMemory] {
        // Ensure the file actually exists before trying to read it.
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("Persistence: No data file found, starting fresh.")
            return []
        }
        
        do {
            // Load the raw data from the file.
            let data = try Data(contentsOf: fileURL)
            // Create a JSON decoder.
            let decoder = JSONDecoder()
            // Decode the data into our array of FoodMemory objects.
            let memories = try decoder.decode([FoodMemory].self, from: data)
            print("Persistence: Successfully loaded \(memories.count) memories from file.")
            return memories
        } catch {
            // Handle potential errors during reading or decoding.
            print("Persistence: Failed to load or decode memories: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Saves an array of FoodMemory to the JSON file.
    /// - Parameter memories: The array of `FoodMemory` to save.
    func saveMemories(_ memories: [FoodMemory]) {
        do {
            // Create a JSON encoder for converting our object to data.
            let encoder = JSONEncoder()
            // Make the JSON output pretty and easier to debug.
            encoder.outputFormatting = .prettyPrinted
            // Encode the array into JSON data.
            let data = try encoder.encode(memories)
            // Write the data to our file URL.
            try data.write(to: fileURL, options: .atomic)
            print("Persistence: Successfully saved \(memories.count) memories to file.")
        } catch {
            // Handle potential errors during encoding or writing to the file.
            print("Persistence: Failed to save memories: \(error.localizedDescription)")
        }
    }
}
