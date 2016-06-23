//
//  Category+CoreDataProperties.swift
//  
//
//  Created by Patrick Kellen on 6/22/16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Category {

    @NSManaged var id: NSNumber?
    @NSManaged var name: String?

}
