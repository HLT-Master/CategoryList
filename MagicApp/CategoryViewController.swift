//
//  CategoryViewController.swift
//  MagicApp
//
//  Created by TEAM-HLT on 6/22/16.
//  Copyright © 2016 TEAM-HLT. All rights reserved.
//

import UIKit
import CoreData
import Alamofire

class CategoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var categories = [Category]()
    
    var queue = [Int:Int]()
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchCategories()
        loadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if(segue.identifier == "Children") {
            let cell = sender as! CategoryTableViewCell
            let id = Int((cell.IDLabel.text)!)
            let controller = segue.destinationViewController as! ChildViewController
            controller.children = fetchChildren(id!)
        }
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject!) -> Bool {
        if(identifier == "Children") {
            let cell = sender as! CategoryTableViewCell
            if(!cell.LockImage.hidden) {
                return false
            }
        }
        return true
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as! CategoryTableViewCell
        cell.NameLabel.text = categories[indexPath.row].name
        cell.IDLabel.text = String(categories[indexPath.row].id as! Int)
        if(categories[indexPath.row].free == true) {
            cell.LockImage.hidden = true
        } else {
            cell.LockImage.hidden = false
        }
        return cell
    }
    
    func loadData() {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "Category")
        fetchRequest.predicate = NSPredicate(format: "parentCategory.@count == 0")
        let sortAlpha = NSSortDescriptor.init(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [sortAlpha]
        do {
            let results = try managedContext.executeFetchRequest(fetchRequest)
            self.categories = results as! [Category]
        } catch let error as NSError {
            print("Error: %@", error)
        }
        self.tableView.reloadData()
    }
    
    func fetchCategories() {
        Alamofire.request(
            .GET,
            "http://localhost:3000/api/v3/categories",
            headers: ["X-User-Email" : "jason@iastate.edu", "X-User-Token" : "4V2UEA1fKqYBfRsSnodA", "X-HLTBundleIdentifier" : "com.higherlearning.nclex"])
            .responseJSON { response in
                guard response.result.isSuccess else {
                    print("Error while fetching categories: \(response.result.error)")
                    return
                }
                let responseJSON = response.result.value as? [String: AnyObject]
                let results = responseJSON!["records"] as? [AnyObject]
                for result in results! {
                    let name = result["name"] as! String
                    let id = (result["id"] as! Int)
                    let free = (result["is_free"] as! Bool)
                    var parent_id = (result["parent_category_id"] as? Int)
                    if(parent_id == nil) {
                        parent_id = -1
                    }
                    self.saveCategory(name, id: id, parent_id: parent_id!, free: free)
                }
                self.addRelationships()
                self.loadData()
        }
    }
    
    func saveCategory(name: String, id: Int, parent_id: Int, free: Bool) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        if(fetchCategory(id) == nil) {
            let entity = NSEntityDescription.entityForName("Category", inManagedObjectContext: managedContext)
            let category = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext) as! Category
            category.name = name
            category.id = id
            category.free = free
            if(parent_id > 0) {
                let parent = fetchCategory(parent_id)
                if(parent != nil) {
                    category.parentCategory = parent
                } else {
                    queue.updateValue(parent_id, forKey: id)
                }
            }
            do {
                try managedContext.save()
            } catch let error as NSError  {
                print("Could not save \(error), \(error.userInfo)")
            }
            
        }
    }
    
    func fetchCategory(id: Int) -> Category? {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "Category")
        fetchRequest.predicate = NSPredicate(format: "id == %@", String(id))
        do {
            let results = try managedContext.executeFetchRequest(fetchRequest)
            if(results.count > 0) {
                return results.first as? Category
            }
        } catch let error as NSError {
            print("Error: %@", error)
        }
        return nil
    }
    
    func addRelationships() {
        for (key, value) in queue {
            let child = fetchCategory(key)
            child?.parentCategory = fetchCategory(value)
            do {
                try child!.managedObjectContext!.save()
            } catch let error as NSError  {
                print("Could not save \(error), \(error.userInfo)")
            }
        }
    }
    
    func fetchChildren(id: Int) -> [Category] {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "Category")
        fetchRequest.predicate = NSPredicate(format: "%K == %@", "parentCategory.id", String(id))
        let sortAlpha = NSSortDescriptor.init(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [sortAlpha]
        do {
            let results = try managedContext.executeFetchRequest(fetchRequest)
            return results as! [Category]
        } catch let error as NSError {
            print("Error: %@", error)
        }
        return [Category]()
    }
    
}
