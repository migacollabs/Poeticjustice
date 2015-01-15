//
//  FirstViewController.swift
//  PoeticJusticeApp
//
//  Created by Mat Mathews on 1/13/15.
//  Copyright (c) 2015 Miga Collabs. All rights reserved.
//

import UIKit

class FirstViewController: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var football: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let tapr = UITapGestureRecognizer(target:self, action:Selector("clickEventOnImage:"))
        tapr.numberOfTapsRequired = 1
        tapr.delegate = self
        self.football.addGestureRecognizer(tapr)
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
        ()
    }
    
    
    @IBAction func clickEventOnImage(recognizer:UITapGestureRecognizer){
        // this doesn't work yet
        println(recognizer)
    }
    
    @IBAction func selectedThing(sender: AnyObject) {
        println("selected lightbulb")
        println(sender)
    }
    @IBAction func selectedLolly(sender: AnyObject) {
        println("selected lollypop")
        println(sender)
    }

}

