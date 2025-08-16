//
//  APIService.swift
//  Nomadish
//
//  Created by Riddhi Munjewar on 8/16/25.
//
// APIService.swift

import SwiftUI
import CoreLocation

// Define the base URL for your local server.
// Use 127.0.0.1 for the simulator. If running on a real device,
// you must use your computer's local network IP address (e.g., http://192.168.1.10:8000).
let baseURL = "http://127.0.0.1:8000"

enum APIError: Error {
    case invalidURL
    case requestFailed(String)
    case decodingError
}

class APIService {

    // You'll need a JSON decoder that can handle the date format from Python.
    private var jsonDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase // Handles python_case to swiftCase
        decoder.dateDecodingStrategy = .iso8601 // Handles Python's datetime format
        return decoder
    }
    
    // FETCH (GET Request)
    func fetchMemories() async -> Result<[FoodMemory], APIError> {
        guard let url = URL(string: "\(baseURL)/memories") else {
            return .failure(.invalidURL)
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let memories = try jsonDecoder.decode([FoodMemory].self, from: data)
            
            // Note: We are now decoding the server response, so we need a Codable FoodMemory.
            // You will need to adjust your FoodMemory model in Swift to match this.
            // I'll provide the updated Swift model below.
            
            return .success(memories)
        } catch {
            return .failure(.requestFailed(error.localizedDescription))
        }
    }
    
    // ADD (POST Request with Image Upload)
    func addMemory(_ memory: FoodMemory, photo: UIImage) async -> Result<FoodMemory, APIError> {
        guard let url = URL(string: "\(baseURL)/memories") else {
            return .failure(.invalidURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Convert the UIImage to JPEG data
        guard let imageData = photo.jpegData(compressionQuality: 0.8) else {
            return .failure(.requestFailed("Could not convert image to JPEG data."))
        }
        
        // Create the multipart/form-data body
        var body = Data()
        
        // Add form fields
        let formFields = [
            "name": memory.name,
            "notes": memory.notes,
            "rating": String(memory.rating),
            "latitude": String(memory.coordinate.latitude),
            "longitude": String(memory.coordinate.longitude)
        ]
        
        for (key, value) in formFields {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        // Add image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        // End of body
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        do {
            let (data, response) = try await URLSession.shared.upload(for: request, from: body)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
                return .failure(.requestFailed("Server returned non-201 status code."))
            }

            let savedMemory = try jsonDecoder.decode(FoodMemory.self, from: data)
            return .success(savedMemory)
        } catch {
            return .failure(.requestFailed(error.localizedDescription))
        }
    }
    
    // DELETE (DELETE Request)
    func deleteMemory(withId memoryId: String) async -> APIError? {
        guard let url = URL(string: "\(baseURL)/memories/\(memoryId)") else {
            return .invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 204 else {
                return .requestFailed("Delete request failed.")
            }
            return nil // Success
        } catch {
            return .requestFailed(error.localizedDescription)
        }
    }
}
