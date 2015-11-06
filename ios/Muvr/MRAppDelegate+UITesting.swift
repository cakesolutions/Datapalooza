import UIKit
import MuvrKit

#if !RELEASE

//
// *** DO NOT RUN UI TESTS ON A DEVICE THAT CONTAINS DATA YOU WANT TO KEEP ***
//
// This code completely removes all saved in the app; the next time you start it, it will be empty.
//
// *** DO NOT RUN UI TESTS ON A DEVICE THAT CONTAINS DATA YOU WANT TO KEEP ***
//
extension MRAppDelegate  {
    
    ///
    /// Comments
    ///
    private func exerciseIds() -> [String] {
        return ["arms/biceps-curl", "arms/triceps-extension", "shoulders/lateral-raise"]
    }
    
    private func generateSessionData(date date: NSDate) {
        
        func generateClassifiedExercise(date date: NSDate, session: MRManagedExerciseSession, index: Int) {
            let exercise = MRManagedClassifiedExercise.insertNewObject(inManagedObjectContext: managedObjectContext)
            exercise.confidence = 1
            exercise.exerciseId = exerciseIds()[index % 3]
            exercise.exerciseSession = session
            exercise.duration = 12
            exercise.intensity = 1
            exercise.repetitions = 10
            exercise.weight = 10
            exercise.start = date.addSeconds(index * 60)
        }
        
        func generateLabelledExercise(date date: NSDate, session: MRManagedExerciseSession, index: Int) {
            let exercise = MRManagedLabelledExercise.insertNewObject(into: session, inManagedObjectContext: managedObjectContext)
            exercise.start = date.addSeconds(index * 60)
            exercise.end = date.addSeconds(index * 60 + 30)
            exercise.exerciseId = exerciseIds()[index % 3]
            exercise.exerciseSession = session
            exercise.intensity = 1
            exercise.weight = 2
            exercise.repetitions = 15
        }
        

        let session = MRManagedExerciseSession.insertNewObject(inManagedObjectContext: managedObjectContext)
        session.id = NSUUID().UUIDString
        session.exerciseModelId = "arms"
        session.start = date
        
        (0..<10).forEach { i in generateClassifiedExercise(date: date, session: session, index: i) }
        (0..<2).forEach { i in generateLabelledExercise(date: date, session: session, index: i) }
    }
    
    private func getSessionDates() -> [NSDate] {
        let today = NSDate()
        let earlierToday = today.addHours(-2)
        var dates = [today, earlierToday]
        (1..<10).forEach { i in
            dates.appendContentsOf([today.addDays(-i), earlierToday.addDays(-i)])
        }
        return dates
    }
    
    private func generateData() {
        getSessionDates().forEach(generateSessionData)
        saveContext()
    }

    func application(application: UIApplication, willFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        if Process.arguments.contains("--reset-container") {
            NSLog("Reset container.")
            if let docs = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true).first {
                let fileManager = NSFileManager.defaultManager()
                try! fileManager.contentsOfDirectoryAtPath(docs).forEach { file in
                    do {
                        try fileManager.removeItemAtPath("\(docs)/\(file)")
                    } catch {
                        // do nothing
                    }
                }
            }

            if Process.arguments.contains("--default-data") {
                generateData()
            }
        }
        
        return true
    }
    
}
#endif
