import Foundation
import CoreMotion
import WatchConnectivity

///
/// The Watch -> iOS connectivity; deals with the underlying mechanism of data transfer and sensor
/// data recording.
///
/// The main key concept in communication is that it is possible to record multiple sessions even
/// with the counterpart missing. (The data gets lost after 3 days, though.)
///
/// The communication proceeds as follows:
/// - *begin* as simple app message so that the phone can modify its UI if it is
///    reachable at the start of the session.
/// - *file* as file with metadata that contains all information contained in the
///   begin message. This allows the phone to pick up running sessions if it were
///   not reachable at the start.
///
/// Additionally, the *file* message's metadata may include the ``end`` property, which indicates
/// that the file being received is the last file in the session, and that the session should finish.
///
public final class MKConnectivity : NSObject, WCSessionDelegate {
    public typealias OnFileTransferDone = () -> Void
    
    private var onFileTransferDone: OnFileTransferDone?
    internal var transferringRealTime: Bool = false
    
    private let recorder: CMSensorRecorder = CMSensorRecorder()
    private(set) public var sessions: [MKExerciseSession: MKExerciseSessionProperties] = [:]
    private let transferQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)

    ///
    /// Initializes this instance, assigninf the metadata ans sensorData delegates.
    /// This call should only happen once
    ///
    /// -parameter metadata: the metadata delegate
    /// -parameter sensorData: the sensor data delegate
    ///
    public init(delegate: MKMetadataConnectivityDelegate) {
        super.init()
        WCSession.defaultSession().delegate = self
        WCSession.defaultSession().activateSession()
        
        delegate.metadataConnectivityDidReceiveExerciseModelMetadata(defaultExerciseModelMetadata)
    }
    
    ///
    /// Returns the first encountered un-ended session
    ///
    public var currentSession: (MKExerciseSession, MKExerciseSessionProperties)? {
        for (session, props) in sessions where props.end == nil {
            return (session, props)
        }
        
        return nil
    }
    
    ///
    /// Sends the sensor data ``data`` invoking ``onDone`` when the operation completes. The callee should
    /// check the value of ``SendDataResult`` to see if it should retry the transimssion, or if it can safely
    /// trim the data it has collected so far.
    ///
    /// - parameter data: the sensor data to be sent
    /// - parameter onDone: the function to be executed on completion (success or error)
    ///
    func transferSensorDataBatch(data: MKSensorData, session: MKExerciseSession, props: MKExerciseSessionProperties?, onDone: OnFileTransferDone) {
        if onFileTransferDone == nil {
            onFileTransferDone = onDone
            let encoded = data.encode()
            let documentsUrl = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true).first!
            let fileUrl = NSURL(fileURLWithPath: documentsUrl).URLByAppendingPathComponent("sensordata.raw")
            
            if encoded.writeToURL(fileUrl, atomically: true) {
                var metadata = session.metadata
                if let props = props { metadata = metadata.plus(props.metadata) }
                metadata["timestamp"] = NSDate().timeIntervalSince1970
                WCSession.defaultSession().transferFile(fileUrl, metadata: metadata)
            }
        }
    }
    
    ///
    /// Transfer sensor data if there is a not-yet-ended demo session
    ///
    /// - parameter sensorData: the sensor data to be transferred
    ///
    public func transferDemoSensorDataForCurrentSession(sensorData: MKSensorData) {
        for (session, props) in sessions where props.end == nil && session.demo {
            self.sessions[session] = props.with(accelerometerStart: NSDate(), recorded: sensorData.rowCount)
            transferSensorDataBatch(sensorData, session: session, props: props) {
                self.sessions[session] = props.with(sent: sensorData.rowCount)
            }
            NSLog("Transferred.")
            return
        }
    }
    
    ///
    /// Called when the file transfer completes.
    ///
    public func session(session: WCSession, didFinishFileTransfer fileTransfer: WCSessionFileTransfer, error: NSError?) {
        if let onDone = onFileTransferDone {
            onDone()
            onFileTransferDone = nil
        }
    }
    
    ///
    /// Ends the current session
    ///
    public func endLastSession() {
        if let (session, props) = mostImportantSessionsEntry() {
            sessions[session] = props.with(end: NSDate())
            execute()
        }
    }
    
    ///
    /// Returns the most important session for processing, if available
    ///
    private func mostImportantSessionsEntry() -> (MKExerciseSession, MKExerciseSessionProperties)? {
        // pick the not-yet-ended session first
        for (session, props) in sessions {
            if props.end == nil {
                return (session, props)
            }
        }
        
        // then whichever one remains
        return sessions.first
    }
    
    ///
    /// Implements the protocol for the W -> P communication by collecting the data from the sensor recorder,
    /// constructing the messages and dealing with session clean-up.
    ///
    public func execute() {
        func getSamples(from from: NSDate, to: NSDate, requireAll: Bool, demo: Bool) -> MKSensorData? {
            var simulatedSamples = demo
            
            #if (arch(i386) || arch(x86_64))
                simulatedSamples = true
            #endif
            
            let duration = to.timeIntervalSinceDate(from)
            let sampleCount = 3 * 50 * Int(duration)
            
            if simulatedSamples {
                let samples = (0..<sampleCount).map { _ in return Float(0) }
                return try! MKSensorData(types: [.Accelerometer(location: .LeftWrist)], start: 0, samplesPerSecond: 50, samples: samples)
            } else {
                return recorder.accelerometerDataFromDate(from, toDate: to).flatMap { (recordedData: CMSensorDataList) -> MKSensorData? in
                    let samples = recordedData.enumerate().flatMap { (_, e) -> [Float] in
                        if let data = e as? CMRecordedAccelerometerData {
                            return [Float(data.acceleration.x), Float(data.acceleration.y), Float(data.acceleration.z)]
                        }
                        return []
                    }
                    // remember to check for truly complete block
                    // it's OK to leave out the very last window
                    if samples.count < (sampleCount - 1200) && requireAll {
                        NSLog("Not yet flushed buffer. Expected \(sampleCount), got \(samples.count)")
                        return nil
                    }
                    return try! MKSensorData(types: [.Accelerometer(location: .LeftWrist)], start: 0, samplesPerSecond: 50, samples: samples)
                }
            }
        }
        
        ///
        /// We process the first session in our ``sessions`` map; if the sensor data is accessible
        /// we will transmit the data to the counterpart. If, as a result of processing this session,
        /// we remove it, we move on to the next session.
        ///
        func processFirstSession() {
            objc_sync_enter(self)
            
            defer { objc_sync_exit(self) }
            
            // pick the most important entry
            guard let (session, props) = mostImportantSessionsEntry() else {
                NSLog("No session")
                return
            }
            
            // compute the dates
            let from = props.accelerometerStart ?? session.start
            let to = props.end ?? NSDate()
            
            // if this session is meant to end, we require all sensor data to be available.
            // there is a neater way, but this saves memory
            guard let sensorData = getSamples(from: from, to: to, requireAll: props.end != nil, demo: session.demo) else {
                NSLog("Not enough sensor data in \(from) - \(to)")
                return
            }

            // set the expected range of samples on the next call
            let updatedProps = props.with(accelerometerStart: from.dateByAddingTimeInterval(sensorData.duration), recorded: sensorData.rowCount)
            self.sessions[session] = updatedProps
            
            // transfer what we have so far
            transferSensorDataBatch(sensorData, session: session, props: props) {
                // update the session with incremented sent counter
                if props.end == nil {
                    self.sessions[session] = updatedProps.with(sent: sensorData.rowCount)
                } else {
                    self.sessions.removeValueForKey(session)
                    // we're done with this session, we can move on to the next one
                    dispatch_async(self.transferQueue, processFirstSession)
                }
                NSLog("Transferred \(sensorData.rowCount) samples; with \(self.sessions.count) active sessions.")
            }
        }
        
        // ask the SDR to record for another 12 hours just in case.
        recorder.recordAccelerometerForDuration(43200)

        // check whether there is something to be done at all.
        NSLog("beginTransfer(); sessions = \(sessions)")
//        if !WCSession.defaultSession().reachable {
//            NSLog("Not reachable; not sending.")
//            return
//        }
        if sessions.count == 0 {
            NSLog("Reachable; no active sessions.")
            return
        }
        
        // it makes sense to continue the work.
        NSLog("Reachable; with \(sessions.count) active sessions.")
        
        // TODO: It would be nice to be able to flush the sensor data recorder
        // recorder.flush()
        dispatch_async(transferQueue, processFirstSession)
        
        NSLog("Done; with \(sessions.count) active sessions.")
    }

        
    ///
    /// Starts the exercise session with the given ``modelId`` and ``demo`` mode. In demo mode,
    /// the caller should explicitly call ``transferDemoSensorDataForCurrentSession``.
    ///
    /// - parameter modelId: the model id so that the phone can properly classify the data
    /// - parameter demo: set for demo mode
    ///
    public func startSession(modelId: MKExerciseModelId, demo: Bool) {
        let session = MKExerciseSession(id: NSUUID().UUIDString, start: NSDate(), demo: demo, modelId: modelId)
        sessions[session] = MKExerciseSessionProperties(accelerometerStart: nil, end: nil, recorded: 0, sent: 0)
        WCSession.defaultSession().transferUserInfo(session.metadata)
    }
    
    /// The debug description
    public override var description: String {
        if let (s, p) = sessions.first {
            return "\(sessions.count): \(s.id.characters.first!): \(s.start)-\(p.end)"
        }
        return "0"
    }

}

