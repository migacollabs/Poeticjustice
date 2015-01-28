//
//  WriteLineViewController.swift
//  PoeticJusticeApp
//
//  Created by Larry Johnson on 1/19/15.
//  Copyright (c) 2015 Miga Collabs. All rights reserved.
//

import UIKit
import Foundation

class Verse {
    let verse_data: NSDictionary
    
    init(rec:NSDictionary){
        self.verse_data = rec
    }
    
    var id: AnyObject? {
        get {
            if let x = self.verse_data["verse_id"] as? Int{
                return x
            }
            return nil
        }
    }
    
    var next_user_id : AnyObject? {
        get {
            if let x = self.verse_data["next_user_id"] as? Int{
                return x
            }
            return nil
        }
    }
    
    var owner_id : AnyObject? {
        get {
            if let x = self.verse_data["owner_id"] as? Int{
                return x
            }
            return nil
        }
    }
    
    var lines : [AnyObject]? {
        get {
            if let x = self.verse_data["lines"] as? [String] {
                return x
            }
            return nil
        }
    }
    
}

class WriteLineViewController: UIViewController {
    
    @IBOutlet weak var topicLabel: UILabel!
    @IBOutlet weak var topicButton: UIButton!
    
    var maxNumPlayers : Int = 2
    
    @IBAction func setNumberPlayers(sender: AnyObject) {
        let sc = (sender as UISegmentedControl)
        switch sc.selectedSegmentIndex
        {
        case 0:
            maxNumPlayers = 2
        case 1:
            maxNumPlayers = 3
        case 2:
            maxNumPlayers = 4
        case 3:
            maxNumPlayers = 5
        default:
            break; 
        }
    }
    
    @IBOutlet var verseView: UITextView!
    
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
        
        verseView.text = ""
        setLine.text = ""
        
        title = "Your Line"
        
        self.configureView()
        updateUserLabel()
        
    }
    
    var lastTabbed : NSDate?
    
    @IBAction func refreshVerseView(sender: AnyObject) {
        viewWillAppear(true)
    }
    
    override func viewWillAppear(animated: Bool) {
        
        if let t = topic {
            title = t.name as? String
        }
        
        if (NetOpers.sharedInstance.userId>0) {
            updateUserLabel()
            
            var refresh : Bool = false
            
            if (lastTabbed==nil) {
                refresh = true
            } else {
                var elapsedTime = NSDate().timeIntervalSinceDate(lastTabbed!)
                refresh = (elapsedTime>NSTimeInterval(10.0))
            }
            
            if (refresh) {
                
                var params = Dictionary<String,AnyObject>()
                params["topic_id"]=topic?.id
                params["user_id"]=NetOpers.sharedInstance.userId
                
                println("hitting active-verses url")
                println(params)
                
                NetOpers.sharedInstance.post(NetOpers.sharedInstance.appserver_hostname! + "/u/active-verses", params: params, loadVerse)
                
                lastTabbed = NSDate()
            }
        
        }
        
    }
    
    func configureView(){
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
    
    var verse : Verse?
    
    func loadVerse(data: NSData?, response: NSURLResponse?, error: NSError?) {
        let httpResponse = response as NSHTTPURLResponse
        if httpResponse.statusCode == 200 {
            if data != nil {
                
                println("loading data...")
                
                let jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(
                    data!, options: NSJSONReadingOptions.MutableContainers,
                    error: nil) as NSDictionary
                
                if let results = jsonResult["results"] as? NSDictionary {
                    
                    println(results)
                    
                    verse = Verse(rec:results)
                    
                    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
                        dispatch_async(dispatch_get_main_queue(),{
                            print(self.verse?.lines)
                            
                            self.verseView.text = ""
                            
                            if let lines = self.verse?.lines as? [String] {
                                for l : String in lines {
                                    self.verseView.text = self.verseView.text + "\n" + l
                                }
                            } else {
                                self.scoreView.hidden = false
                                self.sendButton.hidden = false
                            }
                            
                            if let nextid = self.verse?.next_user_id as? Int {
                                // if it's my turn, let me do it to it
                                if (nextid==NetOpers.sharedInstance.userId) {
                                    self.scoreView.hidden = false
                                    self.sendButton.hidden = false
                                }
                            } else {
                            
                            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                        })
                    })
                } else {
                    println("unable to get results")
                }
                
            }
        }
        
        if (error != nil) {
            println(error)
        }
        
    }

    @IBOutlet var sendButton: UIButton!
    @IBOutlet var scoreView: UIView!
    @IBOutlet var setLine: UITextView!
    
    @IBAction func sendLine(sender: AnyObject) {
        println("Clicked send with score " + String(score) + " " +
        setLine.text)
        
        var params = Dictionary<String,AnyObject>()
        params["topic_id"]=topic?.id
        params["line"]=setLine.text
        
        if let v = verse {
            // existing verse
            params["verse_id"]=v.id
            params["score_increment"]=score
        } else {
            // new verse
            params["max_participants"]=maxNumPlayers
        }
        
        println("hitting saveline url")
        println(params)
        
        NetOpers.sharedInstance.post(NetOpers.sharedInstance.appserver_hostname! + "/u/save-line", params: params, loadVerse)
        
        self.setLine.text = ""
        self.scoreView.hidden = true
        self.sendButton.hidden = true
        
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
