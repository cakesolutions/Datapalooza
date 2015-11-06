import UIKit
import HealthKit
import MuvrKit
import CoreData

enum MRNotifications : String {
    case CurrentSessionDidEnd = "MRNotificationsCurrentSessionDidEnd"
    case CurrentSessionDidStart = "MRNotificationsCurrentSessionDidStart"
}

@UIApplicationMain
class MRAppDelegate: UIResponder, UIApplicationDelegate, MKExerciseModelSource, MKSessionClassifierDelegate {
    
    var window: UIWindow?
    
    private var connectivity: MKConnectivity!
    private var classifier: MKSessionClassifier!
    private(set) internal var currentSession: MRManagedExerciseSession?
    
    ///
    /// Returns this shared delegate
    ///
    static func sharedDelegate() -> MRAppDelegate {
        return UIApplication.sharedApplication().delegate as! MRAppDelegate
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // set up the classification and connectivity
        classifier = MKSessionClassifier(exerciseModelSource: self, delegate: self)
        connectivity = MKConnectivity(sensorDataConnectivityDelegate: classifier, exerciseConnectivitySessionDelegate: classifier)
        
        let typesToShare: Set<HKSampleType> = [HKSampleType.workoutType()]
        let typesToRead: Set<HKSampleType> = [HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!]

        HKHealthStore().requestAuthorizationToShareTypes(typesToShare, readTypes: typesToRead) { (x, y) -> Void in
            print(x)
            print(y)
        }
        
        // main initialization
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window!.makeKeyAndVisible()
        window!.rootViewController = storyboard.instantiateInitialViewController()
        
        let pageControlAppearance = UIPageControl.appearance()
        pageControlAppearance.pageIndicatorTintColor = UIColor.lightGrayColor()
        pageControlAppearance.currentPageIndicatorTintColor = UIColor.blackColor()
        pageControlAppearance.backgroundColor = UIColor.whiteColor()
    
        return true
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        application.idleTimerDisabled = true
    }
    
    func applicationWillResignActive(application: UIApplication) {
        application.idleTimerDisabled = false
    }

    func getExerciseModel(id id: MKExerciseModelId) -> MKExerciseModel {
        func loadTextFiles(path bundlePath: String, filename: String, ext: String, separator: NSCharacterSet) -> [String] {
            let fullPath = NSBundle(path: bundlePath)!.pathForResource(filename, ofType: ext)!
            func removeEmptyStr(arrStr: [String]) -> [String] {
                return arrStr
                    .filter {$0 != ""}
                    .map {$0.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())}
            }
            do {
                let content = try String(contentsOfFile: fullPath, encoding: NSUTF8StringEncoding)
                return removeEmptyStr(content.componentsSeparatedByCharactersInSet(separator))
            } catch {
                return []
            }
        }

        // setup the classifier
        let bundlePath = NSBundle.mainBundle().pathForResource("Models", ofType: "bundle")!

        // loading layer/label
        let layerStr = loadTextFiles(path: bundlePath, filename: "\(id)_model.layers", ext: "txt", separator: NSCharacterSet.whitespaceCharacterSet())
        let layer = layerStr.map {Int($0)!}
        let label = loadTextFiles(path: bundlePath, filename: "\(id)_model.labels", ext: "txt", separator: NSCharacterSet.newlineCharacterSet())

        let modelPath = NSBundle(path: bundlePath)!.pathForResource("\(id)_model.weights", ofType: "raw")!
        let weights = MKExerciseModel.loadWeightsFromFile(modelPath)
        let model = MKExerciseModel(layerConfig: layer, weights: weights,
            sensorDataTypes: [.Accelerometer(location: .LeftWrist)],
            exerciseIds: label,
            minimumDuration: 8)
        return model
    }
    
    func sessionClassifierDidEnd(session: MKExerciseSession, sensorData: MKSensorData?) {
        let objectId = currentSession!.objectID
        currentSession = nil
        NSNotificationCenter.defaultCenter().postNotificationName(MRNotifications.CurrentSessionDidEnd.rawValue, object: objectId)
    }
    
    func sessionClassifierDidClassify(session: MKExerciseSession, classified: [MKClassifiedExercise], sensorData: MKSensorData) {
        if let currentSession = currentSession {
            currentSession.sensorData = sensorData.encode()
            classified.forEach { MRManagedClassifiedExercise.insertNewObject(from: $0, into: currentSession, inManagedObjectContext: managedObjectContext) }
        }
        saveContext()
    }
    
    func sessionClassifierDidStart(session: MKExerciseSession) {
        currentSession = MRManagedExerciseSession.insertNewObject(from: session, inManagedObjectContext: managedObjectContext)
        NSNotificationCenter.defaultCenter().postNotificationName(MRNotifications.CurrentSessionDidStart.rawValue, object: currentSession!.objectID)
        saveContext()
    }
    
    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "io.muvr.CDemo" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls.first!
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("Muvr", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("MuvrCoreData.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "io.muvr", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }

}
