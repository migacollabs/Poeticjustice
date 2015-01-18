//
//  LoginViewController.swift
//  PoeticJusticeApp
//
//  Created by Mat Mathews on 1/14/15.
//  Copyright (c) 2015 Miga Collabs. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {

    @IBOutlet weak var emailAddress: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func openTestView(sender: AnyObject) {
        println(sender)
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        if segue.identifier == "showTabBarController"{
//            // even though the user data is available in the singleton, i've noticed in many docs tutorials
//            // that this pattern is used.. setting up the destination segue with same instance data
//            (segue.destinationViewController as FirstViewController).userDetails = NetOpers.sharedInstance.user
//        }
    }


}
