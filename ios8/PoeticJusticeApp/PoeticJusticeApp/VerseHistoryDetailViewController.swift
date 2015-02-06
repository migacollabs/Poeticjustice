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
            if let vt = self.verseText{
                vt.text! = ""
                for lineRec in vhr.lines_recs{
                    var user_name = ""
                    if let pr = vhr.players[lineRec.player_id]{
                        user_name = pr.user_name
                    }
                    vt.text! += lineRec.text
                    vt.text! += "  - \(user_name)"
                    vt.text! += "\n"
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
//        self.load_verse()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func load_verse(){
        
//        if let verseHistoryRec = self.detailItem{
//        
//            NetOpers.sharedInstance.get(
//                NetOpers.sharedInstance.appserver_hostname! + "/v/verse/id=\(verseHistoryRec.id)", {data, response, error -> Void in
//                    
//                    let httpResponse = response as NSHTTPURLResponse
//                    if httpResponse.statusCode == 200 {
//                        if data != nil {
//                            
//                            let jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(
//                                data!, options: NSJSONReadingOptions.MutableContainers,
//                                error: nil) as NSDictionary
//                            
//                            var verse = ""
//                            if let results = jsonResult["results"] as? NSDictionary{
//                                if let lines = results["lines"] as? NSArray{
//                                    for line in lines{
//                                        verse += "\(line)"
//                                    }
//                                }
//                            }
//
//                            dispatch_async(dispatch_get_main_queue(),{
//                                self.verseText.text = verse
//                                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
//                            })
//                            
//                        }
//                    }
//                    
//            })
//        }
        
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

