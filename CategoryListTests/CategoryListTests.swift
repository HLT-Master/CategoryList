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
    
    func createFixture() -> CategoryList.Category  {
    
        let categoryEntity = NSEntityDescription.entityForName("Category", inManagedObjectContext: self.managedContext!)
        let category = NSManagedObject(entity: categoryEntity!, insertIntoManagedObjectContext: managedContext) as! CategoryList.Category
        category.name = "Category Fixture"
        category.id = 1
        category.isFree = false
        
        save()
        
        return category
    
    }
    
    func save() {
        let appDelegate =
            UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.saveContext()
    }
    
    func testLoadCategoriesFromDatabase_NoParentCategory() {
        
        //
        //Insert a few categories
        //
        

        let categoryA = createFixture()
        categoryA.id = 1
        
        let categoryB = createFixture()
        categoryB.id = 2

        let categoryC = createFixture()
        categoryC.id = 3
        
        //Run
        let controller = ViewController.init()
        let categories = controller.loadCategoriesFromDatabase()!
        controller.parentCategory = nil
        XCTAssertEqual(categories.count, 3)
        XCTAssertTrue(categories.contains(categoryA))
        XCTAssertTrue(categories.contains(categoryB))
        XCTAssertTrue(categories.contains(categoryC))
        
    }
    
    /*
    func testLoadCategoriesFromDatabase_WithParentCategory() {

    }
 */
 
    func testFetchCategoriesFromAPI() {
    
        let categoryOne = ["name" : "Category One", "id" : 1]
        let categoryTwo = ["name" : "Category Two", "id" : 2]
        let records = [categoryOne, categoryTwo]
        let body = ["records" : records]
        stub(http(.GET, uri: "/api/v3/categories"), builder: json(body))

        let expectation = expectationWithDescription("expecting completion block to be called")
        
 
        //Run and verify
        let controller = ViewController.init()
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
 
    func testCategoryForID_DoesExist() {
        
        //Add a category
        let categoryFixture = createFixture()
        
        //Run
        let controller = ViewController.init()
        let category = controller.categoryForID(categoryFixture.id!)
        XCTAssertEqual(category, categoryFixture)

    }
    
    
    func testCategoryForID_DoesNotExist() {

        let controller = ViewController.init()
        let category = controller.categoryForID(1234)
        XCTAssertNil(category)
        
    }
    
    func testInsertCategoryIfNotDuplicate_NotDuplicate() {
        
        let controller = ViewController.init()
        let category = controller.insertCategoryIfNotDuplicate(1234)
        XCTAssertNotNil(category)
        XCTAssertEqual(category.id, 1234)
        
    }
    
    func testInsertCategoryIfNotDuplicate_IsDuplicate() {
        
        //Add a category
        let categoryFixture = createFixture()
        let controller = ViewController.init()
        let category = controller.insertCategoryIfNotDuplicate(categoryFixture.id!)
        
        XCTAssertEqual(categoryFixture, category)
        
        //Make sure there is only one category in the database with this id
        let fetchRequest = NSFetchRequest(entityName: "Category")
        fetchRequest.predicate = NSPredicate(format: "id = \(categoryFixture.id!)")
        do {
            let results =
                try managedContext.executeFetchRequest(fetchRequest) as! [CategoryList.Category]
            XCTAssertEqual(results.count, 1)
        } catch let error as NSError {
            print("Error: %@", error)
            XCTFail()
        }
        
    }

    func testInsertOrUpdateCategory_BadData() {
        
        //Create some bad attributes
        let attributes = ["foo" : "this is not a category",
                          "bar" : 1,
                          "baz" : true]
        
        //Run
        let controller = ViewController.init()
        let category = controller.insertOrUpdateCategory(attributes)
        
        //This should be nil, because the attributes can not be used to create a category
        XCTAssertNil(category)
        
        
    }
    
    func testInsertOrUpdateCategory_Insert() {
        
        let parent = createFixture()
        let attributes = ["name" : "Category One",
                          "id" : 1,
                          "is_free" : true,
                          "parent_category_id" : parent.id!]
        
        //Run
        let controller = ViewController.init()
        let category = controller.insertOrUpdateCategory(attributes)!
        
        //Verify
        XCTAssertEqual(category.name, "Category One")
        XCTAssertEqual(category.id, 1)
        XCTAssertEqual(category.isFree, true)
        XCTAssertEqual(category.parentCategory, parent)
        
    }
    
    func testInsertOrUpdateCategory_Update() {

        let parent = createFixture()
        let child = createFixture()
        child.id = 834
        child.name = "This name should be updated"
        
        let attributes = ["name" : "Updated name",
                          "id" : 834,
                          "is_free" : true,
                          "parent_category_id" : parent.id!]
        
        //Run
        let controller = ViewController.init()
        let category = controller.insertOrUpdateCategory(attributes)!
        
        //Verify
        XCTAssertEqual(category.name, "Updated name")
        XCTAssertEqual(category.id, 834)
        XCTAssertEqual(category.isFree, true)
        XCTAssertEqual(category.parentCategory, parent)
        
    }
    
}
