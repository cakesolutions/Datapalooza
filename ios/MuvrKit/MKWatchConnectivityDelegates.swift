import Foundation

///
/// Delegate that is typically used in the ``MRMetadataConnectivitySession`` to
/// report on the exercise metadata updates
///
public protocol MKMetadataConnectivityDelegate {

    ///
    /// Called when the application receives new exercise models
    ///
    /// - parameter models: the new models
    ///
    func metadataConnectivityDidReceiveExerciseModelMetadata(modelMetadata: [MKExerciseModelMetadata])
    
}
