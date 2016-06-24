//
//  CategoryListTests.swift
//  CategoryListTests
//
//  Created by Patrick Kellen on 6/22/16.
//  Copyright © 2016 HLT. All rights reserved.
//

import XCTest
import Alamofire
import Mockingjay
import CoreData

@testable import CategoryList


class CategoryListTests: XCTestCase {
    
    var managedContext: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let appDelegate =
            UIApplication.sharedApplication().delegate as! AppDelegate
        self.managedContext = appDelegate.managedObjectContext
        
        let fetchRequest = NSFetchRequest(entityName: "Category")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        
        do {
            
            let persistentCoordinator = appDelegate.persistentStoreCoordinator
            try persistentCoordinator.executeRequest(deleteRequest, withContext: self.managedContext!)
            try managedContext.save()
        } catch let error as NSError {
            // TODO: handle the error
            print("error %@", error)
            XCTFail()
        }

        
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.

        super.tearDown()
    }
    
    func testLoadCategoriesFromDatabase_NoParentCategory() {
        
        //
        //Insert a few categories
        //
        
        let categoryEntity = NSEntityDescription.entityForName("Category", inManagedObjectContext: self.managedContext!)
        
        //Insert category A
        let categoryA = NSManagedObject(entity: categoryEntity!, insertIntoManagedObjectContext: managedContext) as! CategoryList.Category
        categoryA.name = "Category A"
        categoryA.id = 1
        categoryA.isFree = false
        
        //Insert category B
        let categoryB = NSManagedObject(entity: categoryEntity!, insertIntoManagedObjectContext: managedContext) as! CategoryList.Category
        categoryB.name = "Category B"
        categoryB.id = 2
        categoryB.isFree = true

        
        //Insert category C
        let categoryC = NSManagedObject(entity: categoryEntity!, insertIntoManagedObjectContext: managedContext) as! CategoryList.Category
        categoryC.name = "Category C"
        categoryC.id = 3
        categoryC.isFree = false

        
        let appDelegate =
            UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.saveContext()
        
        //Run
        let controller = ViewController.init()
        let categories = controller.loadCategoriesFromDatabase()!
        controller.parentCategory = nil
        XCTAssertEqual(categories.count, 3)
        XCTAssertTrue(categories.contains(categoryA))
        XCTAssertTrue(categories.contains(categoryB))
        XCTAssertTrue(categories.contains(categoryC))
        
    }
    
    func testLoadCategoriesFromDatabase_WithParentCategory() {

    }
    
    func testFetchCategoriesFromAPI() {
    
        let categoryOne = ["name" : "Category One", "id" : 1]
        let categoryTwo = ["name" : "Category Two", "id" : 2]
        let records = [categoryOne, categoryTwo]
        let body = ["records" : records]
        stub(http(.GET, uri: "/api/v3/categories"), builder: json(body))

        let expectation = expectationWithDescription("expecting completion block to be called")
        
        let controller = ViewController.init()
 
        //Run and verify
        controller.fetchCategoriesFromAPI { (categoryData) in
            
            XCTAssertEqual(categoryData!, records)
            expectation.fulfill()
            
        }
        
        self.waitForExpectationsWithTimeout(10) { error in
            print("test timed out with error \(error)")
        }
        
    }
    
    
    func testInsertOrUpdateCategories() {

        //Setup
        let categoryOne = ["name" : "Category One",
                           "id" : 1,
                           "is_free" : true]
        
        let categoryTwo = ["name" : "Category Two",
                           "id" : 2,
                           "is_free" : false]
        
        let categories = [categoryOne, categoryTwo] as [[String : AnyObject]]
        
        //Run
        let controller = ViewController.init()
        controller.insertOrUpdateCategories(categories)
        
        
        //Verify
        let fetchRequest = NSFetchRequest(entityName: "Category")
        do {
            let results = try managedContext.executeFetchRequest(fetchRequest)
            XCTAssertEqual(results.count, 2)
            XCTAssertTrue(results.contains({$0.name == "Category One" && $0.id == 1}))
            XCTAssertTrue(results.contains({$0.name == "Category Two" && $0.id == 2}))
            
        } catch let error as NSError {
            print("Error: %@", error)
            XCTFail()
        }
        
        
    }
 
}
