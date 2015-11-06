//
//  MRManagedLabelledExercise.swift
//  Muvr
//
//  Created by Jan Machacek on 10/25/15.
//  Copyright © 2015 Muvr. All rights reserved.
//

import Foundation
import CoreData
import MuvrKit

class MRManagedLabelledExercise: NSManagedObject {

    static func insertNewObject(into session: MRManagedExerciseSession, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedLabelledExercise {
        let mo = NSEntityDescription.insertNewObjectForEntityForName("MRManagedLabelledExercise", inManagedObjectContext: managedObjectContext) as! MRManagedLabelledExercise
        mo.exerciseSession = session
        return mo
    }
    
    func isBefore(other: MRManagedClassifiedExercise) -> Bool {
        return start.compare(other.start) == .OrderedAscending
    }

}
