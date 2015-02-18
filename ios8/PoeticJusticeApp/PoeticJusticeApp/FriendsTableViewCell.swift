//
//  FriendsTableViewCell.swift
//  PoeticJusticeApp
//
//  Created by Mat Mathews on 2/16/15.
//  Copyright (c) 2015 Miga Col.Labs. All rights reserved.
//

import UIKit

class FriendsTableViewCell: UITableViewCell {

    @IBOutlet weak var emailAddress: UILabel!
    @IBOutlet weak var points: UILabel!
    @IBOutlet weak var level: UILabel!
    @IBOutlet weak var avatar: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
