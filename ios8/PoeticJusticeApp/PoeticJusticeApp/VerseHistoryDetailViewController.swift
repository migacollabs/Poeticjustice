//
//  DetailViewController.swift
//  MividioCam2
//
//  Created by Mat Mathews on 12/20/14.
//  Copyright (c) 2014 Miga Collabs. All rights reserved.
//

import UIKit

class VerseHistoryDetailViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var verseTitle: UILabel!
    @IBOutlet weak var verseText: UITextView!
    
    var detailItem: VerseHistoryRec? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }
    
    func configureView() {
        println("configureView called")
        // Update the user interface for the detail item.
        if let vhr: VerseHistoryRec = self.detailItem {
            if let title = self.verseTitle{
                title.text = vhr.title
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    
    // MARK: UITextFieldDelegate methods
    
    func textFieldDidBeginEditing(textField: UITextField!) {    //delegate method
        println("textFieldDidBeginEditing called")
    }
    
    func textFieldShouldEndEditing(textField: UITextField!) -> Bool {  //delegate method
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField!) -> Bool {   //delegate method
        textField.resignFirstResponder()
        return true
    }
    
}

