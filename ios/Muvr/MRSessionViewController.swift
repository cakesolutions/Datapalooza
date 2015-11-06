import UIKit
import CoreData
import MuvrKit

///
/// This class shows the exercises of the displayed session.
/// To display a session, you must call the ``setSession(session:)`` method and provide a valid ``MRManagedExerciseSesssion``.
///
class MRSessionViewController : UIViewController, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addLabelBtn: UIBarButtonItem!
    @IBOutlet weak var navbar: UINavigationBar!
    
    // the displayed session
    private var session: MRManagedExerciseSession?
    // indicates if the displayed session is active (i.e. not finished)
    private var runningSession: Bool = false
    
    ///
    /// Provides the session to display
    ///
    func setSession(session: MRManagedExerciseSession) {
        self.session = session
        runningSession = MRAppDelegate.sharedDelegate().currentSession.map { $0 == session } ?? false
    }
    
    ///
    /// Find an activity to share the give file
    ///
    func share(data: NSData, fileName: String) {
        let documentsUrl = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true).first!
        let fileUrl = NSURL(fileURLWithPath: documentsUrl).URLByAppendingPathComponent(fileName)
        if data.writeToURL(fileUrl, atomically: true) {
            let controller = UIActivityViewController(activityItems: [fileUrl], applicationActivities: nil)
            let excludedActivities = [UIActivityTypePostToTwitter, UIActivityTypePostToFacebook,
                UIActivityTypePostToWeibo, UIActivityTypeMessage, UIActivityTypeMail,
                UIActivityTypePrint, UIActivityTypeCopyToPasteboard,
                UIActivityTypeAddToReadingList, UIActivityTypePostToFlickr,
                UIActivityTypePostToVimeo, UIActivityTypePostToTencentWeibo]
            controller.excludedActivityTypes = excludedActivities
            
            presentViewController(controller, animated: true, completion: nil)
        }
    }
    
    // MARK: UIViewController

    override func viewDidDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidAppear(animated: Bool) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "update", name: NSManagedObjectContextDidSaveNotification, object: MRAppDelegate.sharedDelegate().managedObjectContext)
        if let objectId = session?.objectID {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "sessionDidEnd", name: MRNotifications.CurrentSessionDidEnd.rawValue, object: objectId)
        }
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        addLabelBtn.enabled = runningSession
        if let s = session {
            navbar.topItem!.title = "\(s.start.formatTime()) - \(s.exerciseModelId)"
        } else {
            navbar.topItem!.title = nil
        }
    }
    
    // MARK: notification callbacks
    
    func update() {
        tableView.reloadData()
    }
    
    func sessionDidEnd() {
        addLabelBtn.enabled = false
    }
    
    // MARK: Share & label
    
    /// share the raw session data
    @IBAction func shareRaw() {
        if let data = session?.sensorData,
            let sessionId = session?.id,
            let exerciseModel = session?.exerciseModelId {
            share(data, fileName: "\(exerciseModel)_\(sessionId).raw")
        }
    }
    
    /// share the CSV session data
    @IBAction func shareCSV() {
        if let data = session?.sensorData,
            let sessionId = session?.id,
            let sessionStart = session?.start.timeIntervalSince1970,
            let labelledExercises = session?.labelledExercises.allObjects as? [MRManagedLabelledExercise],
            let exerciseModel = session?.exerciseModelId,
            let sensorData = try? MKSensorData(decoding: data) {
                let csvData = sensorData.encodeAsCsv(sessionStart: sessionStart, labelledExercises: labelledExercises)
                share(csvData, fileName: "\(exerciseModel)_\(sessionId).csv")
        }
    }
    
    /// display the ``Add label`` screen
    @IBAction func label(sender: UIBarButtonItem) {
        performSegueWithIdentifier("label", sender: session)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let lc = segue.destinationViewController as? MRLabelViewController, let session = sender as? MRManagedExerciseSession {
            lc.session = session
        }
    }
    
    // MARK: UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Classified Exercises"
        case 1: return "Labels"
        default: return nil
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return session?.classifiedExercises.count ?? 0
        case 1: return session?.labelledExercises.count ?? 0
        default: return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCellWithIdentifier("classifiedExercise", forIndexPath: indexPath)
            let ce = session!.classifiedExercises.reverse()[indexPath.row] as! MRManagedClassifiedExercise
            cell.textLabel!.text = ce.exerciseId
            let weight = ce.weight.map { w in "\(NSString(format: "%.2f", w)) kg" } ?? ""
            let intensity = ce.intensity.map { i in "Intensity: \(NSString(format: "%.2f", i))" } ?? ""
            let duration = "\(NSString(format: "%.0f", ce.duration))s"
            cell.detailTextLabel!.text = "\(ce.start.formatTime()) - \(duration) - \(weight) - \(intensity)"
            return cell
        case 1:
            let cell = tableView.dequeueReusableCellWithIdentifier("labelledExercise", forIndexPath: indexPath)
            let le = session!.labelledExercises.reverse()[indexPath.row] as! MRManagedLabelledExercise
            cell.textLabel!.text = le.exerciseId
            let weight = "\(NSString(format: "%.2f", le.weight)) kg"
            let intensity = "Intensity: \(NSString(format: "%.2f", le.intensity))"
            let duration = "\(NSString(format: "%.0f", le.end.timeIntervalSince1970 - le.start.timeIntervalSince1970))s"
            cell.detailTextLabel!.text = "\(le.start.formatTime()) - \(duration) - \(weight) - \(intensity)"
            return cell
        default:
            fatalError()
        }
    }
    
}
