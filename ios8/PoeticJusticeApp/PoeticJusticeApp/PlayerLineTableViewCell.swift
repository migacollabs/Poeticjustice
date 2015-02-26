//
//  PlayerLineTableViewCell.swift
//  PoeticJusticeApp
//
//  Created by Mat Mathews on 2/9/15.
//  Copyright (c) 2015 Miga Col.Labs. All rights reserved.
//

import UIKit

class PlayerLineTableViewCell: UITableViewCell {

    @IBOutlet weak var verseLine: UITextView!
    @IBOutlet weak var verseLabel: UILabel!
    @IBOutlet weak var avatarImage: UIImageView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var levelBadgeImage: UIImageView!
    
    @IBOutlet weak var votedStar: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        //self.backgroundColor = UIColor.clearColor()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
