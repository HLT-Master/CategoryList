//
//  CategoryTableViewCell.swift
//  MagicApp
//
//  Created by TEAM-HLT on 6/22/16.
//  Copyright © 2016 TEAM-HLT. All rights reserved.
//

import UIKit

class CategoryTableViewCell: UITableViewCell {

    @IBOutlet weak var NameLabel: UILabel!
    
    @IBOutlet weak var IDLabel: UILabel!
    
    @IBOutlet weak var LockImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
