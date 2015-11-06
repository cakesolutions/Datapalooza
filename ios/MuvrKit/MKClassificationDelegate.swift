import Foundation

///
/// Reports results of exercise classification and estimation
///
protocol MKClassificationDelegate {
    
    ///
    /// Called when the classification completes, reporting the result of the classification
    /// and the data that was used to base the classification on.
    ///
    /// - parameter classified: the array of classified exercises
    /// - parameter block: the block of data used for the classification
    ///
    func classificationCompleted(classified: [MKClassifiedExercise], fromSensorData data: MKSensorData)
    
    ///
    /// Called when the classification has enough data to make an estimation
    ///
    /// - parameter estimated: the estimated exercises
    ///
    func classificationEstimated(estimated: [MKClassifiedExercise])
    
}
