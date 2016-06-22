//
//  StartViewController.swift
//  MagicApp
//
//  Created by TEAM-HLT on 6/22/16.
//  Copyright © 2016 TEAM-HLT. All rights reserved.
//

import UIKit
import CoreData

class StartViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        //deleteData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func deleteData() {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        do {
            let request = NSFetchRequest(entityName: "Category")
            if let result = try managedContext.executeFetchRequest(request) as? [Category] {
                for category in result {
                    managedContext.deleteObject(category)
                    try managedContext.save()
                }
            }
        } catch {
            print("Failed to delete")
        }
    }

}
