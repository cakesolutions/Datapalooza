import CoreData

extension NSManagedObjectContext {

    func countForFetchRequest(request: NSFetchRequest) -> Int? {
        var error: NSError?
        let count = countForFetchRequest(request, error: &error)
        
        if error == nil { return count }
        else { return nil }
    }
    
}
