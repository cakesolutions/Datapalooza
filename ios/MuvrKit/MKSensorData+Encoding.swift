import Foundation

///
/// We have the
///
/// ```
/// uint32_t decompressedSize;
/// compressed struct MK_SENSOR_DATA_HEADER {
///    uint8_t header = 0xd0;         
///    uint8_t version = 1;           
///    uint8_t typesCount;            
///    double  start;                 
///    uint8   samplesPerSecod;       
///    uint32  samplesCount;          
///
///    uint8_t types[typesCount];     
///    uint8_t samples[samplesCount];
/// }
/// ```
///
public extension MKSensorData {
    
    ///
    /// Encode the MKSensorData instance so that it can be transmitted to over a very low-bandwidth network.
    /// It can throw ``MRCodecError.CompressionFailed`` if for some strange reason the data cannot be compressed.
    ///
    /// - returns: the compressed data that can be passed to ``MKSensorData.decode`` to get the same instance
    ///
    public func encode() -> NSData {
        let d = NSMutableData()
        var header: UInt8  = 0x61
        var version: UInt8 = 0x64
        var typesCount: UInt8 = UInt8(self.types.count)
        var samplesPerSecond: UInt8 = UInt8(self.samplesPerSecond)
        var samplesCount: UInt32 = UInt32(self.samples.count)
        var start: Double = self.start
        var samples: [Float] = self.samples
        var types = self.types.flatMap { (type: MKSensorDataType) -> [UInt8] in
            switch type {
            case .Accelerometer(location: MKSensorDataType.Location.LeftWrist):  return [UInt8(0x74), UInt8(0x61), UInt8(0x6c), UInt8(0x0)]
            case .Accelerometer(location: MKSensorDataType.Location.RightWrist): return [UInt8(0x74), UInt8(0x61), UInt8(0x72), UInt8(0x0)]
            case .Gyroscope(location: MKSensorDataType.Location.LeftWrist):      return [UInt8(0x74), UInt8(0x67), UInt8(0x6c), UInt8(0x0)]
            case .Gyroscope(location: MKSensorDataType.Location.RightWrist):     return [UInt8(0x74), UInt8(0x67), UInt8(0x72), UInt8(0x0)]
            case .HeartRate:                                                     return [UInt8(0x74), UInt8(0x68), UInt8(0x2d), UInt8(0x0)]
            }
        }
                
        d.appendBytes(&header,  length: sizeof(UInt8))
        d.appendBytes(&version, length: sizeof(UInt8))
        d.appendBytes(&typesCount, length: sizeof(UInt8))
        d.appendBytes(&samplesPerSecond, length: sizeof(UInt8))
        d.appendBytes(&start, length: sizeof(Double))
        d.appendBytes(&samplesCount, length: sizeof(UInt32))
        
        d.appendBytes(&types, length: types.count)
        d.appendBytes(&samples, length: sizeof(Float) * Int(samplesCount))

        /*
        let destinationBufferSize = d.length
        let destinationBuffer: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.alloc(d.length + sizeof(UInt32))
        let status = compression_encode_buffer(destinationBuffer.advancedBy(sizeof(UInt32)), destinationBufferSize, UnsafePointer<UInt8>(d.bytes), d.length, nil, COMPRESSION_LZFSE)
        if status == 0 {
            throw MKCodecError.CompressionFailed
        }
        UnsafeMutablePointer<UInt32>(destinationBuffer)[0] = UInt32(destinationBufferSize)
        return NSData(bytesNoCopy: destinationBuffer, length: status + sizeof(UInt32))
        */
        
        return d
    }
    
}
