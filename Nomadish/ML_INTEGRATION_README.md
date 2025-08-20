# ML Integration Guide for Nomadish

This guide explains how to integrate real Core ML models for food classification in the Nomadish app.

## Current Implementation

The app currently uses a simulated ML system that demonstrates the UI and workflow for food classification. The system includes:

- **Image preprocessing pipeline** with specialized filters for food images
- **Confidence scoring** and alternative suggestions
- **Food category management** with detailed information
- **Performance monitoring** and model validation

## Integrating Real Core ML Models

### 1. Prepare Your Model

You can use several approaches:

#### Option A: Pre-trained Food-101 Model

- Download a pre-trained model from [Apple's Model Gallery](https://developer.apple.com/machine-learning/models/)
- Convert to Core ML format using `coremltools`
- Supports 101 food categories

#### Option B: Custom Transfer Learning Model

- Use a pre-trained model (ResNet, MobileNet, etc.)
- Fine-tune on your own food dataset
- Export as Core ML model

#### Option C: Train from Scratch

- Build a custom CNN for food classification
- Train on your food dataset
- Export as Core ML model

### 2. Model Requirements

Your Core ML model should:

- Accept 224x224 pixel images as input
- Output classification probabilities
- Support the food categories defined in `MLModelConfig.swift`
- Have inference time < 2 seconds
- Target accuracy > 85%

### 3. Integration Steps

#### Step 1: Add Model to Bundle

1. Drag your `.mlmodel` file into the Xcode project
2. Ensure it's added to the app target
3. Verify the model appears in the bundle

#### Step 2: Update FoodClassifier.swift

Replace the simulated classification with real model inference:

```swift
private func performClassification(on image: UIImage, completion: @escaping (ClassificationResult?) -> Void) {
    guard let cgImage = image.cgImage else {
        completion(nil)
        return
    }

    // Load your actual Core ML model
    guard let model = MLModelConfig.loadModel(named: "YourFoodModel") else {
        completion(nil)
        return
    }

    // Create Vision request with your model
    let request = VNCoreMLRequest { [weak self] request, error in
        // Process real classification results
        guard let results = request.results as? [VNClassificationObservation] else {
            completion(nil)
            return
        }

        let classification = self?.processRealClassificationResults(results)
        completion(classification)
    }

    // Configure and perform request
    request.imageCropAndScaleOption = .centerCrop
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

    DispatchQueue.global(qos: .userInitiated).async {
        do {
            try handler.perform([request])
        } catch {
            print("Classification failed: \(error)")
            DispatchQueue.main.async {
                completion(nil)
            }
        }
    }
}
```

#### Step 3: Update MLModelConfig.swift

Add your model to the supported types:

```swift
enum ModelType: String, CaseIterable {
    case yourModel = "YourFoodModel"
    // ... existing cases

    var displayName: String {
        switch self {
        case .yourModel:
            return "Your Custom Food Classifier"
        // ... existing cases
        }
    }
}
```

### 4. Model Performance Optimization

#### Image Preprocessing

The app includes advanced image preprocessing:

- **Resizing** to 224x224 pixels
- **Color enhancement** for food recognition
- **Noise reduction** for cleaner classification
- **Type-specific enhancements** for different cuisines

#### Performance Monitoring

Monitor your model's performance:

- **Inference time** should be < 2 seconds
- **Memory usage** should be reasonable
- **Accuracy** should be > 85%

### 5. Testing Your Model

1. **Unit Tests**: Test model loading and validation
2. **Integration Tests**: Test with sample food images
3. **Performance Tests**: Measure inference time and memory usage
4. **User Testing**: Test with real photos from users

### 6. Example Model Integration

Here's a complete example of integrating a real model:

```swift
class RealFoodClassifier: ObservableObject {
    private var foodModel: VNCoreMLModel?

    init() {
        loadModel()
    }

    private func loadModel() {
        guard let model = MLModelConfig.loadModel(named: "FoodClassifier") else {
            print("Failed to load model")
            return
        }

        do {
            foodModel = try VNCoreMLModel(for: model)
            print("Model loaded successfully")
        } catch {
            print("Failed to create Vision model: \(error)")
        }
    }

    func classify(image: UIImage, completion: @escaping (ClassificationResult?) -> Void) {
        guard let model = foodModel,
              let cgImage = image.cgImage else {
            completion(nil)
            return
        }

        let request = VNCoreMLRequest(model: model) { request, error in
            // Process results
            guard let results = request.results as? [VNClassificationObservation] else {
                completion(nil)
                return
            }

            let topResult = results.first
            let classification = ClassificationResult(
                name: topResult?.identifier ?? "Unknown",
                confidence: Double(topResult?.confidence ?? 0),
                category: topResult?.identifier ?? "unknown",
                description: "Classified food item",
                alternatives: Array(results.dropFirst().prefix(3).map { $0.identifier })
            )

            completion(classification)
        }

        request.imageCropAndScaleOption = .centerCrop

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
}
```

## Troubleshooting

### Common Issues

1. **Model Loading Fails**

   - Check model file is in the app bundle
   - Verify model format is correct
   - Check model compatibility with iOS version

2. **Poor Classification Results**

   - Ensure input images are properly preprocessed
   - Check model was trained on similar data
   - Verify image format matches training data

3. **Slow Performance**
   - Use smaller model architectures
   - Optimize image preprocessing
   - Consider model quantization

### Performance Tips

- **Use Metal Performance Shaders** for image processing
- **Batch processing** for multiple images
- **Model quantization** for smaller file sizes
- **Background processing** to avoid blocking UI

## Next Steps

1. **Train or obtain** a food classification model
2. **Convert to Core ML** format
3. **Integrate** using the provided examples
4. **Test and optimize** performance
5. **Deploy** to production

## Resources

- [Core ML Documentation](https://developer.apple.com/documentation/coreml)
- [Vision Framework](https://developer.apple.com/documentation/vision)
- [Core ML Tools](https://github.com/apple/coremltools)
- [Apple ML Examples](https://developer.apple.com/machine-learning/examples/)

## Support

For issues with ML integration:

1. Check the troubleshooting section
2. Review Core ML documentation
3. Test with sample models first
4. Ensure proper error handling
