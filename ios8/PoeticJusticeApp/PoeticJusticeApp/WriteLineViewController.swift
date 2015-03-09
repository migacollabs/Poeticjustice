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

class UIVerticalAlignLabel: UILabel {
    enum VerticalAlignment : Int {
        case VerticalAlignmentTop = 0
        case VerticalAlignmentMiddle = 1
        case VerticalAlignmentBottom = 2
    }
    
    var verticalAlignment : VerticalAlignment = .VerticalAlignmentTop {
        didSet {
            setNeedsDisplay()
        }
    }
    
    required init(coder aDecoder: NSCoder){
        super.init(coder: aDecoder)
    }
    
    override func textRectForBounds(bounds: CGRect, limitedToNumberOfLines: Int) -> CGRect {
        let rect = super.textRectForBounds(bounds, limitedToNumberOfLines: limitedToNumberOfLines)
        
        switch(verticalAlignment) {
        case .VerticalAlignmentTop:
            return CGRectMake(bounds.origin.x, bounds.origin.y, rect.size.width, rect.size.height)
        case .VerticalAlignmentMiddle:
            return CGRectMake(bounds.origin.x, bounds.origin.y + (bounds.size.height - rect.size.height) / 2, rect.size.width, rect.size.height)
        case .VerticalAlignmentBottom:
            return CGRectMake(bounds.origin.x, bounds.origin.y + (bounds.size.height - rect.size.height), rect.size.width, rect.size.height)
        default:
            return bounds
        }
    }
    
    override func drawTextInRect(rect: CGRect) {
        let r = self.textRectForBounds(rect, limitedToNumberOfLines: self.numberOfLines)
        super.drawTextInRect(r)
    }
}

struct VerseRec {
    var id : Int = -1
    var next_index_user_ids : Int = -1
    var owner_id : Int = -1
    var lines : [String] = []
    var is_complete : Bool = false
    var user_ids : [Int] = []
    var has_all_lines: Bool = false
    var verse_title : String = ""
    
    // int is user id
    var players = Dictionary<Int,PlayerRec >()
    
    func is_loaded() -> Bool {
        return id>0
    }
}

class WriteLineViewController: UIViewController, UITextViewDelegate {
    
    @IBOutlet weak var topicLabel: UILabel!
    @IBOutlet weak var topicButton: UIButton!
    
    var maxNumPlayers : Int = 2
    
    @IBOutlet weak var player1Avatar: UIImageView!
    @IBOutlet weak var player2Avatar: UIImageView!
    @IBOutlet weak var player3Avatar: UIImageView!
    @IBOutlet weak var player4Avatar: UIImageView!
    @IBOutlet weak var player5Avatar: UIImageView!
    
    private var textViewBlock : UIView = UIView()
    
    
    @IBOutlet var cancelButton: UIButton!
    // var iAdBanner: ADBannerView?
    
    @IBOutlet var verseView: UILabel!
    
    var line : String = "";
    var verseId : Int = 0;
    var should_begin_banner = false
    
    var topic: Topic?{
        didSet{
            self.configureView()
        }
    }
    
    var is_my_turn : Bool = false
    
    let tapRec = UITapGestureRecognizer()
    
    // for now, this is just to help clean up nav once this view is reached
    var newVerseViewController : NewVerseViewController?
    var worldVerseViewController : WorldVerseViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var refreshButton : UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Refresh, target: self, action: "refresh")
        self.navigationItem.rightBarButtonItem = refreshButton
        
        self.sendButton.hidden = true
        
        self.canDisplayBannerAds = true
        
        verseView.text = ""
        
        self.setPlaceholderText("Your turn is coming up soon!")
        
        self.setLine.delegate = self
        
        tapRec.addTarget(self, action: "tappedView")
        self.verseView.addGestureRecognizer(tapRec)
//        self.view.addGestureRecognizer(tapRec)
        
        self.configureView()
        
    }
    
    func setPlaceholderText(text : String) {
        self.setLine.text = text;
        self.setLine.textColor = UIColor.lightGrayColor()
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        if textView.textColor == UIColor.lightGrayColor() {
            textView.text = nil
            textView.textColor = UIColor.blackColor()
        }
    }
    
    func textFieldShouldReturn(textView: UITextView!) -> Bool {
        self.view.endEditing(true);
        return false;
    }
    
    func refresh() {
        if (!is_busy) {
            is_busy = true
            
            // remove the existing blocking view
            self.textViewBlock.removeFromSuperview()
            
            // blocking view gets added back
            viewWillAppear(true)
            
            if (self.is_my_turn) {
                // remove it if it's my turn, otherwise leave it
                self.textViewBlock.removeFromSuperview()
            }
        }
    }
    
    func updateNavigationTitle() {
        if let t = topic {
            if let ti = t.name as? String {
                title = ti
            }
        }
    }
    
    var lastTabbed : NSDate?
    
    override func viewWillAppear(animated: Bool) {
        
        textViewBlock = UIView()
        textViewBlock.frame = self.setLine.frame
        textViewBlock.center = self.setLine.center
        textViewBlock.backgroundColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.0)
        
        self.view.addSubview(textViewBlock)
        
