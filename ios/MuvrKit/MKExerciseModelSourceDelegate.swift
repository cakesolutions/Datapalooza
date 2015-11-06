import Foundation

///
/// Exercise model source errors
///
public enum MKExerciseModelSourceDelegateError {
    ///
    /// The exercise model could not be found
    ///
    case NoSuitableModel
}

///
/// Provides a way to lookup ``MKExerciseModel`` given the list of available sensor types.
///
/// The implementation should attempt to find the best-matching model; that is,
/// a model that is trained to work with all available ``types``.
///
protocol MKExerciseModelSourceDelegate {

    ///
    /// Lookup the ``MKExerciseModel`` for the given the model identity and the
    /// available ``types``.
    ///
    /// - parameter types: the available sensor types
    /// - returns: the most appropriate model
    /// - throws: one of ``MKExerciseModelSourceDelegateError``s
    ///
    func exerciseModelLookup(forSensorTypes types: [MKSensorDataType]) throws -> MKExerciseModel
    
}
