import Foundation

public struct MKExerciseConnectivitySession {
    /// the session id
    internal(set) public var id: String
    /// the model id
    internal(set) public var exerciseModelId: MKExerciseModelId
    /// the start timestamp
    internal(set) public var start: NSDate
    /// the end timestamp
    internal(set) public var end: NSDate?
    /// accumulated sensor data
    internal(set) public var sensorData: MKSensorData?
    /// the file datastamps
    internal var sensorDataFileTimestamps = Set<NSTimeInterval>()
 
    ///
    /// Initialises this instance, assigning the fields
    ///
    /// - parameter id: the session identity
    /// - parameter exerciseModelId: the exercise model identity
    /// - parameter startDate: the start date
    ///
    internal init(id: String, exerciseModelId: String, start: NSDate, end: NSDate?) {
        self.id = id
        self.exerciseModelId = exerciseModelId
        self.start = start
        self.end = end
    }
    
    ///
    /// "Parses" the ``metadata`` to construct the ``MKExerciseConnectivitySession``, returning
    /// the parsed instance or nil.
    ///
    /// - parameter metadata: the metadata to be parsed
    /// - returns: the parsed instance
    ///
    internal static func fromMetadata(metadata: [String : AnyObject]) -> MKExerciseConnectivitySession? {
        let end = (metadata["end"] as? Double).map { NSDate(timeIntervalSince1970: $0) }
        if let exerciseModelId = metadata["exerciseModelId"] as? MKExerciseModelId,
               sessionId = metadata["sessionId"] as? String,
               startTimestamp = metadata["start"] as? Double {
                return MKExerciseConnectivitySession(
                    id: sessionId,
                    exerciseModelId: exerciseModelId,
                    start: NSDate(timeIntervalSince1970: startTimestamp),
                    end: end)
        }
        return nil
    }
}
