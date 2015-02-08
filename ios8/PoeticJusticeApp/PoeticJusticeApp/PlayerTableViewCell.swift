//
//  PlayerTableViewCell.swift
//  PoeticJusticeApp
//
//  Created by Mat Mathews on 2/6/15.
//  Copyright (c) 2015 Miga Col.Labs. All rights reserved.
//

import UIKit

class PlayerTableViewCell: UITableViewCell {

    @IBOutlet weak var avatarImage: UIImageView!
    @IBOutlet weak var userName: UILabel!
    
    @IBOutlet weak var verseLine: UITextView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
