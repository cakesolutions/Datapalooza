import Foundation

extension MKSensorData : Equatable { }

public func ==(lhs: MKSensorData, rhs: MKSensorData) -> Bool {
    return lhs.types == rhs.types &&
           lhs.start == rhs.start &&
           lhs.samples == rhs.samples
}