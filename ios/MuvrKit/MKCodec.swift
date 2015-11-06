import Foundation

enum MKCodecError : ErrorType {
    case NotEnoughInput
    case BadHeader
    
    case CompressionFailed
    case DecompressionFailed
}
