import WatchKit
import Foundation
import WatchConnectivity
import MuvrKit

class MRExerciseRow: NSObject {
    @IBOutlet weak var textLabel: WKInterfaceLabel!
    
    func setExercise(exercise: (String, String)) {
        textLabel.setText(exercise.1)
    }
}

class MRMainController: WKInterfaceController, MRSessionProgressGroup {
    @IBOutlet weak var exerciseModel: WKInterfacePicker!
    @IBOutlet weak var startGroup: WKInterfaceGroup!
    @IBOutlet weak var progressGroup: WKInterfaceGroup!
    @IBOutlet weak var exercisesTable: WKInterfaceTable!
    
    @IBOutlet weak var titleLabel: WKInterfaceLabel!
    @IBOutlet weak var timeLabel: WKInterfaceLabel!
    @IBOutlet weak var statsLabel: WKInterfaceLabel!
    
    private let exercises = [
        ("demo-bc-only", "Biceps curl"),
        ("demo-te-only", "Triceps extension"),
        ("demo-lr-only", "Lateral raise")
    ]

    private var renderer: MRSessionProgressGroupRenderer?

    private var exerciseModelMetadataIndex: Int = 0
    
    override func willActivate() {
        super.willActivate()
        let sd = MRExtensionDelegate.sharedDelegate()
        exerciseModel.setItems(sd.exerciseModelMetadata.map { _, title in return WKPickerItem.withTitle(title) })
        
        updateUI()
        renderer = MRSessionProgressGroupRenderer(group: self)
    }
    
    override func didDeactivate() {
        renderer = nil
        super.didDeactivate()
    }
    
    private func updateUI() {
        let sd = MRExtensionDelegate.sharedDelegate()
        clearAllMenuItems()
        if let (session, _) = sd.currentSession {
            addMenuItemWithItemIcon(WKMenuItemIcon.Pause, title: "Pause", action: "pause")
            addMenuItemWithItemIcon(WKMenuItemIcon.Trash, title: "Stop",  action: "stop")

            if session.demo {
                exercisesTable.setNumberOfRows(exercises.count, withRowType: "exercise")
                (0..<exercisesTable.numberOfRows).forEach { i in
                    let row = exercisesTable.rowControllerAtIndex(i) as! MRExerciseRow
                    row.setExercise(exercises[i])
                }
            } else {
                // TODO: real session will probably want to display plan or something
                exercisesTable.setNumberOfRows(0, withRowType: "exercise")
            }
        } else {
            // NB. this is correct; even though it looks exactly like the line above,
            // NB. it will stay like this.
            exercisesTable.setNumberOfRows(0, withRowType: "exercise")
        }
        
        progressGroup.setHidden(sd.currentSession == nil)
        startGroup.setHidden(sd.currentSession != nil)
    }
    
    override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {
        if MRExtensionDelegate.sharedDelegate().currentSession?.0.demo ?? false {
            let (resourceName, _) = exercises[rowIndex]
            let resourcePath = NSBundle.mainBundle().pathForResource(resourceName, ofType: "raw")!
            let data = NSData(contentsOfFile: resourcePath)!
            let sd = try! MKSensorData(decoding: data)
            MRExtensionDelegate.sharedDelegate().sendSamples(sd)
        }
    }
    
    func pause() {
        
    }
    
    func stop() {
        MRExtensionDelegate.sharedDelegate().endLastSession()
        updateUI()
    }
    
    ///
    /// Called when the user clicks the session start button
    ///
    @IBAction func beginSession() {
        MRExtensionDelegate.sharedDelegate().startSession(exerciseModelMetadataIndex: exerciseModelMetadataIndex, demo: false)
        updateUI()
    }
    
    ///
    /// Called when the user clicks the start demo button
    ///
    @IBAction func beginDemo() {
        MRExtensionDelegate.sharedDelegate().startSession(exerciseModelMetadataIndex: exerciseModelMetadataIndex, demo: true)
        updateUI()
    }
    
    ///
    /// Updates the currently-selected box
    ///
    @IBAction func exerciseModelPickerAction(index: Int) {
        exerciseModelMetadataIndex = index
    }

}

extension WKPickerItem {
    
    static func withTitle(title: String) -> WKPickerItem {
        let i = WKPickerItem()
        i.title = title
        return i
    }
    
}
