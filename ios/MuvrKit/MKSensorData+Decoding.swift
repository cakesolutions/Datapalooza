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
///    uint8_t samplesPerSecod;
///    uint32  samplesCount;         
///
///    uint8_t types[typesCount];    
///    uint8_t samples[samplesCount];
/// }
/// ```
///
public extension MKSensorData {
    
    ///
    /// Initializes this instance by decoding the given ``data``. This is the inverse function
    /// of ``MKSensorData.encode()``: given enough memory, this always holds.
    ///
    /// ```
    /// let a = MKSensorData(...)
    /// let b = MKSensorData(decoding: a.encode())
    /// assert(a == b)
    /// ```
    ///
    /// - parameter data: the data to be decoded
    ///
    public init(decoding data: NSData) throws {
        /*
        let destinationBufferSize: Int = Int(UnsafePointer<UInt32>(data.bytes).memory)
        let sourceBuffer: UnsafePointer<UInt8> = UnsafePointer<UInt8>(data.bytes.advancedBy(sizeof(UInt32)))
        let sourceBufferSize: Int = data.length
        
        let destinationBuffer: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.alloc(destinationBufferSize)
        let status = compression_decode_buffer(destinationBuffer, destinationBufferSize, sourceBuffer, sourceBufferSize, nil, COMPRESSION_LZFSE)
        if status == 0 {
            throw MKCodecError.DecompressionFailed
        }
        
        let bytes = MKUnsafeBufferReader(bytes: destinationBuffer, totalLength: status)
        */
        
        let bytes = MKUnsafeBufferReader(data: data)

        if bytes.length < 18 { throw MKCodecError.NotEnoughInput }
        
        try bytes.expect(UInt8(0x61), throwing: MKCodecError.BadHeader) // 1
        try bytes.expect(UInt8(0x64), throwing: MKCodecError.BadHeader) // 2
        let typesCount: UInt8       = try bytes.next()                  // 3
        let samplesPerSecond: UInt8 = try bytes.next()                  // 4
        let start: Double           = try bytes.next()                  // 12
        let samplesCount: UInt32    = try bytes.next()                  // 13
        let types = try (0..<typesCount).map { _ in                     // 18
            return try MKSensorDataType.decode(bytes)
        }
        let samplesData: UnsafePointer<Float> = try bytes.nexts(Int(samplesCount))
        var samples: [Float] = [Float](count: Int(samplesCount), repeatedValue: 0)
        for i in 0..<Int(samplesCount) {
            samples[i] = samplesData.advancedBy(i).memory
        }
        
        try self.init(types: types, start: start, samplesPerSecond: UInt(samplesPerSecond), samples: samples)
    }
}
