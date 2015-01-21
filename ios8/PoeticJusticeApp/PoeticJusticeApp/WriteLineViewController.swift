//
//  WriteLineViewController.swift
//  PoeticJusticeApp
//
//  Created by Larry Johnson on 1/19/15.
//  Copyright (c) 2015 Miga Collabs. All rights reserved.
//

import UIKit

class WriteLineViewController: UIViewController {
    
    // TODO: is there a way to reset this?
    var score : Int = 1;
    var line : String = "";
    var verseId : Int = 0;

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
