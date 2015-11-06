import Foundation
import Accelerate

public enum MKRepetitionEstimatorError : ErrorType {
    
    case MissingAccelerometerType
    
}

public struct MKRepetitionEstimator {
    public typealias Estimate = (UInt8, Double)
    
    ///
    /// Holds information about a periodic profile
    ///
    private struct PeriodicProfile {
        // Abosolute amount the signal changed in the period
        var totalSteps: Float {
            return upwardSteps + downwardSteps
        }
        // Upwards steps of the signal
        var upwardSteps: Float = 0
        // Downwards steps of the signal
        var downwardSteps: Float = 0

        ///
        /// Determines whether ``self`` is roughly equal to ``that``, given ``margin``
        ///
        /// - parameter that: the other PP to compare
        /// - parameter margin: the margin
        /// - returns: ``true`` if ``self`` ~= ``that`` given ``margin``
        ///
        func roughlyEquals(that: PeriodicProfile, margin: Float) -> Bool {
            func ire(a a: Float, b: Float, margin: Float) -> Bool {
                return (1 + margin) * a > b && b > (1 - margin) * a
            }
            
            return ire(a: self.totalSteps, b: that.totalSteps, margin: margin)
        }
    }
    
    public func estimate(data data: MKSensorData) throws -> Estimate {
        var (sampleDimension, sampleData) = data.samples(along: [.Accelerometer(location: .LeftWrist), .Accelerometer(location: .RightWrist)])
        if sampleDimension == 0 { throw MKRepetitionEstimatorError.MissingAccelerometerType }

        // MARK: Setup basic variables
        let sampleDataLength = sampleData.count / sampleDimension
        
        var correlation = [Float](count: sampleData.count, repeatedValue: 0)
        var signal = sampleData + [Float](count: sampleData.count - 1, repeatedValue: 0)
        
        // MARK: First, compute autocorrelation across all dimensions of our data, summing & finding peaks along the way

        //
        // The ``sampleData`` is a continuous array of ``Float``s, containing ``sampleDimension`` dimensions. For example, for
        // a single accelerometer data, we have ``sampleDimension == 3``, and the values in the ``sampleData`` are 
        // ``[x0, y0, z0; x1, y1, z1; ... xn, yn, zn]``. 
        //
        // In order to use to vDSP functions, we specify the stride to be equal to the ``sampleDimension``, but we must be 
        // careful to specify the first element properly. To do so, we loop over ``0..<sampleDimension``, offsetting the start
        // of the ``sampleData`` by each dimension.
        //
        let peaks = (0..<sampleDimension).map { (d: Int) -> [Int] in
            var peaks: [Int] = []
            let nDowns = 1
            let nUps = 1
            
            vDSP_conv(&signal + d,      vDSP_Stride(sampleDimension),
                      &sampleData + d,  vDSP_Stride(sampleDimension),
                      &correlation + d, vDSP_Stride(sampleDimension),
                      vDSP_Length(sampleDataLength),
                      vDSP_Length(sampleDataLength))

            var max: Float = 2.0 / correlation[d]
            var shift: Float = -1
            vDSP_vsmsa(&correlation + d, vDSP_Stride(sampleDimension),
                       &max, &shift,
                       &correlation + d, vDSP_Stride(sampleDimension),
                       vDSP_Length(sampleDataLength))

            for var i = nDowns; i < sampleDataLength - nUps; ++i {
                var isPeak = true
                for var j = -nDowns; j < nUps && isPeak; ++j {
                    let idx  = (i + j) * sampleDimension + d
                    let idx1 = (i + j + 1) * sampleDimension + d
                    if j < 0 { isPeak = isPeak && correlation[idx] <  correlation[idx1] }
                    else     { isPeak = isPeak && correlation[idx] >= correlation[idx1] }
                }
                if isPeak { peaks.append(i * sampleDimension + d) }
            }

            return peaks
        }
        
        // MARK: Find the most significant dimension in the peaks
        // TODO: Improve me
        let mostSignificantDimension = 0
        let mostSignificantPeaks = peaks[mostSignificantDimension]
        
        // MARK: Compute period profiles in the most significant dimension
        var previousPeakLocation = 0
        var previousHeight: Float = 0
        var currentHeight: Float = 0
        var profiles = (0..<mostSignificantPeaks.count).map { (i: Int) -> PeriodicProfile in
            var profile = PeriodicProfile()
            for var j = previousPeakLocation; j < mostSignificantPeaks[i] - 1; ++j {
                previousHeight = sampleData[j]
                currentHeight = sampleData[j + sampleDimension]
                let steps = previousHeight - currentHeight
                if steps > 0 {
                    profile.upwardSteps += steps
                } else {
                    profile.downwardSteps += steps
                }
            }
            previousPeakLocation = mostSignificantPeaks[i]
            
            return profile
        }
        
        if profiles.count > 0 {
            // MARK: Compute the mean profile from the list of profiles
            profiles.sortInPlace { $0.totalSteps < $1.totalSteps }
            let meanProfile = profiles[profiles.count / 2]

            // MARK: Count the repetitions
            let minimumPeakDistance = 50
            let (count, _) = (0..<mostSignificantPeaks.count).reduce((0, 0)) { x, i in
                let (count, previousPeakLocation) = x
                let msp = mostSignificantPeaks[i]
                if msp - previousPeakLocation >= minimumPeakDistance && profiles[i].roughlyEquals(meanProfile, margin: 50) {
                    return (count + 1, msp)
                } else {
                    return (count, msp)
                }
            }
            
            return (UInt8(count), 1)
        } else {
            return (0, 1)
        }
    }
    
}
