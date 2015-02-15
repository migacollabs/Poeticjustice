//
//  TopicsViewController.swift
//  PoeticJusticeApp
//
//  Created by Mat Mathews on 1/17/15.
//  Copyright (c) 2015 Miga Collabs. All rights reserved.
//

import Foundation
import UIKit
import iAd
import AVFoundation

@IBDesignable
class TopicButton : UIButton {
    @IBInspectable var index: Int = 0
}

@IBDesignable
class TopicLabel : UILabel {
    @IBInspectable var index: Int = 0
}

struct ActiveTopicRec {
    var topic_id : Int = -1
    var src : String = ""
    var verse_id : Int = -1
    var next_index_user_ids : Int = -1
    var verse_user_ids : [Int] = []
    var email_address : String = ""
    var user_name : String = ""
    var verse_title : String = ""
    var owner_id : Int = -1
    var current_user_has_voted : Bool = false
    
    func getTopicStateImageName() -> String {
        
        println("ActiveTopicRec.getTopicStateImageName \(current_user_has_voted)")
        
        if (self.src=="mine") {
            if (self.current_user_has_voted) {
                return "mine_complete.png"
            }
            return "mine.png"
        } else if (self.src=="joined_friend") {
            if (self.current_user_has_voted) {
                return "friend_complete.png"
            }
            return "friend.png"
        } else if (self.src=="joined_world") {
            if (self.current_user_has_voted) {
                return "world_complete.png"
            }
            return "world.png"
        } else if (self.src=="friend") {
            if (self.current_user_has_voted) {
                return "friend_complete.png"
            }
            return "friend.png"
        } else if (self.src=="world") {
            if (self.current_user_has_voted) {
                return "world_complete.png"
            }
            return "world.png"
        }
        // TODO: shouldn't happen but just in case, see
        // what this does
        return "Init.png"
    }
}

class ActiveTopic {
    
    var activeTopicRec : ActiveTopicRec = ActiveTopicRec() {
        didSet{
            refreshed = true
        }
    }
    
    private var topicButton : TopicButton?  // sort of a permanent button
    private var topicStateImage : UIImageView? // transient
    private var topicLabel : TopicLabel? // permanent, text transient
    private var buttonIndex : Int = -1 // permanent
    private var refreshed : Bool = false // used to diff active topics
    
    private var topicStateAnimDuration : NSTimeInterval = 4.0
    
    init(activeTopicRec : ActiveTopicRec, topicButton : TopicButton, topicStateImage : UIImageView, topicLabel : TopicLabel, buttonIndex : Int) {
        self.activeTopicRec = activeTopicRec
        self.topicButton = topicButton
        self.topicStateImage = topicStateImage
        self.topicLabel = topicLabel
        self.buttonIndex = buttonIndex
        
        self.refreshed = true
    }
    
    func setStale() {
        refreshed = false
    }
    
    func isStale() -> Bool {
        return refreshed==false
    }
    
    func unload() {
        // unload resources before remove this instance
        // from a list
        self.topicStateImage?.removeFromSuperview()
        self.topicStateImage = nil
        self.topicLabel?.text = ""
    }
    
    func getCountTurnsLeft() -> Int {
        if let playerPos : Int = find(activeTopicRec.verse_user_ids, NetOpers.sharedInstance.user.id) {
            println("playerPos \(playerPos) in verse_user_ids \(activeTopicRec.verse_user_ids) next_index \(activeTopicRec.next_index_user_ids)")
            if (playerPos > activeTopicRec.next_index_user_ids) {
                return playerPos - activeTopicRec.next_index_user_ids
            } else if (playerPos < activeTopicRec.next_index_user_ids) {
                return (activeTopicRec.verse_user_ids.count) - activeTopicRec.next_index_user_ids + playerPos
            }
        }
        return 0
    }
    
