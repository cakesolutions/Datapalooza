import Foundation

///
/// Represents a "range" in the matching ``MKSensorData`` that explicitly labels
/// it with the given exercise.
///
/// This is useful for training and training stages.
///
@objc public protocol MKLabelledExercise {
    /// The exercise id—a classifier label, not localised
    var exerciseId: MKExerciseId { get }
    /// The start date
    var start: NSDate { get }
    /// The end date
    var end: NSDate { get }
    /// # repetitions; > 0
    var repetitions: UInt32 { get }
    /// The intensity; (0..1.0)
    var intensity: MKExerciseIntensity { get }
    /// The weight in kg; > 0
    var weight: Double { get }
}
