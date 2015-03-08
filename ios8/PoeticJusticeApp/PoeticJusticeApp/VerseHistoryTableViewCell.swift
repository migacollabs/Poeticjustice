//
//  VerseHistoryTableViewCell.swift
//  PoeticJusticeApp
//
//  Created by Mat Mathews on 3/8/15.
//  Copyright (c) 2015 Miga Col.Labs. All rights reserved.
//

import UIKit

class VerseHistoryTableViewCell: UITableViewCell {

    @IBOutlet weak var topicImage: UIImageView!
    @IBOutlet weak var verseTitle: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
