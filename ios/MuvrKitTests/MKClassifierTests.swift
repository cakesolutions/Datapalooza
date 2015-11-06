import Foundation
import XCTest
@testable import MuvrKit

class MKClassifierTests : XCTestCase {
    lazy var classifier: MKClassifier = {
        let modelPath = NSBundle(forClass: MKClassifierTests.self).pathForResource("model-3", ofType: "raw")!
        let weights = MKExerciseModel.loadWeightsFromFile(modelPath)
        
        let model = MKExerciseModel(layerConfig: [1200, 250, 100, 3], weights: weights,
            sensorDataTypes: [.Accelerometer(location: .LeftWrist)],
            exerciseIds: ["1", "2", "3"],
            minimumDuration: 0)
        return try! MKClassifier(model: model)
    }()
    
    /// 
    /// Tests that the classification rejects insufficient data
    ///
    func testClassifyNoSensorDataType() {
        do {
            try classifier.classify(block: MKSensorData(types: [.HeartRate], start: 0, samplesPerSecond: 1, samples: []), maxResults: 100)
            XCTFail("No exception")
        } catch MKClassifierError.NoSensorDataType(_) {
        } catch {
            XCTFail("Bad exception")
        }
    }
    
    ///
    /// Tests that the classification rejects insufficient data
    ///
    func testClassifyNotEnoughData() {
        do {
            try classifier.classify(block: MKSensorData(types: [.Accelerometer(location: .LeftWrist)], start: 0, samplesPerSecond: 1, samples: [1,2,3]), maxResults: 100)
            XCTFail("No exception")
        } catch MKClassifierError.NotEnoughRows(_) {
        } catch {
            XCTFail("Bad exception")
        }
    }
    
    ///
    /// Tests that class 1 is correctly identified
    ///
    func testClassA() {
        let fileName = NSBundle(forClass: MuvrKitTests.self).pathForResource("class-1", ofType: "csv")!
        let block = try! MKSensorData.sensorData(types: [MKSensorDataType.Accelerometer(location: .LeftWrist)], samplesPerSecond: 100, loading: fileName)
        let cls = try! classifier.classify(block: block, maxResults: 100).first!
        XCTAssertEqual(cls.exerciseId, "1")
        XCTAssertGreaterThan(cls.confidence, 0.99)
        
        let bc = try! classifier.classify(block: block, maxResults: 100)
        print(bc)
    }

    ///
    /// Tests that all zeros does not classify the right value
    ///
    func testLargeZeros() {
        let block = MKSensorData.sensorData(types: [MKSensorDataType.Accelerometer(location: .LeftWrist)], samplesPerSecond: 100, generating: 50000, withValue: .Constant(value: 0))
        let cls = try! classifier.classify(block: block, maxResults: 100).first
        XCTAssertTrue(cls == nil)
    }
    
    ///
    /// Tests that computed offset are correct
    ///
    func testExerciseOffsets() {
        var block = MKSensorData.sensorData(types: [MKSensorDataType.Accelerometer(location: .LeftWrist)], samplesPerSecond: 5, generating: 500, withValue: .Sin1(period: 2*5))
        let block2 = MKSensorData.sensorData(types: [MKSensorDataType.Accelerometer(location: .LeftWrist)], samplesPerSecond: 5, generating: 500, withValue: .Constant(value: 0))
        let block3 = MKSensorData.sensorData(types: [MKSensorDataType.Accelerometer(location: .LeftWrist)], samplesPerSecond: 5, generating: 500, withValue: .Sin1(period: 5*5))
        try! block.append(block2)
        try! block.append(block3)
        let cls = try! classifier.classify(block: block, maxResults: 10)
        XCTAssertEqual(cls.first!.offset, 0.0)
        var end = 0.0
        cls.forEach { x in
            XCTAssertGreaterThanOrEqual(x.offset, end)
            NSLog("Exercise \(x.exerciseId) starts on or after \(end)s: \(x.offset)s")
            end = end + x.duration
        }
    }
    
    
}