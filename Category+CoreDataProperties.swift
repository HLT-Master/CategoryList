//
//  Category+CoreDataProperties.swift
//  MagicApp
//
//  Created by TEAM-HLT on 6/22/16.
//  Copyright © 2016 TEAM-HLT. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Category {

    @NSManaged var name: String?
    @NSManaged var id: NSNumber?
    @NSManaged var free: NSNumber?
    @NSManaged var parentCategory: Category?
    @NSManaged var childCategory: NSSet?
    
    @NSManaged func addChildObject(value: Category)
    @NSManaged func removeChildObject(value: Category)
    @NSManaged func addChild(value: Set<Category>)
    @NSManaged func removeChild(value: Set<Category>)

}