//        var screen_height = UIScreen.mainScreen().bounds.height
//        self.canDisplayBannerAds = true
//        self.iAdBanner = self.appdelegate().iAdBanner
//        //self.iAdBanner?.delegate = self
//        self.iAdBanner?.frame = CGRectMake(0,screen_height-98, 0, 0)
//        if let adb = self.iAdBanner{
//            // println("adding ad banner subview ")
//            // self.view.addSubview(adb)
//            
//        }else{
//            // println("WriteLineViewController iAdBanner is nil")
//        }
        
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
                
                // println("hitting active-verse url")
                // println(params)
                
                NetOpers.sharedInstance.post(NetOpers.sharedInstance.appserver_hostname! + "/u/active-verse", params: params, loadVerse)
                
                lastTabbed = NSDate()
            }
        
        }
        
        is_busy = false
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        
        super.touchesBegan(touches, withEvent: event)
        
        var touch : UITouch = touches.anyObject() as UITouch
        
        var userCount : Int = countElements(self.verse.user_ids)
        
        var showAlert : Bool = false
        
        // two player minimum, these always show
        if (touch.view == player1Avatar ||
            touch.view == player2Avatar) {
            showAlert = true
        }
        
        // these may not be visible, but are still clickable
        if (touch.view == player3Avatar && userCount>2) {
            showAlert = true
        }
        
        if (touch.view == player4Avatar && userCount>3) {
            showAlert = true
        }
        
        if (touch.view == player5Avatar && userCount>4) {
            showAlert = true
        }
        
        if (showAlert) {
            self.show_alert("Player Info", message: "You'll need to finish the verse to see this player's info.", controller_title:"Ok")
        }
    
    }
    
    
    override func viewWillDisappear(animated: Bool){
//        self.iAdBanner?.delegate = nil
        // self.iAdBanner?.removeFromSuperview()
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
    
    private var verse : VerseRec = VerseRec()
    
    func loadVerse(data: NSData?, response: NSURLResponse?, error: NSError?) {
        if let httpResponse = response as? NSHTTPURLResponse {
            if httpResponse.statusCode == 200 {
                if data != nil {
                    
                    // println("loading data...")
                    
                    let jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(
                        data!, options: NSJSONReadingOptions.MutableContainers,
                        error: nil) as NSDictionary
                    
                    if let results = jsonResult["results"] as? NSDictionary {
                        
                        // println(results)
                        
                        /*
                        var id : Int = -1
                        var next_index_user_ids : Int = -1
                        var owner_id : Int = -1
                        var lines : [String] = []
                        */
                        
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
                        
                        if let t = results["title"] as? String {
                            self.verse.verse_title = t
                        }
                        
                        if let ui = results["user_ids"] as? [Int] {
                            self.verse.user_ids = ui
                        }
                        
                        if let playersArray = results["user_data"] as? NSArray{
                            for player in playersArray as NSArray{
                                
                                // println(player)
                                
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
                            // println("corrupt user_data")
                        }
                        
                        
                        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
                            dispatch_async(dispatch_get_main_queue(),{
                                
                                // setting this here because it looks like the paragraph
                                // stuff below messes with the label properties
                                var fontSizeMap : Dictionary<Int, CGFloat> = Dictionary<Int, CGFloat>()
                                fontSizeMap[0]=14
                                fontSizeMap[1]=15
                                fontSizeMap[2]=15
                                fontSizeMap[3]=15
                                
                                let screenSize: CGRect = UIScreen.mainScreen().bounds
                                
                                println("Screen height: \(screenSize.height)")
                                
                                if (screenSize.height>600) { // 568 iphone 5s, 667 iphone6
                                    fontSizeMap[4]=15
                                    fontSizeMap[5]=15
                                    fontSizeMap[6]=15
                                } else {
                                    fontSizeMap[4]=13
                                    fontSizeMap[5]=12
                                    fontSizeMap[6]=12
                                }
                                
                                let fontSize : CGFloat = fontSizeMap[self.verse.user_ids.count]!
                                
                                let font : UIFont = UIFont(name: "Helvetica Neue", size: fontSize)!
                                
                                var texts : NSMutableAttributedString = NSMutableAttributedString(string: "")
                                
                                var lineNum : Int = 0
                                for i in 0...((self.verse.user_ids.count*4)-1) {
                                    
                                    lineNum = i + 1
                                    
                                    if (i < self.verse.lines.count) {
                                        
                                        var line = NSMutableAttributedString(string:"\(lineNum). " + self.verse.lines[i] + "\n")
                                    
                                        line.addAttribute(NSFontAttributeName, value: font, range: NSRange(location: 0, length: line.length))
                                        
                                        line.addAttribute(NSForegroundColorAttributeName, value: UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.30), range: NSRange(location: 0, length: countElements(String(lineNum))+1))
                                        
                                        let paraStyle = NSMutableParagraphStyle()
                                        paraStyle.headIndent = 20.0
                                        
                                        line.addAttribute(NSParagraphStyleAttributeName, value: paraStyle, range: NSRange(location: 0, length: line.length))
                                        
                                        texts.appendAttributedString(line)
                                    } else {
                                        
                                        var line = NSMutableAttributedString(string:"\(lineNum).\n")
                                        
                                        line.addAttribute(NSFontAttributeName, value: font, range: NSRange(location: 0, length: line.length))
                                        
                                        line.addAttribute(NSForegroundColorAttributeName, value: UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.30), range: NSRange(location: 0, length: countElements(String(lineNum))+1))
                                        
                                        texts.appendAttributedString(line)
                                        
                                    }
                                }
                                
                                self.verseView.attributedText = texts
                                
                                
                                if NetOpers.sharedInstance.user.is_logged_in() {
                                    if (!self.verse.is_complete) {
                                        
                                        self.is_my_turn = find(self.verse.user_ids, NetOpers.sharedInstance.user.id)==self.verse.next_index_user_ids
                                        
                                        if (self.is_my_turn) {
                                            self.textViewBlock.removeFromSuperview()
                                        }
                                        
                                        self.updateSendPlaceholder()
                                    }
                                    
                                    self.updateCancelButton()
                                    
                                }
                                
                                self.updateNavigationTitle()
                                
                                var i = 0
                                for user_id in self.verse.user_ids {
                                
                                    switch i{
                                    case 0:
                                        self.player1Avatar.image = self.getPlayerAvatarImageName(user_id)
                                    case 1:
                                        self.player2Avatar.image = self.getPlayerAvatarImageName(user_id)
                                    case 2:
                                        self.player3Avatar.image = self.getPlayerAvatarImageName(user_id)
                                    case 3:
                                        self.player4Avatar.image = self.getPlayerAvatarImageName(user_id)
                                    case 4:
                                        self.player5Avatar.image = self.getPlayerAvatarImageName(user_id)
                                    default:
                                        ()
                                    }
                                    
                                    i++
                                }
                                
                                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                                
                                self.is_busy = false
                            })
                        })
                    } else {
                        // println("unable to get results")
                    }
                    
                }
            } else {
                self.show_alert("\(httpResponse.statusCode) Oops", message: "There was a problem loading the verse.  Please try again.", controller_title:"Ok")
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            }
        }
        
        if (error != nil) {
            if let e = error?.localizedDescription {
                self.show_alert("Unable to load verse", message: e, controller_title:"Ok")
            } else {
                self.show_alert("Network error", message: "Unable to load verse", controller_title:"Ok")
            }
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
        
    }
    
    func getPlayerAvatarImageName(userId : Int) -> UIImage {
        if let pr = self.verse.players[userId]{
            return UIImage(named: pr.avatar_name)!
        }
        return UIImage(named: "avatar_default.png")!
    }
    
    var audioPlayer : AVAudioPlayer?
    
    func playButtonSound(){
        var error:NSError?
        
        if let path = NSBundle.mainBundle().pathForResource("Pencil", ofType: "wav") {
            audioPlayer = AVAudioPlayer(contentsOfURL: NSURL(fileURLWithPath: path), fileTypeHint: "wav", error: &error)
            
            if let sound = audioPlayer {
                
                sound.prepareToPlay()
                
                sound.play()
                // println("play sound")
            }
        }
        // println(error)
    }
    
    func getCountTurnsLeft() -> Int {
        if let playerPos : Int = find(self.verse.user_ids, NetOpers.sharedInstance.user.id) {
            if (playerPos > self.verse.next_index_user_ids) {
                return playerPos - self.verse.next_index_user_ids
            } else if (playerPos < self.verse.next_index_user_ids) {
                return (self.verse.user_ids.count) - self.verse.next_index_user_ids + playerPos
            }
        }
        return 0
    }
    
    func updateSendPlaceholder() {
        if (is_my_turn) {
            // self.setLine.enabled = true
            self.sendButton.hidden = false
            self.setPlaceholderText("It's your turn!")
        } else {
            self.sendButton.hidden = true
            // self.setLine.enabled = false
            if (NetOpers.sharedInstance.user.is_logged_in()) {
                var turnsLeft : Int = self.getCountTurnsLeft()
                if (turnsLeft==1) {
                    self.setPlaceholderText("You're up in \(turnsLeft) turn!")
                } else {
                    self.setPlaceholderText("You're up in \(turnsLeft) turns!")
                }
            } else {
                self.setPlaceholderText("Your turn is coming up soon!")
            }
        }
    }

    @IBOutlet var sendButton: UIButton!
    
    @IBOutlet var setLine: UITextView!
    
    var is_busy : Bool = false
    
    @IBAction func sendLine(sender: AnyObject) {
        
        if (!is_busy) {
            is_busy = true
            
            self.setLine.resignFirstResponder()
            
            animateButtonTapped();
            
            is_my_turn = false
            
            // println("Clicked send " + setLine.text)
            
            playButtonSound()
            
            var params = Dictionary<String,AnyObject>()
            params["topic_id"]=topic?.id
            params["line"]=setLine.text
            params["verse_id"]=verseId
            
            // println("hitting saveline url")
            // println(params)
            
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
            controller.topic = self.topic
            var viewControllers: [UIViewController] = self.navigationController!.viewControllers as [UIViewController]
            
            viewControllers.removeAtIndex(viewControllers.count-1)
            viewControllers.append(controller)
            
            self.navigationController?.viewControllers = viewControllers
            
        })
    }
    
    // MARK: - Ad Banner
    
    func appdelegate () -> AppDelegate{
        return UIApplication.sharedApplication().delegate as AppDelegate
    }
    
