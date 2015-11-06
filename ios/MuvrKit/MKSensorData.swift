import Foundation

public typealias MKTimestamp = Double
public typealias MKDuration = Double

///
/// Various failures that are thrown by the operations in the ``MKSensorData``
///
public enum MKSensorDataError : ErrorType {
    ///
    /// The dimensions do not match
    ///
    /// - parameter expected: the expected dimension count
    /// - parameter actual: the actual dimension count
    ///
    case MismatchedDimension(expected: Int, actual: Int)

    ///
    /// The sampling rates do not match
    ///
    /// - parameter expected: the expected sampling rate
    /// - parameter actual: the actual sampling rate
    ///
    case MismatchedSamplesPerSecond(expected: UInt, actual: UInt)
    
    ///
    /// The gap is too long to pad
    ///
    /// - parameter gap: the duration of the gap
    ///
    case TooDiscontinous(gap: MKDuration)
    
    ///
    /// The sample count does not match the expected count for the given dimensionality
    ///
    case InvalidSampleCountForDimension
    
    ///
    /// The data is empty
    ///
    case BadTypes
    
    ///
    /// the requested subset is not entirely included in this MKSensorData
    ///
    case SliceOutOfRange
}

///
/// The sensor data type
///
public enum MKSensorDataType : Equatable {
    case Accelerometer(location: Location)
    case Gyroscope(location: Location)
    case HeartRate
    
    /// The enumeration of where a sensor data is coming from
    public enum Location : Equatable {
        /// the left wrist
        case LeftWrist
        /// the right wrist
        case RightWrist
    }
    

    ///
    /// The required dimension of the data
    ///
    var dimension: Int {
        switch self {
        case .Accelerometer(_): return 3
        case .Gyroscope(_): return 3
        case .HeartRate: return 1
        }
    }
}

public func ==(lhs: MKSensorDataType, rhs: MKSensorDataType) -> Bool {
    switch (lhs, rhs) {
    case (.Accelerometer(let ll), .Accelerometer(let rl)): return ll == rl
    case (.Gyroscope(let ll), .Gyroscope(let rl)): return ll == rl
    case (.HeartRate, .HeartRate): return true
    default: return false
    }
}

public func ==(lhs: MKSensorDataType.Location, rhs: MKSensorDataType.Location) -> Bool {
    switch (lhs, rhs) {
    case (.LeftWrist, .LeftWrist): return true
    case (.RightWrist, .RightWrist): return true
    default: return false
    }
}

public struct MKSensorData {
    /// The dimension of the samples; 1 for HR and such like, 3 for acceleraton, etc.
    public let dimension: Int
    /// The actual samples
    internal var samples: [Float]

    /// The types of data contained in the column vectors (or spans of column vectors)
    public let types: [MKSensorDataType]
    /// The samples per second
    public let samplesPerSecond: UInt
    /// The start timestamp
    public let start: MKTimestamp
    
    ///
    /// Constructs a new instance of this struct, assigns the dimension and samples
    ///
    public init(types: [MKSensorDataType], start: MKTimestamp, samplesPerSecond: UInt, samples: [Float]) throws {
        if types.isEmpty { throw MKSensorDataError.BadTypes }
        self.types = types
        self.dimension = types.reduce(0) { r, e in return r + e.dimension }
        if samples.count % self.dimension != 0 { throw MKSensorDataError.InvalidSampleCountForDimension }
        
        self.samples = samples
        self.start = start
        self.samplesPerSecond = samplesPerSecond
    }
    
    ///
    /// Computes the end timestamp
    ///
    public var end: MKTimestamp {
        return start + duration
    }
    
    ///
    /// Computes the duration
    ///
    public var duration: MKDuration {
        return Double(samples.count / dimension) / Double(samplesPerSecond)
    }
    
    ///
    /// The number of complete rows
    ///
    public var rowCount: Int {
        return samples.count / dimension
    }
    
    /* TODO
    mutating func merge(that: MKSensorData) throws {
    }
    */
    
