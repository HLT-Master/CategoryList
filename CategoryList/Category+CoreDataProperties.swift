//
//  Category+CoreDataProperties.swift
//  CategoryList
//
//  Created by Patrick Kellen on 6/23/16.
//  Copyright © 2016 HLT. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Category {

    @NSManaged var id: NSNumber?
    @NSManaged var name: String?
    @NSManaged var isFree: NSNumber?
    @NSManaged var parentCategory: Category?
    @NSManaged var childCategories: NSSet?

}