    func refresh() {
        if (self.isUserParticipating()) {
            // joined a topic, so animate
            
            self.topicLabel?.text = ""
            
            let counts : Int = self.getCountTurnsLeft()
            
            println("refresh active topic_id \(activeTopicRec.topic_id) counts \(counts)")
            
            topicStateAnimDuration = NSTimeInterval(counts) * 1.5
            
            if topicStateAnimDuration==0 {
                topicStateAnimDuration = 1.0
            }
            
        } else {
            // otherwise, "sell" the topic
            self.topicLabel?.text=self.activeTopicRec.verse_title
        }
        
        self.topicStateImage?.image = UIImage(named: self.activeTopicRec.getTopicStateImageName());
        
    }
    
    func animate() {
        println("animating topic state for topic_id \(activeTopicRec.topic_id)")
        if (self.activeTopicRec.current_user_has_voted==false) {
            if (self.isUserParticipating()) {
                // if the user is a participant and the turns left changes, display it
                self.rotateImage(self.topicStateImage!, duration: self.topicStateAnimDuration)
            } else {
                println("Stopping animation!")
                self.topicStateImage?.image = nil
                // reset the image so it stops animation
                self.topicStateImage?.image = UIImage(named: self.activeTopicRec.getTopicStateImageName());
            }
        }
    }
    
    func isUserParticipating() -> Bool {
        return contains(activeTopicRec.verse_user_ids, NetOpers.sharedInstance.user.id)
    }
    
    private func rotateImage(image : UIImageView, duration : NSTimeInterval) {
        let delay = 0.0
        let fullRotation = CGFloat(M_PI * 2)
        let options = UIViewKeyframeAnimationOptions.Repeat | UIViewKeyframeAnimationOptions.CalculationModePaced
        
        UIView.animateKeyframesWithDuration(duration, delay: delay, options: options, animations: {
            
            // note that we've set relativeStartTime and relativeDuration to zero.
            // Because we're using `CalculationModePaced` these values are ignored
            // and iOS figures out values that are needed to create a smooth constant transition
            UIView.addKeyframeWithRelativeStartTime(0, relativeDuration: 0, animations: {
                image.transform = CGAffineTransformMakeRotation(1/3 * fullRotation)
            })
            
            UIView.addKeyframeWithRelativeStartTime(0, relativeDuration: 0, animations: {
                image.transform = CGAffineTransformMakeRotation(2/3 * fullRotation)
            })
            
            UIView.addKeyframeWithRelativeStartTime(0, relativeDuration: 0, animations: {
                image.transform = CGAffineTransformMakeRotation(3/3 * fullRotation)
            })
            
            }, completion: nil)
    }
    
    func isUserUpNext(userId : Int) -> Bool {
        if (activeTopicRec.next_index_user_ids > -1) {
            if let i : Int = find(activeTopicRec.verse_user_ids, userId) {
                return i==activeTopicRec.next_index_user_ids
            }
        }
        return false
    }
}

class TopicsViewController: UIViewController, UserDelegate {

    @IBOutlet weak var topicButton: TopicButton!
    @IBOutlet var topicScrollView: UIScrollView!
    
    var iAdBanner: ADBannerView?
    var topics = Dictionary<Int, AnyObject>()
    var topic_order:[Int] = []
    var activeTopics:[ActiveTopic] = []
    var should_begin_banner = true
    var lastTabbed : NSDate?
    var audioPlayer : AVAudioPlayer?
    var is_initialized : Bool = false;
    var lastUserEmailAddress : String = ""
    
    private var avatarView : UIImageView = UIImageView()
    private var badgeView : UIImageView = UIImageView()
    
    var is_busy : Bool = false
    var has_topics : Bool = false
    
    // key is verse id
    var navigatingActiveTopics = Dictionary<Int,Topic>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var refreshButton : UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Refresh, target: self, action: "refresh")
        self.navigationItem.rightBarButtonItem = refreshButton
        
        title = "Topics"
        
        // initialize by emptying out all labels
        for view in self.topicScrollView.subviews as [UIView] {
            if let lbl = view as? TopicLabel {
                lbl.text = ""
            }
        }
        
        self.avatarView.addSubview(badgeView)
        self.view.addSubview(avatarView)
        
        lastUserEmailAddress = NetOpers.sharedInstance.user.email_address
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        
        updateAvatar(size);
        
