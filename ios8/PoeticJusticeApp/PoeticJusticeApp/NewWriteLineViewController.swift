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



struct VerseWriteLineScreenRec{
    var id = -1
    var title = ""
    var owner_id = -1
    var user_ids:[Int] = []
    //var participantCount = -1
    var is_complete : Bool = false
    
    // TODO: Refactor
    var next_index_user_ids : Int = -1
    var lines : [String] = []
    
    // int is pk and position
    var lines_recs = Dictionary<Int,PlayerLineRec>()
    
    // int is user id
    var players = Dictionary<Int,PlayerRec >()
    
    // int is user_id and val is line position
    var votes = Dictionary<Int,Int>()
    
    func is_loaded() -> Bool {
        return id>0
    }
    func particiantCount() -> Int{
        return user_ids.count
    }
}


class NewWriteLineViewController:
    UIViewController, ADBannerViewDelegate, UITextFieldDelegate, UITableViewDelegate{
    
    @IBOutlet weak var topicLabel: UILabel!
    @IBOutlet weak var topicButton: UIButton!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var verseView: UITextView?
    @IBOutlet var sendButton: UIButton!
    @IBOutlet var setLine: UITextField!
    @IBOutlet weak var playerLineTableView: UITableView!
    
    private var verse = VerseWriteLineScreenRec()
    var verseLinesForTable:[PlayerLineRec] = []
    
    var line : String = "";
    var verseId : Int = 0;
    var should_begin_banner = false
    var maxNumPlayers : Int = 2
    var is_my_turn : Bool = false
    var lastTabbed : NSDate?
    var is_busy : Bool = false
    
    var topic: Topic?{
        didSet{
            self.configureView()
        }
    }
    
    var iAdBanner: ADBannerView?
    var audioPlayer : AVAudioPlayer?
    // for now, this is just to help clean up nav once this view is reached
    var newVerseViewController : NewVerseViewController?
    var worldVerseViewController : WorldVerseViewController?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // register our custom cell
        self.playerLineTableView.registerNib(UINib(nibName: "PlayerLineTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
        
        var refreshButton : UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Refresh, target: self, action: "refresh")
        self.navigationItem.rightBarButtonItem = refreshButton
        
        self.sendButton.hidden = true
        
        setLine.text = ""
        
        title = "Your Line"
        
        self.setLine.placeholder  = "Your turn is coming up soon!"
        
        self.setLine.delegate = self
        
        self.configureView()
        
    }
    
    
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        println("textFieldShouldReturn")
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
    
    
    override func viewWillAppear(animated: Bool) {
        
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
        
        self.cancelButton.hidden = true
        
        if (NetOpers.sharedInstance.user.is_logged_in()) {
            
            updateCancelButton()
            
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
    
    func updateCancelButton() {
        if (self.verse.is_loaded()) {
            self.cancelButton.hidden = false
            if (NetOpers.sharedInstance.user.id==self.verse.owner_id) {
                self.cancelButton.setTitle(" Cancel", forState: UIControlState.Normal)
            } else {
                self.cancelButton.setTitle(" Leave", forState: UIControlState.Normal)
            }
        } else {
            self.cancelButton.hidden = true
        }
    }
    
    
    func loadVerse(data: NSData?, response: NSURLResponse?, error: NSError?) {
        if let httpResponse = response as? NSHTTPURLResponse {
            if httpResponse.statusCode == 200 {
                if data != nil {
                    
                    println("loading data...")
                    
                    let jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(
                        data!, options: NSJSONReadingOptions.MutableContainers,
                        error: nil) as NSDictionary
                    
                    if let results = jsonResult["results"] as? NSDictionary {
                        
                        println(results)
                        
                        if let id = results["verse_id"] as? Int {
                            self.verse.id = id
                        }
                        
                        if let hal = results["has_all_lines"] as? Bool {
                            if hal && self.verse.id > 0{
                                if let t = self.topic{
                                    self.dispatch_resultsscreen_controller(self.verse.id, topic: t)
                                    return // bail out
                                }
                            }
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
                        
                        
                        if let linesDict = results["lines_d"] as? NSDictionary{
                            
                            for (line_position, line_tuple) in linesDict{
                                
                                // json dict key is str, change to int
                                var p:Int? = (line_position as? String)!.toInt()
                                
                                if let lp = p{
                                    var vlr = PlayerLineRec(
                                        position:p!, text:line_tuple[1] as String, player_id:line_tuple[0] as Int)
                                    
                                    verse.lines_recs[p!] = vlr
                                    
                                }else{
                                    println("corrupt line pk")
                                }
                                
                            }
                        }else{
                            println("corrupt lines data")
                        }
                        
                        if let playersArray = results["user_data"] as? NSArray{
                            for player in playersArray as NSArray{
                                
                                println(player)
                                
                                var pid = player[0] as Int
                                var usrnm = player[1] as String
                                
                                var avnStr:String? = player[2] as? String
                                if avnStr == nil{
                                    avnStr = ""
                                }
                                
                                if !avnStr!.isEmpty{
                                    let upData = (avnStr! as NSString).dataUsingEncoding(NSUTF8StringEncoding)
                                    let userPrefs: NSDictionary = NSJSONSerialization.JSONObjectWithData(
                                        upData!, options: NSJSONReadingOptions.MutableContainers,
                                        error: nil) as NSDictionary
                                    avnStr = userPrefs["avatar_name"] as? String
                                }else{
                                    avnStr = "avatar_default.png"
                                }
                                
                                verse.players[pid] = PlayerRec(
                                    user_id: pid, user_name: usrnm, avatar_name:avnStr!)
                                
                            }
                            
                        }else{
                            println("corrupt user_data")
                        }
                        
                        
                        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
                            dispatch_async(dispatch_get_main_queue(),{
                                
                                println(self.verse.lines_recs)
                                println(self.verse.players)
                                
                                
                                if NetOpers.sharedInstance.user.is_logged_in() {
                                    if (!self.verse.is_complete) {
                                        
                                        self.is_my_turn = find(self.verse.user_ids, NetOpers.sharedInstance.user.id)==self.verse.next_index_user_ids
                                        
                                        self.updateSendPlaceholder()
                                    }
                                    
                                    self.updateCancelButton()
                                    
                                }
                                
                                self.updateNavigationTitle()
                                
                                // sort asc because lines have pks that asc
                                let sortedLinePos = Array(self.verse.lines_recs.keys).sorted(<)
                                
                                for linePos in sortedLinePos{
                                    println("appending line")
                                    self.verseLinesForTable.append(self.verse.lines_recs[linePos]!)
                                }
                                
                                println(self.verseLinesForTable)
                                
                                
                                self.playerLineTableView.reloadData()
                                
                                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                                
                                self.is_busy = false
                            })
                        })
                    } else {
                        println("unable to get results")
                    }
                    
                }
            }
        }
        
        if (error != nil) {
            if let e = error?.localizedDescription {
                self.show_alert("Unable to start new verse", message: e, controller_title:"Ok")
            } else {
                self.show_alert("Network error", message: "Unable to start new verse", controller_title:"Ok")
            }
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
    }
    
    
    func playButtonSound(){
        var error:NSError?
        
        if let path = NSBundle.mainBundle().pathForResource("Pencil", ofType: "wav") {
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
    
    
    @IBAction func sendLine(sender: AnyObject) {
        
        if (!is_busy) {
            is_busy = true
            
            is_my_turn = false
            
            updateSendPlaceholder()
            
            println("Clicked send " + setLine.text)
            
            playButtonSound()
            
            var params = Dictionary<String,AnyObject>()
            params["topic_id"]=topic?.id
            params["line"]=setLine.text
            params["verse_id"]=verseId
            
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
    
    func dispatch_resultsscreen_controller(verseId:Int, topic:Topic){
        dispatch_async(dispatch_get_main_queue(), {
            
            var sb = UIStoryboard(name: "VerseResultsScreenStoryboard", bundle: nil)
            var controller = sb.instantiateViewControllerWithIdentifier("VerseResultsScreenViewController") as VerseResultsScreenViewController
            controller.verseId = verseId
            self.navigationController?.pushViewController(controller, animated: true)
            
        })
    }
    
    
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
    
    func leaveVerse() {
        var params = Dictionary<String,AnyObject>()
        params["verse_id"]=verseId
        
        NetOpers.sharedInstance.post(NetOpers.sharedInstance.appserver_hostname! + "/v/leave", params: params,
            completion_handler:{
                data, response, error -> Void in
                
                if let httpResponse = response as? NSHTTPURLResponse {
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
                        println(error)
                    }
                }
                
                if (error != nil) {
                    if let e = error?.localizedDescription {
                        self.show_alert("Unable to leave verse", message: e, controller_title:"Ok")
                    } else {
                        self.show_alert("Network error", message: "Unable to leave verse", controller_title:"Ok")
                    }
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                }
                
        })

    }
    
    func cancelVerse() {
        NetOpers.sharedInstance.get(NetOpers.sharedInstance.appserver_hostname! + "/v/cancel/id=\(self.verseId)",
            completion_handler:{
                data, response, error -> Void in
                
                if let httpResponse = response as? NSHTTPURLResponse {
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
                        println(error)
                    }
                }
                
                if (error != nil) {
                    if let e = error?.localizedDescription {
                        self.show_alert("Unable to cancel verse", message: e, controller_title:"Ok")
                    } else {
                        self.show_alert("Network error", message: "Unable to cancel verse", controller_title:"Ok")
                    }
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                }
        })
    }
    
    func cancel() {
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
    
    func leave() {
        let cancelController = UIAlertController(title: "Leave Verse", message: "Do you want to leave this verse?", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        let noAction = UIAlertAction(title: "No", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            // do nothing
        })
        let yesAction = UIAlertAction(title: "Yes", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.leaveVerse()
        })
        
        cancelController.addAction(noAction)
        cancelController.addAction(yesAction)
        
        self.presentViewController(cancelController, animated: true, completion: nil)
    }
    
    // cancel if the owner, leave if a participant
    @IBAction func onCancel(sender: AnyObject) {
        println("onCancel/leave called")
        if self.verse.owner_id==NetOpers.sharedInstance.user.id {
            cancel()
        } else {
            leave()
        }
    }
    
    // MARK: - TableView Delegate
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        return 100.0
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        println("numOfRowsinSection called")
        return self.verseLinesForTable.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell
        println("DEQUEUED \(cell)")
        if let pc = cell as? PlayerLineTableViewCell{
            
            // get the line
            var vlr = verseLinesForTable[indexPath.row]
            
            // get the player record so we can
            // set the avatar and userName
            var playerRec = self.verse.players[vlr.player_id]
            
            
            pc.avatarImage.image = UIImage(named: playerRec!.avatar_name)
            pc.userName.text = playerRec!.user_name
            
            // set the line text
            pc.verseLine.text = vlr.text
            
            
        }
        return cell
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            //            PropertyStore.sharedInstance.removePropertyAtIndex(indexPath.row)
            //            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
    
    func show_alert(title:String, message:String, controller_title:String){
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: controller_title, style: UIAlertActionStyle.Default,handler: nil))
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
}








