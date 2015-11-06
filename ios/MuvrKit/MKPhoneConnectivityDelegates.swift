import Foundation

///
///
///
public protocol MKSensorDataConnectivityDelegate {
    
    ///
    /// Called when the application receives new exercise models
    ///
    /// - parameter accumulated: the accumulated sensor data
    /// - parameter new: only the new received block
    /// - parameter session: the session
    ///
    func sensorDataConnectivityDidReceiveSensorData(accumulated accumulated: MKSensorData, new: MKSensorData, session: MKExerciseConnectivitySession)
    
}

///
public protocol MKExerciseConnectivitySessionDelegate {
   
    ///
    /// Called with the watch starts the session with the selected ``exerciseModelId``.
    ///
    /// - parameter exerciseModelId: the exercise model id
    /// - parameter session: the session that has just started
    ///
    func exerciseConnectivitySessionDidStart(session session: MKExerciseConnectivitySession)
    
    ///
    /// Called when the watch ends the session
    /// 
    /// - parameter session: the session that has just ended
    ///
    func exerciseConnectivitySessionDidEnd(session session: MKExerciseConnectivitySession)
    
}