//    func bannerViewWillLoadAd(banner: ADBannerView!) {
//        // println("bannerViewWillLoadAd called")
//    }
    
//    func bannerViewDidLoadAd(banner: ADBannerView!) {
//        // println("bannerViewDidLoadAd called")
//        //UIView.beginAnimations(nil, context:nil)
//        //UIView.setAnimationDuration(1)
//        //self.iAdBanner?.alpha = 1
//        // self.iAdBanner?.hidden = false
//        //UIView.commitAnimations()
//        
//    }
    
//    func bannerViewActionDidFinish(banner: ADBannerView!) {
//        // println("bannerViewACtionDidFinish called")
//    }
    
//    func bannerViewActionShouldBegin(banner: ADBannerView!, willLeaveApplication willLeave: Bool) -> Bool{
//        return true
//    }
    
//    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
//        // println("bannerView didFailToReceiveAdWithError called")
//        self.iAdBanner?.hidden = true
//    }
//    
//    func hide_adbanner(){
//        self.iAdBanner?.hidden = true
//    }
    
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
    
    
    func leaveVerse() {
        var params = Dictionary<String,AnyObject>()
        params["verse_id"]=self.verseId
        
        NetOpers.sharedInstance.post(NetOpers.sharedInstance.appserver_hostname! + "/u/leave", params: params,
            completion_handler:{
                data, response, error -> Void in
                
                if let httpResponse = response as? NSHTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        if data != nil {
                            
                            let jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(
                                data!, options: NSJSONReadingOptions.MutableContainers,
                                error: nil) as NSDictionary
                            
                            // this should be the verse that we just left
                            // println(jsonResult)
                            
                            dispatch_async(dispatch_get_main_queue(),{
                                
                                // println("leaving verse")
                                
                                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                                
                                self.navigationController?.popViewControllerAnimated(true)
                            })
                            
                        }
                    }else{
                        self.show_alert("\(httpResponse.statusCode) Oops", message: "There was a problem leaving the verse.  Please try again.", controller_title:"Ok")
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
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
                            // println(jsonResult)
                            
                            dispatch_async(dispatch_get_main_queue(),{
                                
                                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                                
                                self.navigationController?.popViewControllerAnimated(true)
                            })
                            
                        }
                    }else{
                        self.show_alert("\(httpResponse.statusCode) Oops", message: "There was a problem canceling the verse.  Please try again.", controller_title:"Ok")
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
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
        // println("onCancel/leave called")
        if self.verse.owner_id==NetOpers.sharedInstance.user.id {
            cancel()
        } else {
            leave()
        }
    }
    
    
    @IBAction func showVerseInfo(sender: AnyObject) {
        // TODO: parse HTML link and provide another controller title button to "Open in Safari" in addition to "Ok"
        show_verse_title("Verse Title",
            message: self.verse.verse_title,
            controller_title: "Ok")
    }
    
    func textView(textView: UITextView,
        shouldChangeTextInRange range: NSRange,
        replacementText text: String) -> Bool {
            
        if (is_my_turn) {
            let newLength = countElements(textView.text!) + countElements(text) - range.length
            return newLength <= 65
        }
        
        // disable keyboard?
        return false
    }
    
    func animateButtonTapped() {
        
        let screenSize: CGRect = UIScreen.mainScreen().bounds
        
        for i in 0...3 {
            
            let leaf = UIImageView(image: UIImage(named: "leaf-button.png"))
            leaf.frame = CGRect(x: 0, y: 0, width: 24, height: 12)
            self.view.addSubview(leaf)
            
            let path = UIBezierPath()
            
            // start here
            let offset = CGFloat(5 + i)
            path.moveToPoint(CGPoint(x: self.sendButton.frame.origin.x + offset, y: self.sendButton.frame.origin.y + 5))
            
            let randomYOffset = CGFloat( arc4random_uniform(UInt32(screenSize.height * 0.27)))
            let randomXOffset = CGFloat( arc4random_uniform(UInt32(screenSize.width * 0.27)))
            
            // add some curves points from top right to bottom left
            path.addCurveToPoint(
                CGPoint(x: 0, y: screenSize.height),
                controlPoint1: CGPoint(x: screenSize.width * 0.5 - randomXOffset, y: screenSize.height * 0.5 - randomYOffset),
                controlPoint2: CGPoint(x: screenSize.width * 0.5 + randomXOffset, y: screenSize.height * 0.5 + randomYOffset))
            
            // create the animation
            let anim = CAKeyframeAnimation(keyPath: "position")
            anim.path = path.CGPath
            anim.rotationMode = kCAAnimationRotateAuto
            
            // allow enough time for the leaves to fall about half way down
            // the view
            anim.duration = 6 + Double(arc4random_uniform(10))
            
            // add the animation 
            leaf.layer.addAnimation(anim, forKey: "animate position along path")
            
            // fade out the leaves after awhile
            UIView.animateWithDuration(4.5, animations: {
                leaf.alpha = 0.0
            })
            
            // the leaves are spinning
            let duration = NSTimeInterval(5 + i)
            let delay = 0.0
            let options = UIViewKeyframeAnimationOptions.CalculationModePaced
            let fullRotation = CGFloat(M_PI * 2)
            
            UIView.animateKeyframesWithDuration(duration, delay: delay, options: options, animations: {
                
                // note that we've set relativeStartTime and relativeDuration to zero.
                // Because we're using `CalculationModePaced` these values are ignored
                // and iOS figures out values that are needed to create a smooth constant transition
                UIView.addKeyframeWithRelativeStartTime(0, relativeDuration: 0, animations: {
                    leaf.transform = CGAffineTransformMakeRotation(1/3 * fullRotation)
                })
                
                UIView.addKeyframeWithRelativeStartTime(0, relativeDuration: 0, animations: {
                    leaf.transform = CGAffineTransformMakeRotation(2/3 * fullRotation)
                })
                
                UIView.addKeyframeWithRelativeStartTime(0, relativeDuration: 0, animations: {
                    leaf.transform = CGAffineTransformMakeRotation(3/3 * fullRotation)
                })
                
                }, completion: {(Bool) in
                    leaf.removeFromSuperview() // free up resources
                    return
            })
            
        }
    }
    
    func show_verse_title(title:String, message:String, controller_title:String){
        dispatch_async(dispatch_get_main_queue()) {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: controller_title, style: UIAlertActionStyle.Default, handler: nil))
            
            if let url = NSURL(string:self.verse.verse_title) {
                
                let open: ((UIAlertAction!) -> Void)! = { action in
                    UIApplication.sharedApplication().openURL(url)
                    return
                }
                
                alertController.addAction(UIAlertAction(title: "Open in Safari", style: UIAlertActionStyle.Default, handler: open ))
            
            }
            
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    func show_alert(title:String, message:String, controller_title:String){
        dispatch_async(dispatch_get_main_queue()) {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: controller_title, style: UIAlertActionStyle.Default,handler: nil))
            
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    // MARK: - gestures
    
    func tappedView(){
        self.setLine.resignFirstResponder()
    }
    
}








