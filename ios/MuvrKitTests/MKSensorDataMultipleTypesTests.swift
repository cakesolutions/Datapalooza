import Foundation
import XCTest
@testable import MuvrKit

class MKSensorDataMultipleTypesTests : XCTestCase {
    let threeD = try! MKSensorData(types: [.Accelerometer(location: .LeftWrist)], start: 0, samplesPerSecond: 1, samples: [-100, 0, 100])
    
    func testSamplesAsTriples() {
        let threeD = try! MKSensorData(types: [.Accelerometer(location: .LeftWrist)], start: 0, samplesPerSecond: 1, samples: [-100, 0, 100, -90, 10, 110, -110, -10, 90])
        XCTAssertEqual(threeD.samples(along: [.Accelerometer(location: .LeftWrist)]).1,
            [-100, 0,   100,
             -90,  10,  110,
             -110, -10, 90]
        )
    }
    
    /// ```
    ///   S1
    /// + S2
    /// ====
    ///   S2
    /// ```
    func testAppendCompletelyOverlapping() {
        var d = threeD
        try! d.append(threeD)
        XCTAssertEqual(d.end, 1)
        XCTAssertEqual(d.samples(along: [.Accelerometer(location: .LeftWrist)]).1, [-100, 0, 100])
    }
    
    /// ```
    ///   S1
    /// +   S2
    /// ======
    ///   S1S2
    /// ```
    func testAppendImmediatelyFollowing() {
        var d = threeD
        try! d.append(MKSensorData(types: [.Accelerometer(location: .LeftWrist)], start: 1, samplesPerSecond: 1, samples: [-50, 50, 150]))
        try! d.append(MKSensorData(types: [.Accelerometer(location: .LeftWrist)], start: 2, samplesPerSecond: 1, samples: [0, 100, 200]))
        XCTAssertEqual(d.end, 3)

        XCTAssertEqual(d.samples(along: [.Accelerometer(location: .LeftWrist)]).1,
            [-100, 0,   100,
             -50,  50,  150,
             0,    100, 200]
        )
    }
    
    /// ```
    ///  S1
    /// +  .g.S2
    /// +       ·g·S3
    /// =============
    ///  S1...S2···S3
    /// ```
    func testAppendAllowableGap() {
        var d = threeD
        try! d.append(MKSensorData(types: [.Accelerometer(location: .LeftWrist)], start: 2, samplesPerSecond: 1, samples: [100, 100, 200]))
        XCTAssertEqual(d.end, 3)
        XCTAssertEqual(d.samples(along: [.Accelerometer(location: .LeftWrist)]).1,
            [-100, 0,   100,
                0, 50,  150,
              100, 100, 200]
        )
    }
    
    func testAppendAllowableGapMulti() {
        var d =  try! MKSensorData(types: [.Accelerometer(location: .LeftWrist), .Gyroscope(location: .LeftWrist), .HeartRate], start: 0, samplesPerSecond: 1, samples: [1, 2, 3, 10, 20, 30, 40])
        try! d.append(MKSensorData(types: [.Accelerometer(location: .LeftWrist), .Gyroscope(location: .LeftWrist), .HeartRate], start: 2, samplesPerSecond: 1, samples: [3, 4, 7, 30, 40, 70, 80]))
        XCTAssertEqual(d.end, 3)

        XCTAssertEqual(d.samples(along: [.Accelerometer(location: .LeftWrist)]).1,
            [1, 2, 3,
             2, 3, 5,
             3, 4, 7]
        )

        XCTAssertEqual(d.samples(along: [.Gyroscope(location: .LeftWrist)]).1,
            [10, 20, 30,
             20, 30, 50,
             30, 40, 70]
        )

        XCTAssertEqual(d.samples(along: [.HeartRate]).1,
            [40,
             60,
             80]
        )
    }
    
    ///
    /// Appending sensor data with too big gap (> 10 seconds) is not allowed
    ///
    func testAppendTooBigGap() {
        var d = threeD
        do {
            try d.append(MKSensorData(types: [.Accelerometer(location: .LeftWrist)], start: 12, samplesPerSecond: 1, samples: [200, 200, 200]))
            XCTFail("Gap too big got in")
        } catch MKSensorDataError.TooDiscontinous(11) {
            
        } catch {
            XCTFail("Bad exception")
        }
    }
    
}