//
//  FirstViewController.swift
//  PoeticJusticeApp
//
//  Created by Mat Mathews on 1/13/15.
//  Copyright (c) 2015 Miga Collabs. All rights reserved.
//

import UIKit

class FirstViewController: UIViewController, UIGestureRecognizerDelegate {
    

    @IBOutlet weak var topic1: UIButton!
    @IBOutlet weak var topic2: UIButton!
    @IBOutlet weak var topic3: UIButton!
    @IBOutlet weak var topic4: UIButton!
    @IBOutlet weak var topic5: UIButton!
    @IBOutlet weak var topic6: UIButton!
    @IBOutlet weak var topic7: UIButton!
    @IBOutlet weak var topic8: UIButton!
    @IBOutlet weak var topic9: UIButton!
    @IBOutlet weak var topic10: UIButton!
    @IBOutlet weak var topic11: UIButton!
    @IBOutlet weak var topic12: UIButton!
    @IBOutlet weak var topic13: UIButton!
    @IBOutlet weak var topic14: UIButton!
    @IBOutlet weak var topic15: UIButton!
    @IBOutlet weak var topic16: UIButton!
    @IBOutlet weak var topic17: UIButton!
    @IBOutlet weak var topic18: UIButton!
    @IBOutlet weak var topic19: UIButton!
    @IBOutlet weak var topic20: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.topic1.setImage(
            UIImage(named: "Ghost.png"), forState: .Normal)
        self.topic1.tag = 1
        self.topic1.addTarget(self, action: "selectedTopic:", forControlEvents: .TouchUpInside)
        
        self.topic2.setImage(
            UIImage(named: "American-Football.png"), forState: .Normal)
        self.topic2.tag = 2
        self.topic2.addTarget(self, action: "selectedTopic:", forControlEvents: .TouchUpInside)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func gestureRecognizer(UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWithGestureRecognizer:UIGestureRecognizer) -> Bool {
            println("shouldRecS returning true")
            return true
    }
    
    var userDetails: User? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }
    
    func configureView(){
        // enable / disable topic icons
    }
    
    
    @IBAction func clickEventOnImage(recognizer:UITapGestureRecognizer){
        // this doesn't work yet
        println(recognizer)
    }
    
    @IBAction func selectedFootball(sender: AnyObject) {
        println("selected football")
        println(sender)
    }
    @IBAction func selectedLolly(sender: AnyObject) {
        println("selected lollypop")
        println(sender)
    }

    @IBAction func selectedCassette(sender: AnyObject) {
        println("selected cassette")
        println(sender)
    }
    
    @IBAction func selectedTopic(sender: AnyObject) {
        println("selected a topic")
        println(sender.tag)
    }
    
}

