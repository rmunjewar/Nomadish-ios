//
//  FoodClassifier.swift
//  Nomadish
//
//  Created by Riddhi Munjewar on 8/15/25.
//

import SwiftUI
// placeholder class for ML Model (need CoreML model)

class FoodClassifier {
    private let possibleFoods = ["Pizza 🍕", "Sushi 🍣", "Dosa 🥞", "Burger 🍔", "Salad 🥗", "Pasta 🍝"]
        
        /// Simulates classifying an image and returns a predicted food name.
        /// - Parameters:
        ///   - image: The UIImage to be classified.
        ///   - completion: A closure that returns the predicted name (String) or nil.
        func classify(image: UIImage, completion: @escaping (String?) -> Void) {
            // This is where you would run your actual Core ML model inference.
            // For now, we'll just pretend it's working in the background.
            print("ML Model: Classifying image...")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                let prediction = self.possibleFoods.randomElement()
                print("ML Model: Predicted '\(prediction ?? "Nothing")'")
                completion(prediction)
            }
        }
    }
