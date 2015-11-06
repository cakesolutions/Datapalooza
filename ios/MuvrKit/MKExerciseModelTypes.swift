import Foundation

///
/// The exercise model identty
///
public typealias MKExerciseModelId = String

///
/// The exercise model metadata that binds the exercise model identity and its title
///
public typealias MKExerciseModelMetadata = (MKExerciseModelId, String)

///
/// The exercise identity
///
public typealias MKExerciseId = String

///
/// The intensity
///
public typealias MKExerciseIntensity = Double

///
/// The exercise intensity metadata that binds the intensity value and its title
///
public typealias MKExerciseIntensityMetadata = (MKExerciseIntensity, String)