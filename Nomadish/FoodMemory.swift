//
//  FoodMemory.swift - data structure for a food memory.
//  Nomadish
//
//  Created by Riddhi Munjewar on 8/15/25.
//

import Foundation
import SwiftUI
import CoreLocation

struct FoodMemory: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var name: String
    var dateAdded: Date
    var notes: String
    var rating: Int
    var imageUrl: URL?
    
    var photo: UIImage?
    var coordinate: CLLocationCoordinate2D
    
    enum CodingKeys: String, CodingKey {
        case id, name, dateAdded, notes, rating, latitude, longitude
        case imageURL
    }
    
    init(id: String = UUID().uuidString, name: String, dateAdded: Date, notes: String, rating: Int, photo: UIImage?, coordinate: CLLocationCoordinate2D) {
        self.id = id
        self.name = name
        self.dateAdded = dateAdded
        self.notes = notes
        self.rating = rating
        self.photo = photo
        self.coordinate = coordinate
    }
    
    // custom decorder to handle converting lat.long from JSON to Coordinate 2d
    init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            name = try container.decode(String.self, forKey: .name)
            dateAdded = try container.decode(Date.self, forKey: .dateAdded)
            notes = try container.decode(String.self, forKey: .notes)
            rating = try container.decode(Int.self, forKey: .rating)
            
            let latitude = try container.decode(Double.self, forKey: .latitude)
            let longitude = try container.decode(Double.self, forKey: .longitude)
            coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            photo = nil
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(name, forKey: .name)
            try container.encode(dateAdded, forKey: .dateAdded)
            try container.encode(notes, forKey: .notes)
            try container.encode(rating, forKey: .rating)
            try container.encode(coordinate.latitude, forKey: .latitude)
            try container.encode(coordinate.longitude, forKey: .longitude)
        }
        
        static func == (lhs: FoodMemory, rhs: FoodMemory) -> Bool {
            lhs.id == rhs.id
        }
    }