//        if UIDevice.currentDevice().orientation.isLandscape.boolValue {
//            
//        } else {
//            
//        }
    }
    
    func updateAvatar(size : CGSize) {
        
        avatarView.frame = CGRect(
            x: size.width-100, // 720,
            y: 80, //  200,
            width: 123,
            height: 127
        )
        
        // positioned in the avatar view
        badgeView.frame = CGRect(
            x: 30,
            y: 97,
            width: 24,
            height: 24
        )
        
        avatarView.image = UIImage(named: NetOpers.sharedInstance.user.avatarName)
        
        badgeView.image = UIImage(named: "lvl_" + String(NetOpers.sharedInstance.user.level) + ".png")
    }
    
    override func viewWillAppear(animated: Bool) {
        
        println("TopicsViewController.viewWillAppear called")
        
        // very important, the user changed in the same app instance
        // so reinitialize everything
        if (NetOpers.sharedInstance.user.email_address != self.lastUserEmailAddress) {
            self.topic_order.removeAll(keepCapacity: false)
            self.topics.removeAll(keepCapacity: false)
            
            for at in self.activeTopics {
                at.unload()
            }
            
            self.activeTopics.removeAll(keepCapacity: false)
            self.is_initialized = false
            self.has_topics = false
            
            self.lastUserEmailAddress = NetOpers.sharedInstance.user.email_address
        }
        
        if (!has_topics) {
            self.fetchTopics()
        }
        
        var screen_height = UIScreen.mainScreen().bounds.height
        self.iAdBanner = self.appdelegate().iAdBanner
        //self.iAdBanner?.delegate = self
        self.iAdBanner?.frame = CGRectMake(0,screen_height-98, 0, 0)
        if let adb = self.iAdBanner{
            println("adding ad banner subview ")
            self.view.addSubview(adb)
        }
        
        // click on the tab, so refresh
        if (NetOpers.sharedInstance.user.is_logged_in()) {
            
            updateAvatar(UIScreen.mainScreen().bounds.size);
            
            NetOpers.sharedInstance.user.addUserDelegate(self)
            
            self.fetchActiveTopics()
        }
        
        is_busy = false
    }
    
    override func viewWillDisappear(animated: Bool){
//        self.iAdBanner?.delegate = nil
//        self.iAdBanner?.removeFromSuperview()
    }
    
    func handleUserLevelChange(oldLevel : Int, newLevel : Int) {
        println("handling user level change")
        if ( !(oldLevel==newLevel) ) {
            // if the level changed, refresh the topics
            println("level changed, reloading all topics")
            self.fetchTopics()
        }
    }
    
    func refresh() -> Bool {
        var refreshed : Bool = false
        if (NetOpers.sharedInstance.user.is_logged_in()) {
            
            var refresh : Bool = false
            
            if (lastTabbed==nil) {
                refresh = true
            } else {
                var elapsedTime = NSDate().timeIntervalSinceDate(lastTabbed!)
                refresh = (elapsedTime>NSTimeInterval(3.0))
            }
            
            if (refresh) {
                if (!is_busy) {
                    updateAvatar(UIScreen.mainScreen().bounds.size);
                    fetchActiveTopics()
                    refreshed = true
                }
                
                lastTabbed = NSDate()
            }
            
        }
        return refreshed
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func playButtonSound(){
        var error:NSError?
        
        var names : [String] = ["Page Turn", "Book Page Turn"]
        var name = names[Int(arc4random_uniform(UInt32(names.count)))]
        if let path = NSBundle.mainBundle().pathForResource(name, ofType: "wav") {
            audioPlayer = AVAudioPlayer(contentsOfURL: NSURL(fileURLWithPath: path), fileTypeHint: "wav", error: &error)
            
            if let sound = audioPlayer {
                
                sound.prepareToPlay()
                
                sound.play()
            }
        }
        println(error)
    }
    
    func isTopicButtonUnlocked(topicButton : TopicButton) -> Bool {
        
        var userLevel : Int = NetOpers.sharedInstance.user.level
        
        if (userLevel==1) {
            if (topicButton.index<=16) {
                return true
            }
        } else {
            if (topicButton.index < (16 + ( (userLevel-1) * 8))) {
                return true
            }
        }
        return false
    }
    
    @IBAction func handleTopicButton(sender: AnyObject) {
        
        var topicButton = (sender as TopicButton)
        
        if (is_initialized && (NetOpers.sharedInstance.user.is_logged_in()) && isTopicButtonUnlocked(topicButton)) {
            
            if (!is_busy) {
                is_busy = true
                
                playButtonSound()
                
                
                var tag = topicButton.tag
                var tid = self.topic_order[tag-1]
                var topic = self.topics[tid] as Topic
                
                // stop the ads on this view
                self.should_begin_banner = false
                
                var verseId : Int?
                var isOpen = false // could be open friend or world
                var activeTopic: ActiveTopicRec? = nil
                
                for at in self.activeTopics {
                    
                    let activeTopicRec = at.activeTopicRec
                    
                    if (activeTopicRec.topic_id==tid) {
                        
                        println("button press topic_id \(tid) activeTopicRec.verse_user_ids \(activeTopicRec.verse_user_ids) src \(activeTopicRec.src)")
                        
                        // i've either joined or created these verses
                        if (at.isUserParticipating() || activeTopicRec.owner_id==NetOpers.sharedInstance.user.id){
                            verseId = activeTopicRec.verse_id
                            activeTopic = activeTopicRec
                            break
                        }else{
                            // just some open verses with available user slots available
                            if activeTopicRec.src == "world" || activeTopicRec.src=="friend" {
                                verseId = activeTopicRec.verse_id
                                isOpen = true
                                activeTopic = activeTopicRec
                                break
                            }
                        }
                        
                    }
                }
                
                if let vid = verseId {
                    
                    // TODO: Check to see if a verse for this topic and level is complete or
                    // all the players have added their lines.. and if so
                    // show the VerseResultsScreenViewController
                    
                    if isOpen{
                        let vc = WorldVerseViewController(nibName: "WorldVerseViewController", bundle:nil)
                        vc.topic = topic
                        vc.activeTopic = activeTopic
                        navigationController?.pushViewController(vc, animated: true)
                        
                    }else{
                        
                        var params = Dictionary<String,AnyObject>()
                        params["verse_id"]=vid
                        params["user_id"]=NetOpers.sharedInstance.user.id
                        
                        self.navigatingActiveTopics[vid] = topic
                        NetOpers.sharedInstance.post(NetOpers.sharedInstance.appserver_hostname! + "/u/active-verse", params: params, openNextView)
                        
//                        let vc = WriteLineViewController(nibName: "WriteLineViewController", bundle:nil)
//                        vc.verseId = vid
//                        vc.topic = topic
//                        navigationController?.pushViewController(vc, animated: true)
                    }
                    
                } else {
                    let vc = NewVerseViewController(nibName: "NewVerseViewController", bundle:nil)
                    vc.topic = topic
                    navigationController?.pushViewController(vc, animated: true)
                    
                }
                
                is_busy = false
            }
            
        }
        
    }
    
    func openNextView(data: NSData?, response: NSURLResponse?, error: NSError?){
        
        
        let httpResponse = response as NSHTTPURLResponse
        if httpResponse.statusCode == 200 {
            if data != nil {
                
                println("loading data...")
                
                let jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(
                    data!, options: NSJSONReadingOptions.MutableContainers,
                    error: nil) as NSDictionary
                
                if let results = jsonResult["results"] as? NSDictionary {
                    
                    println(results)
                    
                    if let vid = results["verse_id"] as? Int{
                        
                        //var vid__:Int? = (vid_ as String).toInt()
                                                
                        //if let vid = vid__{
                            if let topic = self.navigatingActiveTopics[vid]{
                                
                                // there is a verse and a topic
                                if let x = results["is_complete"] as? Bool{
                                    
                                    if x == true {
                                        
                                        self.dispatch_resultsscreen_controller(vid, topic: topic)
                                        
                                        
                                    }else{
                                        
                                        // not marked complete yet, but have all the
                                        // expected lines been submitted?
                                        var has_all_lines = false
                                        if let x = results["has_all_lines"] as? Bool{
                                            has_all_lines = x
                                        }
                                        
                                        var line_count = 0
                                        if let x = results["lines"] as? NSArray{
                                            line_count = x.count
                                        }
                                        
                                        var user_count = 0
                                        if let x = results["user_ids"] as? NSArray{
                                            for user_id in x {
                                                if user_id as Int != -1{
                                                    user_count += 1
                                                }
                                            }
                                        }
                                        
                                        if (has_all_lines || (line_count >= user_count * 4 && user_count > 1)){
                                            
                                            self.dispatch_resultsscreen_controller(vid, topic: topic)
                                            
                                        }else{
                                            
                                            self.dispatch_writeline_controller(vid, topic: topic)
                                        }
                                        
                                    }
                                    
                                }else{
                                    self.dispatch_alert("Error", message: "Bad gameplay state - no is_complete flag", controller_title: "Ok")
                                }
                                
                            }
                            
                        //}
                        
                    }else{
                        self.dispatch_alert("Error", message: "Bad gameplay state - invalid Verse Id", controller_title: "Ok")
                    }
                    
                }
            }
        }else{
            self.dispatch_alert("Error", message: "Cannot get Verse for Topic", controller_title: "Ok")
        }

    }
    
    func dispatch_writeline_controller(verseId:Int, topic:Topic){
        dispatch_async(dispatch_get_main_queue(), {
            
            let vc = WriteLineViewController(nibName: "WriteLineViewController", bundle:nil)
            //let vc = NewWriteLineViewController(nibName: "NewWriteLineViewController", bundle:nil)
            vc.verseId = verseId
            vc.topic = topic
            self.navigationController?.pushViewController(vc, animated: true)
            
        })
        
    }
    
    func dispatch_resultsscreen_controller(verseId:Int, topic:Topic){
        dispatch_async(dispatch_get_main_queue(), {
            
            var sb = UIStoryboard(name: "VerseResultsScreenStoryboard", bundle: nil)
            var controller = sb.instantiateViewControllerWithIdentifier("VerseResultsScreenViewController") as VerseResultsScreenViewController
            controller.verseId = verseId
            self.navigationController?.pushViewController(controller, animated: true)
            
        })
    }
    
    // MARK - Topics
    
    
    func fetchTopics(){
        // get all the available topics (has nothing to do with active / world
        NetOpers.sharedInstance._load_topics(loadTopicData)
    }
    
    func loadTopicData(data:NSData?, response:NSURLResponse?, error:NSError?){
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        
        if let httpResponse = response as? NSHTTPURLResponse {
            if httpResponse.statusCode == 200 {
                
                var user = NetOpers.sharedInstance.user
                
                if data != nil {
                    
                    if let jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(
                        data!, options: NSJSONReadingOptions.MutableContainers,
                        error: nil) as? NSDictionary{
                            
                            if let results = jsonResult["results"] as? NSArray {
                                
                                self.topics.removeAll(keepCapacity: false)
                                self.topic_order.removeAll(keepCapacity: false)
                                
                                for topic in results {
                                    var t = Topic(rec:topic as NSDictionary)
                                    var tid = t.id! as Int
                                    self.topics[tid] = t
                                    self.topic_order.append(tid)
                                }
                            }
                            
                            // needs to happen at least once, even if
                            // a severe error happens
                            has_topics = true
                           
                    }else{
                        self.dispatch_alert("Error", message: "No Topics", controller_title: "Ok")
                    }

                }
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.loadTopicButtons()
                })
                
            }else{
                // TODO: handle specific errors
                self.dispatch_alert("Error: Unable to load Topics", message: "Please make sure to sign in", controller_title: "Ok")

            }
        }
    }
    
    func fetchActiveTopics() {
        // TODO: don't let this be spammed
        is_busy = true
        println("fetchActiveTopics called")
        NetOpers.sharedInstance.get(NetOpers.sharedInstance.appserver_hostname! + "/u/active-topics", loadActiveTopicData)
    }
    
    func getActiveTopic(activeTopicRec : ActiveTopicRec) -> AnyObject? {
        for at : ActiveTopic in self.activeTopics {
            if (at.activeTopicRec.verse_id==activeTopicRec.verse_id) {
                at.activeTopicRec = activeTopicRec // refresh this
                return at
            }
        }
        
        if let index = find(self.topic_order, activeTopicRec.topic_id) {
            // TODO: precautionary let here - need to figure out order view objects are rendered
            var topicButton: TopicButton? = self.view.viewWithTag((index+1)) as? TopicButton
            var topicStateImage: UIImageView = self.getTopicStateImage((index+1), imageName: activeTopicRec.getTopicStateImageName())
            var topicLabel: TopicLabel = self.getTopicLabel((index+1))!
            
            println("found topicButton \(topicButton) topicStateImage \(topicStateImage) activeTopicRec \(activeTopicRec) topicLabel \(topicLabel) index \(index)")
            
            var at : ActiveTopic = ActiveTopic(activeTopicRec: activeTopicRec, topicButton: topicButton!, topicStateImage: topicStateImage, topicLabel: topicLabel, buttonIndex: index)
            
            self.activeTopics.append(at)
            
            return at
        }
        
        return nil
        
    }
    
    func loadActiveTopicData(data:NSData?, response:NSURLResponse?, error:NSError?){
        
        var activeTopicRecs : [ActiveTopicRec] = []
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        
        if let httpResponse = response as? NSHTTPURLResponse {
            if httpResponse.statusCode == 200 {
                
                if data != nil {
                    
                    let jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(
                        data!, options: NSJSONReadingOptions.MutableContainers,
                        error: nil) as NSDictionary
                    
                    println(jsonResult)
                    
                    if let level = jsonResult["user_level"] as? Int {
                        NetOpers.sharedInstance.user.level = level
                    }
                    
                    if let score = jsonResult["user_score"] as? Int {
                        NetOpers.sharedInstance.user.user_score = score
                    }
                    
                    if let results = jsonResult["results"] as? NSArray {
                        
                        for r in results {
                            
                            var atr = ActiveTopicRec()
                            
                            if let id = r["topic_id"] as? Int {
                                atr.topic_id = id
                            }
                            
                            if let src = r["src"] as? String {
                                atr.src = src
                            }
                            
                            if let vid = r["verse_id"] as? Int {
                                atr.verse_id = vid
                            }
                            
                            if let nid = r["next_index_user_ids"] as? Int {
                                atr.next_index_user_ids = nid
                            }
                            
                            if let vids = r["user_ids"] as? [Int] {
                                atr.verse_user_ids = vids
                            }
                            
                            if let ea = r["email_address"] as? String {
                                atr.email_address = ea
                            }
                            
                            if let un = r["user_name"] as? String {
                                atr.user_name = un
                            }
                            
                            if let oid = r["owner_id"] as? Int {
                                atr.owner_id = oid
                            }
                            
                            if let ti = r["title"] as? String {
                                atr.verse_title = ti
                            }
                            
                            if let cuhv = r["current_user_has_voted"] as? Bool {
                                atr.current_user_has_voted = cuhv
                            }
                            
                            activeTopicRecs.append(atr)
                            
                        }
                        
                    }
                    
                }
                
            } else {
                
                self.dispatch_alert("Error", message: "Cannot load Topics", controller_title: "Ok")
                
                self.is_busy = false
                
            }
            
        } else {
            self.is_busy = false
        }
        
        dispatch_async(dispatch_get_main_queue(), {
            self.syncActiveTopics(activeTopicRecs)
        })

    }
    
    func syncActiveTopics(activeTopicRecs : [ActiveTopicRec]) {
        
        is_busy = true
        
        // mark all active topics as stale before data refresh
        for at : ActiveTopic in self.activeTopics {
            at.setStale()
        }
        
        var upNextCount : Int = 0
        var joinedCount : Int = 0
        
        for atr : ActiveTopicRec in activeTopicRecs {
            // TODO: figure out how to make this not optional as active topics can start loading before topics finished?
            if let at : ActiveTopic = self.getActiveTopic(atr) as? ActiveTopic {
                if (at.isUserUpNext(NetOpers.sharedInstance.user.id)) {
                    upNextCount += 1;
                }
                
                if (at.isUserParticipating()) {
                    joinedCount += 1;
                }
            }
        }
        
        self.navigationController?.tabBarItem.badgeValue = String(upNextCount) + " / " + String(joinedCount)
        
        // clean up by removing all stale active topics
        var staleActiveTopics : [Int] = []
        
        var i : Int = 0
        for at : ActiveTopic in self.activeTopics {
            if (at.isStale()) {
                at.unload()
                staleActiveTopics.append(at.activeTopicRec.topic_id)
            } else {
                at.refresh()
                at.animate()
            }
            
            i += 1
        }
        
        println("stale active topic ids \(staleActiveTopics) activeTopics count \(self.activeTopics.count)")
        
        for topicId : Int in staleActiveTopics {
            var index : Int = -1
            for at : ActiveTopic in self.activeTopics {
                if (at.activeTopicRec.topic_id==topicId) {
                    break
                }
                index += 1
            }
            if (index > -1) {
                self.activeTopics.removeAtIndex(index)
            }
        }
        
        is_busy = false
    }
    
    func getTopicLabel(index : Int) -> TopicLabel? {
        for view in self.topicScrollView.subviews as [UIView] {
            if let lbl = view as? TopicLabel {
                if (lbl.index==(index)) {
                    return lbl
                }
            }
        }
        return nil
    }
    
    func getTopicStateImage(index : Int, imageName : String) -> UIImageView {
        let image = UIImage(named: imageName)
        let imageView = UIImageView(image: image!)
        
        if let btn: TopicButton = self.view.viewWithTag(index) as? TopicButton {
            
            imageView.frame = CGRect(
                x: btn.center.x - (btn.frame.width * 0.5),
                y: btn.center.y - (btn.frame.height * 0.5),
                width: imageView.frame.width ,
                height: imageView.frame.height
            )
            
            println("adding topic state image to subview for \(imageName)")
            self.topicScrollView.addSubview(imageView)
            
        }
        return imageView
    }
    
    func loadTopicButtons(){
        if (self.topic_order.count > 0 && self.topics.count>0) {
            
            println("loading topic buttons")
            
            var maxTopics : Int = 16
            
            if (NetOpers.sharedInstance.user.is_logged_in()) {
                if (NetOpers.sharedInstance.user.level>1) {
                    maxTopics = 16 + ( (NetOpers.sharedInstance.user.level-1) * 8)
                }
            }
            
            println("num topics for level: " + String(maxTopics))
            
            // self.topic_order = self.shuffle(self.topic_order)
            for idx in 1...maxTopics{
                
                var tid = self.topic_order[idx-1]
                var topic = self.topics[tid] as Topic
                
                var btn: TopicButton? = self.view.viewWithTag(idx) as? TopicButton
                if btn != nil{
                    println(topic.main_icon_name)
                    btn!.setImage(UIImage(named: topic.main_icon_name! as String), forState: .Normal)
                } else {
                    println("no button found for tag " + String(idx))
                }
            }
            
            is_busy = false
            is_initialized = true
        }
    }
    
    
    // MARK: - Ad Banner
    
    func appdelegate () -> AppDelegate{
        return UIApplication.sharedApplication().delegate as AppDelegate
    }
    
    func hide_adbanner(){
        self.iAdBanner?.hidden = true
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    // MARK: - gesture, shuffling
    
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent) {
        if motion == .MotionShake {
            self.loadTopicButtons()
        }
    }
    
    func shuffle<C: MutableCollectionType where C.Index == Int>(var list: C) -> C {
        let count = countElements(list)
        for i in 0..<(count - 1) {
            let j = Int(arc4random_uniform(UInt32(count - i))) + i
            swap(&list[i], &list[j])
        }
        return list
    }
    
    // MARK: - notification, alerts
    
    func dispatch_alert(title:String, message:String, controller_title:String){
        
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0), { ()->() in
            dispatch_async(dispatch_get_main_queue(), {
                
                let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
                alertController.addAction(UIAlertAction(title: controller_title, style: UIAlertActionStyle.Default,handler: nil))
                
                self.presentViewController(alertController, animated: true, completion: nil)
                
            })
        })
    }
    
    func show_alert(title:String, message:String, controller_title:String){
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: controller_title, style: UIAlertActionStyle.Default,handler: nil))
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }

}

