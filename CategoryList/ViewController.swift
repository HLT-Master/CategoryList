//
//  ViewController.swift
//  CategoryList
//
//  Created by Patrick Kellen on 6/22/16.
//  Copyright © 2016 HLT. All rights reserved.
//

import UIKit
import Alamofire
import CoreData

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var categories : [Category]? = [Category]()
    var parentCategory : Category?
    var managedContext : NSManagedObjectContext!
    
    @IBOutlet weak var tableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Get our managed object context from the app delegate
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        managedContext = appDelegate.managedObjectContext
        
        //Set up tableview cells
        tableView.registerClass(UITableViewCell.self,
                                forCellReuseIdentifier: "Cell")

        
        //If this is the top level (parentCategory == nil), fetch the data from the API. Otherwise, don't fetch anything,
        //we don't need to fetch more than once
        
        if self.parentCategory == nil {
            self.fetchCategoriesFromAPI { (categoryData) in
                if(categoryData != nil) {
                    self.insertOrUpdateCategories(categoryData!)
                    self.categories = self.loadCategoriesFromDatabase()
                    self.tableView.reloadData()
                }
            }
        } else {
            self.categories = self.loadCategoriesFromDatabase()
            self.tableView.reloadData()
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    func loadCategoriesFromDatabase() -> [Category]? {
        
        //If the controller has a parent category, get categories with that parent category. Otherwise, get categories that don't have a parent category.
        let fetchRequest = NSFetchRequest(entityName: "Category")
        if parentCategory != nil {
            fetchRequest.predicate = NSPredicate(format: "parentCategory = %@", parentCategory!)
        } else {
            fetchRequest.predicate = NSPredicate(format: "parentCategory = nil")
        }
        
        //Execute the fetch request
        do {
            let results =
                try managedContext.executeFetchRequest(fetchRequest) as! [Category]
            return results
        } catch let error as NSError {
            print("Error: %@", error)
            return nil
        }
        
    }
    
    func fetchCategoriesFromAPI(completion: ([[String : AnyObject]]?) -> Void) {
        
        Alamofire.request(
            .GET,
            "https://staging-hlt-web-service.herokuapp.com/api/v3/categories",
            headers: ["X-HLTBundleIdentifier" : "com.hltcorp.integrationtest"],
            encoding: .URL)
            .validate()
            .responseJSON { (response) -> Void in
                guard response.result.isSuccess else {
                    print("Error while fetching categories: \(response.result.error)")
                    completion(nil)
                    return
                }
                
                guard let value = response.result.value as? [String: AnyObject],
                    
                    records = value["records"] as? [[String: AnyObject]] else {
                        print("Malformed data received from fetchCategories")
                        completion(nil)
                        return
                }
                
                completion(records)
        }
        
    }
    
    func insertOrUpdateCategories(categoryData: [[String : AnyObject]]) {
     
        //Iterate over our array of attributes and insert
        for attributes in categoryData {
            self.insertOrUpdateCategory(attributes)
        }
        
        let appDelegate =
            UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.saveContext()
        
    }
    
    func categoryExists(id: NSNumber) -> Category? {

        //See if we already have a category matching this id
        
        do {
            let fetchRequest = NSFetchRequest(entityName: "Category")
            fetchRequest.predicate = NSPredicate(format: "id = %@", id)
            let results =
                try managedContext.executeFetchRequest(fetchRequest) as! [Category]
            if(results.count > 0) {
                return results.first
            } else {
                return nil
            }
        } catch let error as NSError {
            print("Error: %@", error)
            return nil
        }
        
    }
    
    func insertCategoryIfNotDuplicate(id: NSNumber) -> Category {
        
        if let category = self.categoryExists(id){
            
            //Category already exists, return it!
            return category
            
        } else {
            
            //Category does not yet exist, create a new one and return it
            let categoryEntity = NSEntityDescription.entityForName("Category", inManagedObjectContext: managedContext)
            let category = NSManagedObject(entity: categoryEntity!, insertIntoManagedObjectContext: managedContext) as! Category
            return category
            
        }

    }

    func insertOrUpdateCategory(attributes: [String : AnyObject]) -> Category? {

        //Check that we have the required attributes
        guard let name = attributes["name"] as? String,
            let id = attributes["id"] as? NSNumber,
            let isFree = attributes["is_free"] as? NSNumber
            else {
                print("Malformed categoryDictionary: \(attributes)")
                return nil
        }
        
        //Insert category if it doesn't already exist
        let category = self.insertCategoryIfNotDuplicate(id)
        
        //Set attributes
        category.name = name
        category.id = id
        category.isFree = isFree
        
        //Parent might be nil, so check!
        if let parentCategoryID = attributes["parent_category_id"] as? NSNumber {
            
            //Create the parent category if it doesn't already exist
            let parentCategory = self.insertCategoryIfNotDuplicate(parentCategoryID)
            category.parentCategory = parentCategory
            
        }
        
        return category
        
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.categories!.count
        
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        //Get our cell
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell")
        
        //Allow multiple lines of text
        cell?.textLabel!.numberOfLines = 0
        
        //Get the category and set the label
        let category = self.categories![indexPath.row]
        cell?.textLabel!.text = category.name
        
        //Show a lock icon if the category is not free, otherwise show nothing
        if category.isFree!.boolValue {
            cell?.imageView!.image = nil
        } else {
            cell?.imageView!.image = UIImage(named:"icon-lock")?.imageWithRenderingMode(.AlwaysTemplate)
            cell?.imageView!.tintColor = UIColor.redColor()
        }
            
        //If the category has children, show an arrow on the right. Otherwise show nothing
        if category.childCategories!.count > 0 {
            cell?.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            cell?.selectionStyle = UITableViewCellSelectionStyle.Default
        } else {
            cell?.accessoryType = UITableViewCellAccessoryType.None
            cell?.selectionStyle = UITableViewCellSelectionStyle.None

        }
        
        return cell!
        
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        //If this category has children, push another view controller. Otherwise don't do anything.
        let category = self.categories![indexPath.row]
        if category.childCategories?.count > 0 {
            let controller = self.storyboard?.instantiateViewControllerWithIdentifier("CategoryList") as! ViewController
            controller.parentCategory = category
            self.navigationController!.pushViewController(controller, animated: true)
        }
        
    }
    
}

