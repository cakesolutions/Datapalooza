import WatchKit
import Foundation
import HealthKit

class MRGlanceController: WKInterfaceController, MRSessionProgressGroup {
    @IBOutlet weak var titleLabel: WKInterfaceLabel!
    @IBOutlet weak var timeLabel: WKInterfaceLabel!
    @IBOutlet weak var statsLabel: WKInterfaceLabel!
    private var renderer: MRSessionProgressGroupRenderer?

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)        
    }
    
    override func willActivate() {
        renderer = MRSessionProgressGroupRenderer(group: self)
        MRExtensionDelegate.sharedDelegate().applicationDidBecomeActive()
        super.willActivate()
    }

    override func didDeactivate() {
        renderer = nil
        super.didDeactivate()
    }

}
