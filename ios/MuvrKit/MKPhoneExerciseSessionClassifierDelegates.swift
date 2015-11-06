import Foundation

///
/// Implementations will receive the results of session classification and summarisation
///
public protocol MKSessionClassifierDelegate {
    
    ///
    /// Called when the session classification completes. The session continues even
    /// after the classification.
    ///
    /// - parameter session: the current snapshot of the session
    /// - parameter sensorData: the sensor data collected so far
    ///
    func sessionClassifierDidClassify(session: MKExerciseSession, classified: [MKClassifiedExercise], sensorData: MKSensorData)
    
    ///
    /// The session has ended
    ///
    /// - parameter session: the session that has just ended
    /// - parameter sensorData: the sensor data from the entire session
    ///
    func sessionClassifierDidEnd(session: MKExerciseSession, sensorData: MKSensorData?)
        
    ///
    /// Called when the session starts
    ///
    /// - parameter session: the session that has just started
    ///
    func sessionClassifierDidStart(session: MKExerciseSession)
    
}
