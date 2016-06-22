//
//  ChildViewController.swift
//  MagicApp
//
//  Created by TEAM-HLT on 6/22/16.
//  Copyright © 2016 TEAM-HLT. All rights reserved.
//

import UIKit

class ChildViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var children = [Category]()

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return children.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell")
        cell!.textLabel?.text = children[indexPath.row].name
        return cell!
    }

}
