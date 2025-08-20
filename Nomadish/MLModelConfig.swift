import Foundation
import CoreML

struct MLModelConfig {
    
    enum ModelType: String, CaseIterable {
        case food101 = "Food101"
        case customFood = "CustomFoodClassifier"
        case transferLearning = "TransferLearningFood"
        
        var displayName: String {
            switch self {
            case .food101:
                return "Food-101 Dataset Model"
            case .customFood:
                return "Custom Food Classifier"
            case .transferLearning:
                return "Transfer Learning Model"
            }
        }
        
        var description: String {
            switch self {
            case .food101:
                return "Pre-trained model on 101 food categories"
            case .customFood:
                return "Custom model trained on specific food types"
            case .transferLearning:
                return "Model fine-tuned for food recognition"
            }
        }
    }
    
    static let defaultModel = ModelType.food101
    static let inputSize = CGSize(width: 224, height: 224)
    static let confidenceThreshold: Double = 0.3
    static let maxPredictions = 5
    
    static let foodCategories: [String: FoodCategoryInfo] = [
        "pizza": FoodCategoryInfo(
            name: "Pizza 🍕",
            cuisine: "Italian",
            description: "Italian pizza with various toppings",
            commonIngredients: ["dough", "cheese", "tomato sauce", "toppings"],
            confidenceBoost: 1.0
        ),
        "pasta": FoodCategoryInfo(
            name: "Pasta 🍝",
            cuisine: "Italian",
            description: "Italian noodle dish",
            commonIngredients: ["pasta", "sauce", "cheese", "herbs"],
            confidenceBoost: 1.0
        ),
        "sushi": FoodCategoryInfo(
            name: "Sushi 🍣",
            cuisine: "Japanese",
            description: "Japanese rice and fish dish",
            commonIngredients: ["rice", "fish", "seaweed", "vegetables"],
            confidenceBoost: 1.0
        ),
        "ramen": FoodCategoryInfo(
            name: "Ramen 🍜",
            cuisine: "Japanese",
            description: "Japanese noodle soup",
            commonIngredients: ["noodles", "broth", "meat", "vegetables"],
            confidenceBoost: 1.0
        ),
        "burger": FoodCategoryInfo(
            name: "Burger 🍔",
            cuisine: "American",
            description: "Ground meat patty in a bun",
            commonIngredients: ["beef", "bun", "lettuce", "tomato", "cheese"],
            confidenceBoost: 1.0
        ),
        "sandwich": FoodCategoryInfo(
            name: "Sandwich 🥪",
            cuisine: "American",
            description: "Bread with filling",
            commonIngredients: ["bread", "meat", "vegetables", "condiments"],
            confidenceBoost: 1.0
        ),
        "dosa": FoodCategoryInfo(
            name: "Dosa 🥞",
            cuisine: "Indian",
            description: "South Indian crepe",
            commonIngredients: ["rice", "lentils", "spices"],
            confidenceBoost: 1.0
        ),
        "curry": FoodCategoryInfo(
            name: "Curry 🍛",
            cuisine: "Indian",
            description: "Spiced dish with sauce",
            commonIngredients: ["spices", "vegetables", "meat", "sauce"],
            confidenceBoost: 1.0
        ),
        "tacos": FoodCategoryInfo(
            name: "Tacos 🌮",
            cuisine: "Mexican",
            description: "Mexican corn tortilla dish",
            commonIngredients: ["tortilla", "meat", "vegetables", "salsa"],
            confidenceBoost: 1.0
        ),
        "salad": FoodCategoryInfo(
            name: "Salad 🥗",
            cuisine: "International",
            description: "Fresh vegetables and greens",
            commonIngredients: ["lettuce", "vegetables", "dressing"],
            confidenceBoost: 1.0
        ),
        "soup": FoodCategoryInfo(
            name: "Soup 🥣",
            cuisine: "International",
            description: "Liquid food dish",
            commonIngredients: ["broth", "vegetables", "meat", "herbs"],
            confidenceBoost: 1.0
        ),
        "steak": FoodCategoryInfo(
            name: "Steak 🥩",
            cuisine: "International",
            description: "Grilled beef cut",
            commonIngredients: ["beef", "seasonings", "herbs"],
            confidenceBoost: 1.0
        ),
        "fish": FoodCategoryInfo(
            name: "Fish 🐟",
            cuisine: "International",
            description: "Seafood dish",
            commonIngredients: ["fish", "seasonings", "herbs"],
            confidenceBoost: 1.0
        ),
        "chicken": FoodCategoryInfo(
            name: "Chicken 🍗",
            cuisine: "International",
            description: "Poultry dish",
            commonIngredients: ["chicken", "seasonings", "herbs"],
            confidenceBoost: 1.0
        ),
        "ice_cream": FoodCategoryInfo(
            name: "Ice Cream 🍦",
            cuisine: "International",
            description: "Frozen dessert",
            commonIngredients: ["cream", "sugar", "flavorings"],
            confidenceBoost: 1.0
        ),
        "cake": FoodCategoryInfo(
            name: "Cake 🍰",
            cuisine: "International",
            description: "Sweet baked dessert",
            commonIngredients: ["flour", "sugar", "eggs", "butter"],
            confidenceBoost: 1.0
        )
    ]
    
    struct ModelPerformance {
        let accuracy: Double
        let inferenceTime: TimeInterval
        let memoryUsage: Int64
        
        var isGood: Bool {
            accuracy > 0.85 && inferenceTime < 2.0
        }
    }
    
    static func getModelPerformance(for modelType: ModelType) -> ModelPerformance {
        switch modelType {
        case .food101:
            return ModelPerformance(accuracy: 0.88, inferenceTime: 1.2, memoryUsage: 256 * 1024 * 1024)
        case .customFood:
            return ModelPerformance(accuracy: 0.92, inferenceTime: 0.8, memoryUsage: 128 * 1024 * 1024)
        case .transferLearning:
            return ModelPerformance(accuracy: 0.90, inferenceTime: 1.0, memoryUsage: 192 * 1024 * 1024)
        }
    }
}

struct FoodCategoryInfo {
    let name: String
    let cuisine: String
    let description: String
    let commonIngredients: [String]
    let confidenceBoost: Double
}

extension MLModelConfig {
    
    static func loadModel(named modelName: String) -> MLModel? {
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") else {
            print("Could not find Core ML model: \(modelName)")
            return nil
        }
        
        do {
            let model = try MLModel(contentsOf: modelURL)
            print("Successfully loaded Core ML model: \(modelName)")
            return model
        } catch {
            print("Failed to load Core ML model: \(error)")
            return nil
        }
    }
    
    static func validateModel(_ model: MLModel) -> Bool {
        guard let inputDescription = model.modelDescription.inputDescriptionsByName.first else {
            return false
        }
        
        let inputShape = inputDescription.value.multiArrayConstraint?.shape
        guard let shape = inputShape, shape.count >= 3 else {
            return false
        }
        
        let expectedHeight = Int(inputSize.height)
        let expectedWidth = Int(inputSize.width)
        
        return shape[1] == expectedHeight && shape[2] == expectedWidth
    }
}
