//
//  APIService.swift
//  Nomadish
//
//  Created by Riddhi Munjewar on 8/16/25.
//

import SwiftUI
import CoreLocation

// Define the base URL for your local server.
// Use 127.0.0.1 for the simulator. If running on a real device,
// you must use your computer's local network IP address (e.g., http://192.168.1.10:8000).
let baseURL = "http://127.0.0.1:8000"

enum APIError: Error, LocalizedError {
    case invalidURL
    case requestFailed(String)
    case decodingError
    case serverUnavailable
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .requestFailed(let message):
            return "Request failed: \(message)"
        case .decodingError:
            return "Failed to decode response"
        case .serverUnavailable:
            return "Server is unavailable"
        }
    }
}

class APIService {

    // You'll need a JSON decoder that can handle the date format from Python.
    private var jsonDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase // Handles python_case to swiftCase
        
        // Custom date decoder for ISO8601 format
        let customFormatter = DateFormatter()
        customFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        customFormatter.locale = Locale(identifier: "en_US_POSIX")
        customFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        let isoFormatter = ISO8601DateFormatter()
        
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try ISO8601 format first
            if let date = isoFormatter.date(from: dateString) {
                return date
            }
            
            // Try custom format
            if let date = customFormatter.date(from: dateString) {
                return date
            }
            
            // Try without microseconds
            customFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            if let date = customFormatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
        }
        
        return decoder
    }
    
    // FETCH (GET Request)
    func fetchMemories() async -> Result<[FoodMemory], APIError> {
        guard let url = URL(string: "\(baseURL)/memories") else {
            return .failure(.invalidURL)
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.requestFailed("Invalid response"))
            }
            
            if httpResponse.statusCode == 200 {
                let memories = try jsonDecoder.decode([FoodMemory].self, from: data)
                return .success(memories)
            } else {
                return .failure(.requestFailed("Server returned status code \(httpResponse.statusCode)"))
            }
            
        } catch {
            print("Fetch memories error: \(error)")
            return .failure(.serverUnavailable)
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
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.requestFailed("Invalid response"))
            }
            
            if httpResponse.statusCode == 201 {
                let savedMemory = try jsonDecoder.decode(FoodMemory.self, from: data)
                return .success(savedMemory)
            } else {
                return .failure(.requestFailed("Server returned status code \(httpResponse.statusCode)"))
            }
        } catch {
            print("Add memory error: \(error)")
            return .failure(.serverUnavailable)
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
            guard let httpResponse = response as? HTTPURLResponse else {
                return .requestFailed("Invalid response")
            }
            
            if httpResponse.statusCode == 204 {
                return nil // Success
            } else {
                return .requestFailed("Server returned status code \(httpResponse.statusCode)")
            }
        } catch {
            print("Delete memory error: \(error)")
            return .serverUnavailable
        }
    }
}
