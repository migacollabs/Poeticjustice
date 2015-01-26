//
//  WriteLineViewController.swift
//  PoeticJusticeApp
//
//  Created by Larry Johnson on 1/19/15.
//  Copyright (c) 2015 Miga Collabs. All rights reserved.
//

import UIKit

class WriteLineViewController: UIViewController {
    
    @IBOutlet weak var topicLabel: UILabel!
    @IBOutlet weak var topicButton: UIButton!
    
    // TODO: is there a way to reset this?
    var score : Int = 1;
    var line : String = "";
    var verseId : Int = 0;
    
    var topic: Topic?{
        didSet{
            self.configureView()
        }
    }

    @IBOutlet var userLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Add a Line"
        
        self.configureView()
        updateUserLabel()
    }
    
    override func viewDidAppear(animated: Bool) {
        updateUserLabel()
    }
    
    func configureView(){
        if let label = self.topicLabel {
            if let t = self.topic{
                label.text? = t.name as String
            }
        }
        
        if let t_btn = self.topicButton{
            if let t = self.topic{
                t_btn.setImage(UIImage(named: t.main_icon_name as String), forState: .Normal)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateUserLabel() {
        if let un = NetOpers.sharedInstance.user?.user_name as? String {
            if let us = NetOpers.sharedInstance.user?.user_score as? Int {
                self.userLabel.text = un + " // " + String(us) + " points"
            }
        } else {
            self.userLabel.text = "You are not signed in"
        }
    }
    
    @IBAction func decrementScore(sender: AnyObject) {
        score = 0;
    }
    
    @IBAction func incrementScore(sender: AnyObject) {
        score = 2;
    }

    @IBOutlet var setLine: UITextView!
    
    @IBAction func sendLine(sender: AnyObject) {
        println("Clicked send with score " + String(score) + " " +
        setLine.text)
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
