import Foundation

public struct MKExerciseModel {
    /// the network topology
    internal let layerConfig: [Int]
    /// the network weights
    internal let weights: [Float]
    /// the required sensor data types
    internal let sensorDataTypes: [MKSensorDataType]
    /// the minimum set duration
    internal let minimumDuration: MKDuration
    /// the exercises as labels
    public let exerciseIds: [MKExerciseId]
    
    public init(layerConfig: [Int], weights: [Float], sensorDataTypes: [MKSensorDataType], exerciseIds: [MKExerciseId], minimumDuration: MKDuration) {
        self.layerConfig = layerConfig
        self.sensorDataTypes = sensorDataTypes
        self.weights = weights
        self.exerciseIds = exerciseIds
        self.minimumDuration = minimumDuration
    }
    
    public static func loadWeightsFromFile(path: String) -> [Float] {
        let data = NSData(contentsOfFile: path)!
        let count = data.length / sizeof(Float)
        // create array of appropriate length:
        var weights = [Float](count: count, repeatedValue: 0)
        // copy bytes into array
        data.getBytes(&weights, length: data.length)
        return weights
    }
    
}
