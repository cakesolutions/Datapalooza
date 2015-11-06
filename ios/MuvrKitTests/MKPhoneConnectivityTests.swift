import Foundation
import XCTest
import WatchConnectivity
@testable import MuvrKit

class MKConnectivityTests : XCTestCase {
    
    ///
    /// A subclass of WCSessionFile that can be used to "transmit" only ``MKSensorData``. It handles
    /// caching the file in a temporary location and encoding.
    ///
    class WCMockSessionFile : WCSessionFile {
        private let _fileURL: NSURL
        private let _metadata: [String : AnyObject]?
        
        override var fileURL: NSURL {
            get {
                return _fileURL
            }
        }
        
        override var metadata: [String : AnyObject]? {
            get {
                return _metadata
            }
        }
        
        ///
        /// Initializes this instance, encoding the ``sensorData`` to a temporary file; and passing-through the ``metadata``
        ///
        init(sensorData: MKSensorData, metadata: [String : AnyObject]) {
            let encoded = sensorData.encode()
            let cachesUrl = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.CachesDirectory, NSSearchPathDomainMask.UserDomainMask, true).first!
            let fileUrl = NSURL(fileURLWithPath: cachesUrl).URLByAppendingPathComponent("sensordata.raw")
            _ = try? NSFileManager.defaultManager().removeItemAtURL(fileUrl)
            encoded.writeToURL(fileUrl, atomically: true)
            
            self._fileURL = fileUrl
            self._metadata = metadata
        }
    }
    
    ///
    /// Implementation of the connectivity delegates
    ///
    class Delegates : MKSensorDataConnectivityDelegate, MKExerciseConnectivitySessionDelegate {
        var accumulated: MKSensorData?
        var new: MKSensorData?
        var session: MKExerciseConnectivitySession?
        
        func sensorDataConnectivityDidReceiveSensorData(accumulated accumulated: MKSensorData, new: MKSensorData, session: MKExerciseConnectivitySession) {
            self.accumulated = accumulated
            self.new = new
        }
        
        func exerciseConnectivitySessionDidEnd(session session: MKExerciseConnectivitySession) {
            if self.session!.id == session.id { self.session = nil }
        }
        
        func exerciseConnectivitySessionDidStart(session session: MKExerciseConnectivitySession) {
            self.session = session
        }
    }
    
    ///
    /// Tests that the delegate fires appropriately with *session start* -> *last data* events only
    ///
    func testStartEnd() {
        let delegates = Delegates()
        let c = MKConnectivity(sensorDataConnectivityDelegate: delegates, exerciseConnectivitySessionDelegate: delegates)
        let start = NSDate(timeIntervalSince1970: 1000)
        c.session(WCSession.defaultSession(), didReceiveUserInfo: ["action":"start", "sessionId":"1234", "exerciseModelId":"arms", "start":start.timeIntervalSince1970])
        XCTAssertEqual(delegates.session!.id, "1234")
        XCTAssertEqual(delegates.session!.exerciseModelId, "arms")
        XCTAssertEqual(delegates.session!.start, start)
        
        let sensorData = try! MKSensorData(types: [.Accelerometer(location: .LeftWrist)], start: 0, samplesPerSecond: 50, samples: [Float](count: 300, repeatedValue: 0))
        let f = WCMockSessionFile(sensorData: sensorData, metadata: ["timestamp":NSTimeInterval(0), "sessionId":"1234", "exerciseModelId":"arms", "start":start.timeIntervalSince1970, "end": NSDate().timeIntervalSince1970])
        // sends last chunk of data
        c.session(WCSession.defaultSession(), didReceiveFile: f)
        
        XCTAssertTrue(delegates.session == nil)
    }

    ///
    /// Tests that the delegate fires appropriately with *session start* -> *data* -> *session end* events
    ///
    func testSendSensorData() {
        let delegates = Delegates()
        let c = MKConnectivity(sensorDataConnectivityDelegate: delegates, exerciseConnectivitySessionDelegate: delegates)
        let start = NSDate()
        c.session(WCSession.defaultSession(), didReceiveUserInfo: ["action":"start", "sessionId":"1234", "exerciseModelId":"arms", "start":start.timeIntervalSince1970])
        
        let sensorData = try! MKSensorData(types: [.Accelerometer(location: .LeftWrist)], start: 0, samplesPerSecond: 50, samples: [Float](count: 300, repeatedValue: 0))
        let f = WCMockSessionFile(sensorData: sensorData, metadata: ["timestamp":NSTimeInterval(0), "sessionId":"1234", "exerciseModelId":"arms", "start":start.timeIntervalSince1970])
        c.session(WCSession.defaultSession(), didReceiveFile: f)
        c.session(WCSession.defaultSession(), didReceiveFile: f)
        
        XCTAssertEqual(delegates.new!, sensorData)
    }
    
}
