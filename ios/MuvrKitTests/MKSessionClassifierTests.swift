import Foundation
import XCTest
@testable import MuvrKit

class MKSessionClassifierTests : XCTestCase, MKExerciseModelSource {
 
    ///
    /// Implementation of the ``MKSessionClassifierDelegate`` that fires the matching ``XCTestExpectation``s
    /// so that the test can be executed asynchronously.
    ///
    class Delegate : MKSessionClassifierDelegate {
        var classified: MKExerciseSession?
        var ended: MKExerciseSession?
        var started: MKExerciseSession?
        
        private let classifyExpectation: XCTestExpectation
        
        ///
        /// Initialises this instance, assigning the ``classifyExpectation`` and ``summariseExpectation``.
        ///
        init(onClassify classifyExpectation: XCTestExpectation) {
            self.classifyExpectation = classifyExpectation
        }
        
        func sessionClassifierDidStart(session: MKExerciseSession) {
            self.started = session
        }

        func sessionClassifierDidClassify(session: MKExerciseSession, classified: [MKClassifiedExercise], sensorData: MKSensorData) {
            self.classified = session
            self.classifyExpectation.fulfill()
        }
        
        func sessionClassifierDidEnd(session: MKExerciseSession, sensorData: MKSensorData?) {
            self.ended = session
        }
    }
    
    func getExerciseModel(id id: MKExerciseModelId) -> MKExerciseModel {
        let modelPath = NSBundle(forClass: MKClassifierTests.self).pathForResource("model-3", ofType: "raw")!
        let weights = MKExerciseModel.loadWeightsFromFile(modelPath)
        let model = MKExerciseModel(layerConfig: [1200, 250, 100, 3], weights: weights,
            sensorDataTypes: [.Accelerometer(location: .LeftWrist)],
            exerciseIds: ["1", "2", "3"],
            minimumDuration: 0)

        return model
    }
    
    ///
    /// Tests that the simple flow of start -> one block of sensor data -> end works as expected, namely that:
    /// - classification triggers some time after receiving sensor data
    /// - summary triggers some time after ending the session
    ///
    func testSimpleSessionFlow() {
        let classifyExpectation = expectationWithDescription("classify")
        
        let delegate = Delegate(onClassify: classifyExpectation)
        let classifier = MKSessionClassifier(exerciseModelSource: self, delegate: delegate)
        let sd = try! MKSensorData(types: [.Accelerometer(location: .LeftWrist)], start: 0, samplesPerSecond: 50, samples: [Float](count: 1200, repeatedValue: 0.3))
        let session = MKExerciseConnectivitySession(id: "1234", exerciseModelId: "arms", start: NSDate(), end: nil)

        classifier.exerciseConnectivitySessionDidStart(session: session)
        classifier.sensorDataConnectivityDidReceiveSensorData(accumulated: sd, new: sd, session: session)
        classifier.exerciseConnectivitySessionDidEnd(session: session.withData(sd))
        
        waitForExpectationsWithTimeout(10) { err in
            // TODO: add assertions here
        }
    }
    
}
