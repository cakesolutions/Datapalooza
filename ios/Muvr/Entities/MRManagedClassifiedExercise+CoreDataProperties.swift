//
//  MRManagedClassifiedExercise+CoreDataProperties.swift
//  Muvr
//
//  Created by Jan Machacek on 10/25/15.
//  Copyright © 2015 Muvr. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension MRManagedClassifiedExercise {

    @NSManaged var start: NSDate
    @NSManaged var confidence: Double
    @NSManaged var duration: Double
    @NSManaged var exerciseId: String
    @NSManaged var intensity: NSNumber?
    @NSManaged var repetitions: NSNumber?
    @NSManaged var weight: NSNumber?
    @NSManaged var exerciseSession: MRManagedExerciseSession?

}
