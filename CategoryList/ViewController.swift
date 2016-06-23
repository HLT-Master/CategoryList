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

class ViewController: UIViewController, UITableViewDataSource {
    
    var categories : [Category]?
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerClass(UITableViewCell.self,
                                forCellReuseIdentifier: "Cell")
        // Do any additional setup after loading the view, typically from a nib.
        self.fetchCategoriesFromAPI { (categoryData) in
            if(categoryData != nil) {
                self.insertCategories(categoryData!)
                self.categories = self.loadCategoriesFromDatabase()
                self.tableView.reloadData()
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    func loadCategoriesFromDatabase() -> [Category] {
     
        let fetchRequest = NSFetchRequest(entityName: "Category")
        let appDelegate =
            UIApplication.sharedApplication().delegate as! AppDelegate
        
        let managedContext = appDelegate.managedObjectContext
        
        //See if we already have a category matching this id
        var results = []
        do {
            results =
                try managedContext.executeFetchRequest(fetchRequest)
        } catch let error as NSError {
            print("Error: %@", error)
        }
        
        return results as! [Category]
        
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
    
    func insertCategories(categoryData: [[String : AnyObject]]) {
     
        for categoryDictionary in categoryData {
 
            guard let name = categoryDictionary["name"] as? String,
                let id = categoryDictionary["id"] as? NSNumber else {
                    print("Malformed categoryDictionary: \(categoryDictionary)")
                continue
            }
            
            self.insertCategoryIfNotDuplicate(name, id: id)
            
        }
        
    }
    
    func categoryExists(id: NSNumber) -> Category? {
        
        let fetchRequest = NSFetchRequest(entityName: "Category")
        fetchRequest.predicate = NSPredicate(format: "id = %@", id)
        
        let appDelegate =
            UIApplication.sharedApplication().delegate as! AppDelegate
        
        let managedContext = appDelegate.managedObjectContext
        
        //See if we already have a category matching this id
        var results = []
        do {
            results =
                try managedContext.executeFetchRequest(fetchRequest)
        } catch let error as NSError {
            print("Error: %@", error)
        }
        
        if(results.count > 0) {
            return results.firstObject as? Category
        } else {
            return nil
        }
 
    }
    
    func insertCategoryIfNotDuplicate(name: String, id: NSNumber) -> Category {
        
        if let category = self.categoryExists(id) {
            return category
        } else {
            let appDelegate =
                UIApplication.sharedApplication().delegate as! AppDelegate
            let managedContext = appDelegate.managedObjectContext
            let categoryEntity = NSEntityDescription.entityForName("Category", inManagedObjectContext: managedContext)
            let category = NSManagedObject(entity: categoryEntity!, insertIntoManagedObjectContext: managedContext) as! Category
            category.name = name
            category.id = id
            return category
        }

    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if self.categories != nil {
            return self.categories!.count
        } else {
            return 0
        }
        
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell")
        let category = self.categories![indexPath.row]
        cell?.textLabel!.text = category.name
        return cell!
        
    }
    
}

