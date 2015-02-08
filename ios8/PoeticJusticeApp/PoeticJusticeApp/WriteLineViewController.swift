//
//  WriteLineViewController.swift
//  PoeticJusticeApp
//
//  Created by Larry Johnson on 1/19/15.
//  Copyright (c) 2015 Miga Collabs. All rights reserved.
//

import UIKit
import Foundation
import iAd
import AVFoundation

struct VerseRec {
    var id : Int = -1
    var next_index_user_ids : Int = -1 // TODO: remove this, replace with next_index_user_ids
    var owner_id : Int = -1
    var lines : [String] = []
    var is_complete : Bool = false
    var user_ids : [Int] = []
    
    func is_loaded() -> Bool {
        return id>0
    }
}

class WriteLineViewController: UIViewController, ADBannerViewDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var topicLabel: UILabel!
    @IBOutlet weak var topicButton: UIButton!
    
    var maxNumPlayers : Int = 2
    
    @IBOutlet var cancelButton: UIButton!
    var iAdBanner: ADBannerView?
    
    @IBOutlet var verseView: UITextView!
    
    // TODO: is there a way to reset this?
    var score : Int = 1;
    var line : String = "";
    var verseId : Int = 0;
    var should_begin_banner = false
    
    var topic: Topic?{
        didSet{
            self.configureView()
        }
    }
    
    var is_my_turn : Bool = false
    
    // for now, this is just to help clean up nav once this view is reached
    var newVerseViewController : NewVerseViewController?
    var worldVerseViewController : WorldVerseViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var refreshButton : UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Refresh, target: self, action: "refresh")
        self.navigationItem.rightBarButtonItem = refreshButton
        
        self.sendButton.hidden = true
        self.cancelButton.hidden = true
        
        verseView.text = ""
        setLine.text = ""
        
        title = "Your Line"
        
        self.setLine.placeholder  = "Your turn is coming up soon!"
        
        self.setLine.delegate = self
        
        self.configureView()
        
    }
    
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        self.view.endEditing(true);
        return false;
    }
    
    func refresh() {
        if (!is_busy) {
            is_busy = true
            
            viewWillAppear(true)
        }
    }
    
    func updateNavigationTitle() {
        if let t = topic {
            if let ti = t.name as? String {
                title = ti + " / " + String(self.verse.user_ids.count) + " players"
            }
        }
    }
    
    var lastTabbed : NSDate?
    
    override func viewWillAppear(animated: Bool) {
        
        self.cancelButton.hidden = true
        
        var screen_height = UIScreen.mainScreen().bounds.height
        self.canDisplayBannerAds = true
        self.iAdBanner = self.appdelegate().iAdBanner
        //self.iAdBanner?.delegate = self
        self.iAdBanner?.frame = CGRectMake(0,screen_height-98, 0, 0)
        if let adb = self.iAdBanner{
            println("adding ad banner subview ")
            self.view.addSubview(adb)
        }else{
            println("WriteLineViewController iAdBanner is nil")
        }
        
        updateNavigationTitle()
        
        if (NetOpers.sharedInstance.user.is_logged_in()) {
            
            if (self.verse.is_loaded()) {
                if (NetOpers.sharedInstance.user.id==self.verse.owner_id) {
                    self.cancelButton.hidden = false
                }
            }
            
            updateSendPlaceholder()
            
            var refresh : Bool = false
            
            if (lastTabbed==nil) {
                refresh = true
            } else {
                var elapsedTime = NSDate().timeIntervalSinceDate(lastTabbed!)
                refresh = (elapsedTime>NSTimeInterval(10.0))
            }
            
            if (refresh) {
                
                var params = Dictionary<String,AnyObject>()
                
                params["verse_id"]=verseId
                params["user_id"]=NetOpers.sharedInstance.user.id
                
                println("hitting active-verse url")
                println(params)
                
                NetOpers.sharedInstance.post(NetOpers.sharedInstance.appserver_hostname! + "/u/active-verse", params: params, loadVerse)
                
                lastTabbed = NSDate()
            }
        
        }
        
        is_busy = false
    }
    
    
    override func viewWillDisappear(animated: Bool){
//        self.iAdBanner?.delegate = nil
        self.iAdBanner?.removeFromSuperview()
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
    
    @IBAction func decrementScore(sender: AnyObject) {
        score = 0;
    }
    
    @IBAction func incrementScore(sender: AnyObject) {
        score = 2;
    }
    
    private var verse : VerseRec = VerseRec()
    
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
                    
                    /*
                    var id : Int = -1
                    var next_index_user_ids : Int = -1
                    var owner_id : Int = -1
                    var lines : [String] = []
                    */
                    
                    if let id = results["id"] as? Int {
                        self.verse.id = id
                    }
                    
                    if let nid = results["next_index_user_ids"] as? Int {
                        self.verse.next_index_user_ids = nid
                    }
                    
                    if let oid = results["owner_id"] as? Int {
                        self.verse.owner_id = oid
                    }
                    
                    if let li = results["lines"] as? [String] {
                        self.verse.lines = li
                    }
                    
                    if let ic = results["is_complete"] as? Bool {
                        self.verse.is_complete = ic
                    }
                    
                    if let ui = results["user_ids"] as? [Int] {
                        self.verse.user_ids = ui
                    }
                    
                    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
                        dispatch_async(dispatch_get_main_queue(),{
                            
                            self.verseView.text = ""
                            
                            for l : String in self.verse.lines {
                                self.verseView.text = self.verseView.text + "\n" + l
                            }
                            
                            self.verseView.text = self.verseView.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
                            
                            if NetOpers.sharedInstance.user.is_logged_in() {
                                if (!self.verse.is_complete) {
                                    
                                    self.is_my_turn = find(self.verse.user_ids, NetOpers.sharedInstance.user.id)==self.verse.next_index_user_ids
                                    
                                    self.updateSendPlaceholder()
                                }
                                
                                if self.verse.owner_id==NetOpers.sharedInstance.user.id {
                                    self.cancelButton.hidden = false
                                }
                                
                            }
                            
                            self.updateNavigationTitle()
                            
                            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                            
                            self.is_busy = false
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
    
    var audioPlayer : AVAudioPlayer?
    
    func playButtonSound(){
        var error:NSError?
        
        if let path = NSBundle.mainBundle().pathForResource("Typing", ofType: "wav") {
            audioPlayer = AVAudioPlayer(contentsOfURL: NSURL(fileURLWithPath: path), fileTypeHint: "wav", error: &error)
            
            if let sound = audioPlayer {
                
                sound.prepareToPlay()
                
                sound.play()
                println("play sound")
            }
        }
        println(error)
    }
    
    func updateSendPlaceholder() {
        if (is_my_turn) {
            self.sendButton.hidden = false
            self.setLine.placeholder = "It's your turn!"
        } else {
            self.sendButton.hidden = true
            self.setLine.placeholder  = "Your turn is coming up soon!"
        }
    }

    @IBOutlet var sendButton: UIButton!
    @IBOutlet var scoreView: UIView!
    
    @IBOutlet var setLine: UITextField!
    
    var is_busy : Bool = false
    
    @IBAction func sendLine(sender: AnyObject) {
        
        if (!is_busy) {
            is_busy = true
            
            is_my_turn = false
            
            updateSendPlaceholder()
            
            println("Clicked send with score " + String(score) + " " +
                setLine.text)
            
            playButtonSound()
            
            var params = Dictionary<String,AnyObject>()
            params["topic_id"]=topic?.id
            params["line"]=setLine.text
            params["verse_id"]=verseId
            params["score_increment"]=score
            
            println("hitting saveline url")
            println(params)
            
            NetOpers.sharedInstance.post(NetOpers.sharedInstance.appserver_hostname! + "/u/save-line", params: params, loadVerse)
            
            self.setLine.text = ""
        }
        
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: - Ad Banner
    
    func appdelegate () -> AppDelegate{
        return UIApplication.sharedApplication().delegate as AppDelegate
    }
    
    func bannerViewWillLoadAd(banner: ADBannerView!) {
        println("bannerViewWillLoadAd called")
    }
    
    func bannerViewDidLoadAd(banner: ADBannerView!) {
        println("bannerViewDidLoadAd called")
        //UIView.beginAnimations(nil, context:nil)
        //UIView.setAnimationDuration(1)
        //self.iAdBanner?.alpha = 1
        self.iAdBanner?.hidden = false
        //UIView.commitAnimations()
        
    }
    
    func bannerViewActionDidFinish(banner: ADBannerView!) {
        println("bannerViewACtionDidFinish called")
    }
    
    func bannerViewActionShouldBegin(banner: ADBannerView!, willLeaveApplication willLeave: Bool) -> Bool{
        return true
    }
    
    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
        println("bannerView didFailToReceiveAdWithError called")
        self.iAdBanner?.hidden = true
    }
    
    func hide_adbanner(){
        self.iAdBanner?.hidden = true
    }
    
    func cancelVerse() {
        NetOpers.sharedInstance.get(NetOpers.sharedInstance.appserver_hostname! + "/v/cancel/id=\(self.verseId)",
            completion_handler:{
                data, response, error -> Void in
                
                let httpResponse = response as NSHTTPURLResponse
                if httpResponse.statusCode == 200 {
                    if data != nil {
                        
                        let jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(
                            data!, options: NSJSONReadingOptions.MutableContainers,
                            error: nil) as NSDictionary
                        
                        // this should be the verse that we just deleted
                        println(jsonResult)
                        
                        dispatch_async(dispatch_get_main_queue(),{
                            
                            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                            
                            self.navigationController?.popViewControllerAnimated(true)
                        })
                        
                    }
                }else{
                    println("Error")
                    println(error)
                }
                
        })
    }
    
    
    @IBAction func onCancel(sender: AnyObject) {
        println("onCancel called")
        
        let cancelController = UIAlertController(title: "Cancel Verse", message: "Do you want to cancel this verse?", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        let noAction = UIAlertAction(title: "No", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            // do nothing
        })
        let yesAction = UIAlertAction(title: "Yes", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.cancelVerse()
        })
        
        cancelController.addAction(noAction)
        cancelController.addAction(yesAction)
        
        self.presentViewController(cancelController, animated: true, completion: nil)
        
    }
    
}








