//
//  GameCompleteViewController.swift
//  PoeticJusticeApp
//
//  Created by Larry Johnson on 2/22/15.
//  Copyright (c) 2015 Miga Col.Labs. All rights reserved.
//

import UIKit

class GameCompleteViewController: UIViewController {

    @IBOutlet var avatarImage: UIImageView!
    @IBOutlet var userNameLabel: UILabel!
    @IBOutlet var messageLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.layer.cornerRadius = 5
        self.view.layer.shadowOpacity = 0.8
        self.view.layer.shadowOffset = CGSizeMake(0.0, 0.0)

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        let user : User = NetOpers.sharedInstance.user
        if (user.is_logged_in()) {
            
            avatarImage.image = UIImage(named: user.avatarName)
            
            userNameLabel.text = "Congratulations \(user.user_name)!"
            
            messageLabel.text = "You've finished the game!  Not many have reached level 7, but you did.  You truly are a poet.  Plus your score total is " + String(NetOpers.sharedInstance.user.user_score) + " which is quite high.  Well done!"
            
        }
    }

    @IBOutlet var closeButton: UIButton!
    
    
    @IBAction func handleClose(sender: AnyObject) {
        self.view.removeFromSuperview()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
