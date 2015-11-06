import Foundation

///
/// Extension containing defaul values
///
extension MKConnectivity {
    
    ///
    /// Default exercise models that will be reported in case no models are found from the app
    ///
    internal var defaultExerciseModelMetadata: [MKExerciseModelMetadata] {
        return [
            ("arms",      "Arms"),
            ("shoulders", "Shoulders"),
            ("chest",     "Chest")
        ]
    }

}