///
/// Convenience addition to ``[K:V]``
///
private extension Dictionary {
    
    ///
    /// Returns a new ``[K:V]`` by appending ``dict``
    ///
    /// - parameter dict: the dictionary to append
    /// - returns: self + dict
    ///
    func plus(dict: [Key : Value]) -> [Key : Value] {
        var result = self
        for (k, v) in dict {
            result.updateValue(v, forKey: k)
        }
        return result
    }
    
}

///
/// Adds the ``metadata`` property that can be used in P -> W comms
/// See ``MKExerciseConnectivitySession`` for the phone counterpart.
///
private extension MKExerciseSession {

    var metadata: [String : AnyObject] {
        return [
            "exerciseModelId" : modelId,
            "sessionId" : id,
            "start" : start.timeIntervalSince1970
        ]
    }
    
}

///
/// Adds the ``metadata`` property that can be used in P -> W comms
/// See ``MKExerciseConnectivitySession`` for the phone counterpart.
///
private extension MKExerciseSessionProperties {
    
    var metadata: [String : AnyObject] {
        var md: [String : AnyObject] = [
            "recorded" : recorded,
            "sent" : sent,
        ]
        if let end = end { md["end"] = end.timeIntervalSince1970 }
        if let accelerometerStart = accelerometerStart { md["accelerometerStart"] = accelerometerStart.timeIntervalSince1970 }
        
        return md
    }
    
}

///
/// Allows the ``CMSensorDataList`` to be iterated over; unfortunately, the iteration
/// is not specifically-typed.
///
extension CMSensorDataList : SequenceType {
    
    public func generate() -> NSFastGenerator {
        return NSFastGenerator(self)
    }
}

#if (arch(i386) || arch(x86_64))
    
    class CMFakeAccelerometerData : CMAccelerometerData {
        override internal var acceleration: CMAcceleration {
            get {
                return CMAcceleration(x: 0, y: 0, z: 0)
            }
        }
    }
    
#endif
