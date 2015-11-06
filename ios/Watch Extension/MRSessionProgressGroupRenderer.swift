import WatchKit

class MRSessionProgressGroupRenderer : NSObject {
    private let group: MRSessionProgressGroup
    private var timer: NSTimer?
    
    init(group: MRSessionProgressGroup) {
        self.group = group

        super.init()
        self.timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "update", userInfo: nil, repeats: true)
    }
    
    deinit {
        self.timer?.invalidate()
        self.timer = nil
    }
    
    func update() {
        if let (session, props) = MRExtensionDelegate.sharedDelegate().currentSession {
            let text = NSDateComponentsFormatter().stringFromTimeInterval(session.duration)!
            group.titleLabel.setText(session.modelId)
            group.timeLabel.setText(text)
            group.statsLabel.setText("R \(props.recorded), S \(props.sent)")
        } else {
            group.titleLabel.setText("Idle")
            group.timeLabel.setText(MRExtensionDelegate.sharedDelegate().description)
            group.statsLabel.setText(buildDate())
        }
    }
}
