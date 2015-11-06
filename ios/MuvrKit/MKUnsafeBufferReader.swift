import Foundation

class MKUnsafeBufferReader {
    private let totalLength: Int
    private var offset: Int
    private let bytes: UnsafePointer<UInt8>
    
    /*
    init(bytes: UnsafePointer<UInt8>, totalLength: Int) {
        self.bytes = bytes
        self.totalLength = totalLength
        self.offset = 0
    }
    */
    
    init(data: NSData) {
        self.bytes = UnsafePointer<UInt8>(data.bytes)
        self.totalLength = data.length
        self.offset = 0
    }
    
    func expect(value: UInt8, throwing e: ErrorType) throws {
        if try next() != value {
            throw e
        }
    }
    
    func next<A>() throws -> A {
        return try nexts(1).memory
    }
    
    func nexts<A>(count: Int) throws -> UnsafePointer<A> {
        // 32 bit architecture check: Int overflows for suitably big ``count`` and ``sizeof(A)``        
        #if !(arch(x86_64) || arch(arm64))
        
        let countBytes64: Int64 = Int64(sizeof(A)) * Int64(count)
        if countBytes64 > Int64(INT32_MAX) {
            throw MKCodecError.NotEnoughInput
        }
        
        #endif
        
        let countBytes: Int = sizeof(A) * count
        if offset + countBytes - 1 < totalLength {
            let ptr = UnsafePointer<A>(bytes.advancedBy(offset))
            offset += countBytes
            return ptr
        }
        throw MKCodecError.NotEnoughInput
    }
        
    /// The readable length
    var length: Int {
        return totalLength - offset
    }
}
