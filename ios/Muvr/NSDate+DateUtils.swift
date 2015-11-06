import Foundation

extension NSDate {
    
    ///
    /// Computes date only components from an instance that (may) also contains time
    ///
    var dateOnly: NSDate {
        let components = NSCalendar.currentCalendar().components([NSCalendarUnit.Year, NSCalendarUnit.Month, NSCalendarUnit.Day], fromDate: self)
        return NSCalendar.currentCalendar().dateFromComponents(components)!
    }
    
    ///
    /// Adds the specified number of days to this NSDate
    ///
    func addDays(days: Int) -> NSDate {
        return NSCalendar.currentCalendar().dateByAddingUnit(NSCalendarUnit.Day, value: days, toDate: self, options: NSCalendarOptions.MatchFirst)!
    }
    
    ///
    /// Adds the specified number of hours to this NSDate
    ///
    func addHours(hours: Int) -> NSDate {
        return NSCalendar.currentCalendar().dateByAddingUnit(NSCalendarUnit.Hour, value: hours, toDate: self, options: NSCalendarOptions.MatchFirst)!
    }
    
    ///
    /// Adds the specified number of seconds to this NSDate
    ///
    func addSeconds(seconds: Int) -> NSDate {
        return NSCalendar.currentCalendar().dateByAddingUnit(NSCalendarUnit.Second, value: seconds, toDate: self, options: NSCalendarOptions.MatchFirst)!
    }
    
    ///
    /// returns a string (HH:mm) representing the time of this NSDate
    func formatTime() -> String {
        let format = NSDateFormatter()
        format.dateFormat = "HH:mm"
        return format.stringFromDate(self)
    }
    
}