    ///
    /// returns a new MKSensorData containing only the data for the specified period
    ///
    public func slice(offset: MKTimestamp, duration: MKDuration) throws -> MKSensorData {
        if offset < start || offset + duration > end {
            throw MKSensorDataError.SliceOutOfRange
        }
        let sampleStart = dimension * Int(samplesPerSecond) * Int(offset - start)
        let sampleEnd = sampleStart + dimension * Int(samplesPerSecond) * Int(duration)
        let data = samples[sampleStart..<sampleEnd]
        return try MKSensorData(types: types, start: offset, samplesPerSecond: samplesPerSecond, samples: Array(data))
    }
    
    ///
    /// Appends ``that`` to this by filling in the gaps or resolving the overlaps if necessary
    ///
    /// - parameter that: the MKSensorData of the same dimension and sampling rate to append
    ///
    public mutating func append(that: MKSensorData) throws {
        // no need to add empty data
        if that.samples.isEmpty { return }
        if self.samplesPerSecond != that.samplesPerSecond { throw MKSensorDataError.MismatchedSamplesPerSecond(expected: self.samplesPerSecond, actual: that.samplesPerSecond) }
        if self.dimension != that.dimension { throw MKSensorDataError.MismatchedDimension(expected: self.dimension, actual: that.dimension) }
        
        if start == -1 && that.start == -1 {
            samples.appendContentsOf(that.samples)
            return
        }

        let maxGap: MKDuration = 10
        let gap = that.start - self.end
    
        if gap > maxGap { throw MKSensorDataError.TooDiscontinous(gap: gap) }
        let samplesDelta = Int(gap * Double(samplesPerSecond)) * dimension
        
        if samplesDelta < 0 && -samplesDelta < samples.count {
            // partially overlapping
            let x: Int = samples.count + samplesDelta
            samples.removeRange(x..<samples.count)
            samples.appendContentsOf(that.samples)
        } else if samplesDelta < 0 && -samplesDelta == samples.count {
            // completely overlapping
            samples = that.samples
        } else if -samplesDelta > samples.count {
            // overshooting overlap
            fatalError("Implement me")
        } else if samplesDelta == 0 {
            // no gap; simply append
            samples.appendContentsOf(that.samples)
        } else /* if samplesDelta > 0 */ {
            // gapping
            var gapSamples = [Float](count: samplesDelta, repeatedValue: 0)
            for i in 0..<dimension {
                let selfDimCount = self.samples.count / dimension
                let thatDimCount = that.samples.count / dimension
                let gapDimCount  = gapSamples.count / dimension
                let first = that.samples[thatDimCount * i]
                let last  = self.samples.isEmpty ? first : self.samples[selfDimCount * (i + 1) - 1]
                let ds = Float(first - last) / Float(gapDimCount + 1)
                for j in 0..<gapDimCount {
                    gapSamples[gapDimCount * i + j] = last + ds * Float(j + 1)
                }
            }
            
            samples.appendContentsOf(gapSamples)
            samples.appendContentsOf(that.samples)
        }
    }
 
    ///
    /// Returns samples along the given types; this is essentially a column slice
    /// of the sensor data matrix
    ///
    /// - parameter types: the types that should be returned
    ///
    func samples(along types: [MKSensorDataType], range: Range<Int>? = nil) -> (Int, [Float]) {
        
        if types == self.types {
            let elementRange = range.map { (r: Range<Int>) -> Range<Int> in
                return Range<Int>(start: r.startIndex * dimension, end: r.endIndex * dimension)
            }
            if let elementRange = elementRange {
                return (self.dimension, Array(self.samples[elementRange]))
            }
            return (self.dimension, self.samples)
        }
        
        let bitmap = self.types.reduce([]) { r, t in
            return r + [Bool](count: t.dimension, repeatedValue: types.contains(t))
        }

        let rowCount = self.samples.count / dimension
        let typesElementRange = range ?? Range<Int>(start: 0, end: rowCount)

        let includedDimensions = bitmap.filter { $0 }.count
        return (includedDimensions, typesElementRange.flatMap { row in
            return bitmap.enumerate().flatMap { (idx: Int, value: Bool) -> Float? in
                if value {
                    return self.samples[row * self.dimension + idx]
                }
                return nil
            }
        })
    }

}
