//
//  TopicsGameViewController.swift
//  PoeticJusticeApp
//
//  Created by Larry Johnson on 1/26/15.
//  Copyright (c) 2015 Miga Col.Labs. All rights reserved.
//

import UIKit

class TopicsGameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Choose a Topic"
        // Do any additional setup after loading the view.
        
        updateUserLabel()
    }
    
    override func viewWillAppear(animated : Bool) {
        updateUserLabel()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func refresh() {
        updateUserLabel()
    }
    
    @IBOutlet var userLabel: UILabel!
    
    func updateUserLabel() {
        if let un = NetOpers.sharedInstance.user?.user_name as? String {
            if let us = NetOpers.sharedInstance.user?.user_score as? Int {
                self.userLabel.text = un + " // " + String(us) + " points"
            }
        } else {
            self.userLabel.text = "You are not signed in"
        }
    }
    
    var topics = Dictionary<Int, AnyObject>()
    
    @IBAction func handleTopicButton(sender: AnyObject) {
        
        var btn = sender as UIButton
        var topic : Topic?
        
        println(btn.imageView?.image?)
        
        for (i, t) in self.topics {
            if let to = t as? Topic {
                if let min = to.main_icon_name as? String {
                    
                }
            }
        }
       
        let vc = WriteLineViewController(nibName: "WriteLineViewController", bundle: nil)
        vc.topic = topic
        navigationController?.pushViewController(vc, animated: false)
        
        println("loading WriteLineViewController")
        // don't remove the nav bar so the user can go back
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
