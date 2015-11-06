import Foundation
import XCTest
@testable import MuvrKit

class MKSensorDataThreedDPerformanceTests : XCTestCase {
    let threeD = try! MKSensorData(types: [.Accelerometer(location: .LeftWrist)], start: 0, samplesPerSecond: 1, samples: [-100, 0, 100])

    func testAppendPerformance() {
        var d = try! MKSensorData(types: [.Accelerometer(location: .LeftWrist)], start: 0, samplesPerSecond: 1, samples: [1, 1, 1])
        let fiftySamples = [Float](count: 50 * 3, repeatedValue: 100)
        
        self.measureBlock {
            for _ in 0...100_000 {
                try! d.append(try! MKSensorData(types: [.Accelerometer(location: .LeftWrist)], start: d.end + 1, samplesPerSecond: 1, samples: fiftySamples))
            }
        }
    }

    
}
