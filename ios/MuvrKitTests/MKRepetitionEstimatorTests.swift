import Foundation
import XCTest
@testable import MuvrKit

class MKRepetitionEstimatorTests : XCTestCase {

    func testSimpleSynthetic() {
        let block = MKSensorData.sensorData(types: [.Accelerometer(location: .LeftWrist)], samplesPerSecond: 100, generating: 400, withValue: .Sin1(period: 10))
        let (count, _) = try! MKRepetitionEstimator().estimate(data: block)
        XCTAssertEqual(count, 6)
    }
    
    func testSimpleTooFast() {
        let block = MKSensorData.sensorData(types: [.Accelerometer(location: .LeftWrist)], samplesPerSecond: 100, generating: 400, withValue: .Sin1(period: 1))
        let (count, _) = try! MKRepetitionEstimator().estimate(data: block)
        XCTAssertEqual(count, 0)
    }
    
    func testZero() {
        let block = MKSensorData.sensorData(types: [.Accelerometer(location: .LeftWrist)], samplesPerSecond: 100, generating: 400, withValue: .Constant(value: 0))
        let (count, _) = try! MKRepetitionEstimator().estimate(data: block)
        XCTAssertEqual(count, 0)
    }
    
    func testMissingAccelerometer() {
        let block = MKSensorData.sensorData(types: [.HeartRate], samplesPerSecond: 100, generating: 400, withValue: .Constant(value: 0))
        do {
            try MKRepetitionEstimator().estimate(data: block)
            XCTFail("No exception")
        } catch MKRepetitionEstimatorError.MissingAccelerometerType {
            // OK
        } catch {
            XCTFail("Bad exception")
        }
    }
    
}
