//
//  MRManagedExerciseSession+CoreDataProperties.swift
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

extension MRManagedExerciseSession {

    @NSManaged var exerciseModelId: String
    @NSManaged var id: String
    @NSManaged var sensorData: NSData?
    @NSManaged var start: NSDate
    @NSManaged var labelledExercises: NSSet
    @NSManaged var classifiedExercises: NSSet

}
