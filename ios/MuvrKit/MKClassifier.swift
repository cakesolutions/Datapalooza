import Foundation
import Accelerate

///
/// Possible classification errors
///
public enum MKClassifierError : ErrorType {
    ///
    /// The sensor data does not contain any of the required sensor data types
    ///
    /// - parameter required: the required types
    ///
    case NoSensorDataType(received: [MKSensorDataType], required: [MKSensorDataType])
    
    ///
    /// The sensor data does not contain enough data for the classification
    ///
    /// - parameter required: the required number of rows
    ///
    case NotEnoughRows(received: Int, required: Int)
}

///
/// Classifies the input data according to the model
///
public struct MKClassifier {
    private let model: MKExerciseModel
    private let neuralNet: MKForwardPropagator
    private let windowSize = 400
    private let windowStepSize = 10
    private let numInputs: Int
    private let numClasses: Int
    
    ///
    /// Initializes the classifier given the ``model``.
    ///
    /// - parameter model: the model
    ///
    public init(model: MKExerciseModel) throws {
        self.model = model
        let netConfig = MKForwardPropagatorConfiguration(
            layerConfiguration: model.layerConfig,
            hiddenActivation: ReLUActivation(),
            outputActivation: SigmoidActivation(),
            biasValue: 1.0,
            biasUnits: 1)
        self.neuralNet = try MKForwardPropagator.configured(netConfig, weights: model.weights)
        
        self.numInputs = self.model.layerConfig.first!
        self.numClasses = self.model.exerciseIds.count
    }
    
    ///
    /// Classifies the data in the ``block``, returning up to ``maxResults`` results. The classifier will
    /// take an appropriate slice of the data from the given block; ideally, the slice is the exact data set.
    /// This is driven by the model, and so it is important to ensure that the right instance of the classifier
    /// is used to do the classification.
    ///
    /// - parameter block: the received sensor data
    ///
    public func classify(block block: MKSensorData, maxResults: Int) throws -> [MKClassifiedExercise] {
        // in the outer function, we perform the common decoding and basic checking
        let (dimension, m) = block.samples(along: model.sensorDataTypes)
        if dimension == 0 {
            // we could not find any slice that the model requires
            throw MKClassifierError.NoSensorDataType(received: block.types, required: model.sensorDataTypes)
        }
        
        let rowCount = m.count / dimension
        if rowCount < windowSize {
            // not enough input for classification
            throw MKClassifierError.NotEnoughRows(received: block.rowCount, required: windowSize)
        }

        let numWindows = (rowCount - windowSize) / windowStepSize + 1
        let duration = Double(windowStepSize) / Double(block.samplesPerSecond)
        
        let cews: [MKClassifiedExerciseWindow] = try (0..<numWindows).map { window in
            let offset = dimension * windowStepSize * window
            // NSLog("bytes \(offset)-\(offset + windowSize * sizeof(Double)); length \(doubleM.count * sizeof(Double))")
            let featureMatrix: UnsafePointer<Float> = UnsafePointer(m).advancedBy(offset)
            let windowPrediction = try neuralNet.predictFeatureMatrix(featureMatrix, length: dimension * windowSize)
            let classRanking = (0..<numClasses).sort { x, y in
                return windowPrediction[x] > windowPrediction[y]
            }
            let resultCount = min(maxResults, numClasses)
            let start = duration * Double(window)
            let classifiedExerciseBlocks: [MKClassifiedExerciseBlock] = (0..<resultCount).flatMap { i in
                let labelIndex = classRanking[i]
                
                let labelName = self.model.exerciseIds[labelIndex]
                let probability = windowPrediction[labelIndex]
                if probability > 0.7 {
                    return MKClassifiedExerciseBlock(confidence: Double(probability), exerciseId: labelName, duration: duration, offset: start)
                }
                return nil
            }
            return MKClassifiedExerciseWindow(window: window, classifiedExerciseBlocks: classifiedExerciseBlocks)
        }
        
        if cews.isEmpty { return [] }
        
        var result: [MKClassifiedExerciseBlock] = []
        var accumulator: MKClassifiedExerciseBlock? = nil
        for var i = 0; i < cews.count; ++i {
            NSLog("\(cews[i])")
            if let current = cews[i].classifiedExerciseBlocks.first {
                if accumulator == nil {
                    accumulator = current
                } else if current.isRoughlyEqual(accumulator!) {
                    accumulator!.extend(current)
                } else {
                    result.append(accumulator!)
                    accumulator = current
                }
            } else {
                if let a = accumulator { result.append(a) }
                accumulator = nil
            }
        }
        if let a = accumulator { result.append(a) }
        
        return result.filter { $0.duration >= self.model.minimumDuration }.map { x in
            return MKClassifiedExercise(confidence: x.confidence, exerciseId: x.exerciseId, duration: x.duration, offset: x.offset, repetitions: nil, intensity: nil, weight: nil)
        }
    }    
}

struct MKClassifiedExerciseBlock {
    var confidence: Double
    let exerciseId: MKExerciseId
    var duration: MKTimestamp
    let offset: MKTimestamp
    
    mutating func extend(by: MKClassifiedExerciseBlock) {
        // the new confidence the average confidence of both blocks 
        // use the duration to apply correct weights in average computation
        self.confidence = (self.confidence * self.duration + by.confidence * by.duration) / (self.duration + by.duration)
        self.duration = self.duration + by.duration
    }

    func isRoughlyEqual(to: MKClassifiedExerciseBlock) -> Bool {
        return self.exerciseId == to.exerciseId && abs(self.confidence - to.confidence) < 0.1
    }
}


struct MKClassifiedExerciseWindow {
    let window: Int
    let classifiedExerciseBlocks: [MKClassifiedExerciseBlock]
}
