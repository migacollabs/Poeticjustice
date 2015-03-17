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
    var max_lines : Int = 8
    var num_lines : Int = 0 // current number of lines

    
    func getTopicStateImageName() -> String {
        
        // println("ActiveTopicRec.getTopicStateImageName \(current_user_has_voted)")
        
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
    private var topicStateImage : UIImageView = UIImageView() // permanent really
    private var topicLabel : TopicLabel? // permanent, text transient
    private var buttonIndex : Int = -1 // permanent
    private var refreshed : Bool = false // used to diff active topics
    
    private var topicStateAnimDuration : NSTimeInterval = 4.0
    
    init(activeTopicRec : ActiveTopicRec, topicButton : TopicButton, topicLabel : TopicLabel, buttonIndex : Int) {
        self.activeTopicRec = activeTopicRec
        self.topicButton = topicButton
        self.topicLabel = topicLabel
        self.buttonIndex = buttonIndex
        
        self.topicStateImage.image = UIImage(named: activeTopicRec.getTopicStateImageName());
        
        self.topicStateImage.frame = CGRect(
            x: topicButton.center.x - (topicButton.frame.width * 0.5),
            y: topicButton.center.y - (topicButton.frame.height * 0.5),
            width: topicButton.frame.width ,
            height: topicButton.frame.height
        )
        
        println("Created topicStateImage topic_id \(activeTopicRec.topic_id) - \(topicStateImage) for button index \(topicButton.index) and verse_id \(activeTopicRec.verse_id)")
        
        self.refreshed = true
    }
    
    func getTopicStateImage() -> UIImageView {
        return self.topicStateImage
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
        println("unloading ActiveTopic for topic_id \(self.activeTopicRec.topic_id)")
        self.topicStateImage.image = nil
        // self.topicStateImage.removeFromSuperview()
        self.topicLabel?.text = ""
        
        self.activeTopicRec.verse_user_ids = []
        self.activeTopicRec.owner_id = -1
    }
    
    func getCountTurnsLeft() -> Int {
        if let playerPos : Int = find(activeTopicRec.verse_user_ids, NetOpers.sharedInstance.user.id) {
            // println("playerPos \(playerPos) in verse_user_ids \(activeTopicRec.verse_user_ids) next_index \(activeTopicRec.next_index_user_ids)")
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
            
            println("refresh active topic_id \(activeTopicRec.topic_id) - turns left for player \(counts)")
            
            topicStateAnimDuration = 4.0
            
            if (counts==0) {
                // player's turn to write a line
                topicStateAnimDuration = 1.0
            } else {
                // player's turn to wait, unless it's time to vote
                if (activeTopicRec.num_lines>=activeTopicRec.max_lines && !activeTopicRec.current_user_has_voted) {
                        topicStateAnimDuration = 1.0
                }
            }
            
        } else {
            // otherwise, "sell" the topic
            self.topicLabel?.text=self.activeTopicRec.verse_title
        }
        
    }
    
    func animate() {
        println("animating topic state for topic_id \(activeTopicRec.topic_id)")
        
        // reset the image so it stops animation
        self.topicStateImage.image = UIImage(named: self.activeTopicRec.getTopicStateImageName());
        
        // rotate it if necessary
        if (self.activeTopicRec.current_user_has_voted==false) {
            if (self.isUserParticipating()) {
                // if the user is a participant and the turns left changes, display it
                self.rotateImage(self.topicStateImage, duration: self.topicStateAnimDuration)
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
}

class TopicsHelper {
    // Singleton
    class var sharedInstance: TopicsHelper {
        struct Static {
            static let instance = TopicsHelper();
        }
        return Static.instance
    }
    
    func isUserUpNext(activeTopicRec : ActiveTopicRec, userId : Int) -> Bool {
        if (activeTopicRec.next_index_user_ids > -1) {
            if let i : Int = find(activeTopicRec.verse_user_ids, userId) {
                return i==activeTopicRec.next_index_user_ids
            }
        }
        return false
    }
    
    func convertToActiveTopicRecs(results : NSArray) -> [ActiveTopicRec] {
        
        var recs : [ActiveTopicRec] = []
        
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
            } else {
                atr.verse_user_ids = []
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
            
            if let ml = r["max_lines"] as? Int {
                atr.max_lines = ml
            }
            
            if let nl = r["num_lines"] as? Int {
                atr.num_lines = nl
            }
            
            recs.append(atr)
        }
        
        return recs
        
    }

}

class TopicsViewController: UIViewController, UserDelegate {
    

    @IBOutlet weak var topicButton: TopicButton!
    @IBOutlet var topicScrollView: UIScrollView!
    
    // var iAdBanner: ADBannerView?
    var topics = Dictionary<Int, AnyObject>()
    var topic_order:[Int] = []
    var activeTopics : Dictionary<Int, ActiveTopic> = Dictionary<Int, ActiveTopic>() // key = topic_id
    var should_begin_banner = true
    var lastTabbed : NSDate?
    var audioPlayer : AVAudioPlayer?
    var is_initialized : Bool = false;
    var lastUserEmailAddress : String = ""
    
    private var avatarView : UIImageView = UIImageView()
    private var badgeView : UIImageView = UIImageView()
    private var scoreView : UIImageView = UIImageView();
    private var favView : UIImageView = UIImageView();
    private var scoreLabel : UILabel = UILabel();
    private var favLabel : UILabel = UILabel();
    
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
        
        self.scoreView.addSubview(scoreLabel);
        self.favView.addSubview(favLabel);
        
        self.avatarView.addSubview(badgeView)
        self.avatarView.addSubview(scoreView)
        self.avatarView.addSubview(favView)
        
        self.view.addSubview(avatarView)
        
        lastUserEmailAddress = NetOpers.sharedInstance.user.email_address
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        
        updateAvatar(size);
        
        // var screen_height = UIScreen.mainScreen().bounds.height
        // self.iAdBanner?.frame = CGRectMake(0,screen_height-98, 0, 0)
        
    }
    
    func didUserCompleteGame() -> Bool {
        if (NetOpers.sharedInstance.user.is_logged_in()) {
            if (NetOpers.sharedInstance.user.level==7) {
                var complete_count : Int = 0
                for (topicId, ar) in self.activeTopics {
                    if (ar.activeTopicRec.current_user_has_voted) {
                        complete_count += 1;
                    }
                }
                if (complete_count==64) {
                    return true
                }
            }
        }
        return false
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
        
        scoreView.frame = CGRect(
            x: 30,
            y: 125,
            width: 24,
            height: 24
        )
        
        scoreLabel.frame = CGRect(
            x: 28,
            y: 0,
            width: 50,
            height: 24
        )
        
        favView.frame = CGRect(
            x: 30,
            y: 153,
            width: 24,
            height: 24
        )
        
        favLabel.frame = CGRect(
            x: 28,
            y: 0,
            width: 50,
            height: 24
        )
        
        avatarView.image = UIImage(named: NetOpers.sharedInstance.user.avatarName)
        badgeView.image = UIImage(named: "lvl_" + String(NetOpers.sharedInstance.user.level) + ".png")
        scoreView.image = UIImage(named: "tea-plant-leaf-icon.png")
        favView.image = UIImage(named: "star_gold_256.png")
        
        scoreLabel.text = String(format: "x%03d", NetOpers.sharedInstance.user.user_score)
        favLabel.text = String(format: "x%03d", NetOpers.sharedInstance.user.num_favorited_lines)
        
        scoreLabel.font = UIFont(name: "Courier", size: 14)!
        favLabel.font = UIFont(name: "Courier", size: 14)!
    }
    
    private var viewedGameComplete : Bool = false;
    
    override func viewWillAppear(animated: Bool) {
        
        println("TopicsViewController.viewWillAppear called")
        
        is_busy = true
        
        // very important, the user changed in the same app instance
        // so reinitialize everything
        if (NetOpers.sharedInstance.user.email_address != self.lastUserEmailAddress) {
            self.topic_order.removeAll(keepCapacity: false)
            self.topics.removeAll(keepCapacity: false)
            
            for (topicId, at) in self.activeTopics {
                at.unload()
            }
            
            self.is_initialized = false
            self.has_topics = false
            
            self.lastUserEmailAddress = NetOpers.sharedInstance.user.email_address
        }
        
        if (!has_topics) {
            // do this here to handle the leveling up as well as init
            self.fetchTopics()
        }
//        
//        var screen_height = UIScreen.mainScreen().bounds.height
//        self.iAdBanner = self.appdelegate().iAdBanner
//        //self.iAdBanner?.delegate = self
//        self.iAdBanner?.frame = CGRectMake(0,screen_height-98, 0, 0)
//        if let adb = self.iAdBanner{
//            // println("adding ad banner subview ")
//            // self.view.addSubview(adb)
//        }
        
        // click on the tab, so refresh
        if (NetOpers.sharedInstance.user.is_logged_in()) {
            
            updateAvatar(UIScreen.mainScreen().bounds.size);
            
            NetOpers.sharedInstance.user.addUserDelegate(self)
            
            if (!viewedGameComplete && self.didUserCompleteGame()) {
                self.show_game_complete_screen()
                viewedGameComplete = true
            }
            
            if (has_topics) {
                // this eventually leads to is_busy = false
                self.fetchActiveTopics()
            } else {
                is_busy = false
            }
        } else {
            
            self.show_alert("You are not signed in", message: "Please sign in before playing.", controller_title: "Ok")
            
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            
            is_busy = false
        }
        
    }
    
    override func viewWillDisappear(animated: Bool){
//        self.iAdBanner?.delegate = nil
//        self.iAdBanner?.removeFromSuperview()
    }
    
    func handleUserLevelChange(oldLevel : Int, newLevel : Int) {
        if ( !(oldLevel==newLevel) ) {
            // if the level changed, refresh the topics
            println("user level changed, reloading all topics")
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
        
        if (is_initialized) {
            
            if (NetOpers.sharedInstance.user.is_logged_in()) {
                if (isTopicButtonUnlocked(topicButton)) {
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
                        
                        for (topicId, at) in self.activeTopics {
                            
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
                        
                        println("is verse open? \(isOpen)")
                        
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
                        
                    }
                } else {
                    // have not leveled up
                    self.show_alert("Oops", message: "You'll need to level up to unlock this topic!", controller_title: "Ok")
                }
            } else {
                // have not leveled up
                self.show_alert("Oops", message: "You'll need to sign in to play!", controller_title: "Ok")
            }
        }
        
    }
    
    func openNextView(data: NSData?, response: NSURLResponse?, error: NSError?){
        
        if let httpResponse = response as? NSHTTPURLResponse {
            if httpResponse.statusCode == 200 {
                if data != nil {
                    
                    // println("loading data...")
                    
                    let jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(
                        data!, options: NSJSONReadingOptions.MutableContainers,
                        error: nil) as NSDictionary
                    
                    if let results = jsonResult["results"] as? NSDictionary {
                        
                        // println(results)
                        
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
                                    self.show_alert("Error", message: "Bad gameplay state - no is_complete flag", controller_title: "Ok")
                                }
                                
                            }
                            
                            //}
                            
                        }else{
                            self.show_alert("Error", message: "Bad gameplay state - invalid Verse Id", controller_title: "Ok")
                        }
                        
                    }
                }
            }else{
                self.show_alert("\(httpResponse.statusCode) Oops", message: "There was a problem loading the verse for the selected topic.  Please try again.", controller_title:"Ok")
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
            
            // println(self.navigationController)
            
            var sb = UIStoryboard(name: "VerseResultsScreenStoryboard", bundle: nil)
            var controller = sb.instantiateViewControllerWithIdentifier("VerseResultsScreenViewController") as VerseResultsScreenViewController
            controller.verseId = verseId
            controller.topic = topic
            self.navigationController?.popViewControllerAnimated(false)
            self.navigationController?.pushViewController(controller, animated: true)
            
        })
    }
    
    // MARK - Topics
    
    
    func fetchTopics(){
        // get all the available topics (has nothing to do with active / world
        NetOpers.sharedInstance._load_topics(loadTopicData)
    }
    
    func loadTopicData(data:NSData?, response:NSURLResponse?, error:NSError?){
        
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
                            
                            if (NetOpers.sharedInstance.user.is_logged_in()) {
                                dispatch_async(dispatch_get_main_queue()) {
                                    self.fetchActiveTopics()
                                }
                            }
                        
                            // needs to happen at least once, even if
                            // a severe error happens
                            has_topics = true
                           
                    }else{
                        self.show_alert("Error", message: "No topics found", controller_title: "Ok")
                    }

                }
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.loadTopicButtons()
                })
                
            }else{
                self.show_alert("\(httpResponse.statusCode) Oops", message: "There was a problem loading the topics.  Please try again.", controller_title:"Ok")

            }
        }
        
        if (error != nil) {
            if let e = error?.localizedDescription {
                self.show_alert("Unable to load topics", message: e, controller_title:"Ok")
            } else {
                self.show_alert("Network error", message: "Unable to load topics", controller_title:"Ok")
            }
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
        
    }
    
    func fetchActiveTopics() {
        // TODO: don't let this be spammed
        is_busy = true
        // println("fetchActiveTopics called")
        NetOpers.sharedInstance.get(NetOpers.sharedInstance.appserver_hostname! + "/u/active-topics", loadActiveTopicData)
    }
    
    func getActiveTopic(activeTopicRec : ActiveTopicRec) -> AnyObject? {
        for (topicId, at) in self.activeTopics {
            if (at.activeTopicRec.topic_id==activeTopicRec.topic_id) {
                at.activeTopicRec = activeTopicRec
                return at
            }
        }
        
        if let index = find(self.topic_order, activeTopicRec.topic_id) {
            
            var topicButton: TopicButton? = self.view.viewWithTag((index+1)) as? TopicButton
            var topicLabel: TopicLabel = self.getTopicLabel((index+1))!
            
            var at : ActiveTopic = ActiveTopic(activeTopicRec: activeTopicRec, topicButton: topicButton!, topicLabel: topicLabel, buttonIndex: index)
            
            self.topicScrollView.addSubview(at.getTopicStateImage())
            
            self.activeTopics[activeTopicRec.topic_id] = at
            
            return at
        }
        
        return nil
        
    }
    
    
    func loadActiveTopicData(data:NSData?, response:NSURLResponse?, error:NSError?){
        
        var activeTopicRecs : [ActiveTopicRec] = []
        
        if let httpResponse = response as? NSHTTPURLResponse {
            if httpResponse.statusCode == 200 {
                
                if data != nil {
                    
                    let jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(
                        data!, options: NSJSONReadingOptions.MutableContainers,
                        error: nil) as NSDictionary
                    
                    if let level = jsonResult["user_level"] as? Int {
                        NetOpers.sharedInstance.user.level = level
                    }
                    
                    if let score = jsonResult["user_score"] as? Int {
                        NetOpers.sharedInstance.user.user_score = score
                    }
                    
                    if let numFavs = jsonResult["num_of_favorited_lines"] as? Int {
                        NetOpers.sharedInstance.user.num_favorited_lines = numFavs
                    }
                    
                    if let results = jsonResult["results"] as? NSArray {
                        activeTopicRecs = TopicsHelper.sharedInstance.convertToActiveTopicRecs(results)
                    }
                    
                }
                
            } else {
                
                self.show_alert("\(httpResponse.statusCode) Oops", message: "There was a problem loading the topics.  Please try again.", controller_title:"Ok")
                
                self.is_busy = false
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            }
            
        } else {
            self.is_busy = false
        }
        
        if (error != nil) {
            if let e = error?.localizedDescription {
                self.show_alert("Unable to load topics", message: e, controller_title:"Ok")
            } else {
                self.show_alert("Network error", message: "Unable to load topics", controller_title:"Ok")
            }
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
        
        dispatch_async(dispatch_get_main_queue(), {
            self.syncActiveTopics(activeTopicRecs)
        })

    }
    
    private var is_syncing : Bool = false
    
    func syncActiveTopics(activeTopicRecs : [ActiveTopicRec]) {
        
        if (!is_syncing) {
            
            is_syncing = true
            is_busy = true
            
            // mark invalid past active topics as stale before data refresh
            for (topicId, at) in self.activeTopics {
                var found : Bool = false
                for atr : ActiveTopicRec in activeTopicRecs {
                    if (atr.topic_id==at.activeTopicRec.topic_id) {
                        found = true
                        break;
                    }
                }
                if (!found) {
                    at.setStale()
                }
            }
            
            var upNextCount : Int = 0
            var joinedCount : Int = 0
            
            for atr : ActiveTopicRec in activeTopicRecs {
                
                if let at : ActiveTopic = self.getActiveTopic(atr) as? ActiveTopic {
                    
                    if (TopicsHelper.sharedInstance.isUserUpNext(at.activeTopicRec, userId: NetOpers.sharedInstance.user.id) && !at.activeTopicRec.current_user_has_voted) {
                        upNextCount += 1;
                    }
                    
                    if (at.isUserParticipating()) {
                        joinedCount += 1;
                    }
                }
            }
            
            if (upNextCount > 0) {
                self.navigationController?.tabBarItem.badgeValue = String(upNextCount)
            } else {
                self.navigationController?.tabBarItem.badgeValue = nil
            }
            
            // clean up by removing all stale active topics
            var staleActiveTopics : [Int] = []
            
            var i : Int = 0
            for (topicId, at) in self.activeTopics {
                
                if (at.isStale()) {
                    at.unload()
                    staleActiveTopics.append(at.activeTopicRec.topic_id)
                } else {
                    at.refresh()
                    at.animate()
                }
                
                i += 1
            }
            
            println("stale check: topic_ids \(staleActiveTopics) of \(self.activeTopics.count) total topics are stale")
            
            for topicId : Int in staleActiveTopics {
                var index : Int = -1
                for (topicId, at) in self.activeTopics {
                    if (at.activeTopicRec.topic_id==topicId) {
                        println("removing stale topic for topic_id \(topicId)")
                        break
                    }
                    index += 1
                }
                if (index > -1) {
                    self.activeTopics[topicId]=nil
                }
            }
            
            is_syncing = false
            is_busy = false
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
        
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
    
    func loadTopicButtons(){
        if (self.topic_order.count > 0 && self.topics.count>0) {
            
            // println("loading topic buttons")
            
            var maxTopics : Int = 16
            
            if (NetOpers.sharedInstance.user.is_logged_in()) {
                if (NetOpers.sharedInstance.user.level>1) {
                    maxTopics = 16 + ( (NetOpers.sharedInstance.user.level-1) * 8)
                }
            }
            
            // println("num topics for level: " + String(maxTopics))
            
            // self.topic_order = self.shuffle(self.topic_order)
            for idx in 1...maxTopics{
                
                var tid = self.topic_order[idx-1]
                var topic = self.topics[tid] as Topic
                
                var btn: TopicButton? = self.view.viewWithTag(idx) as? TopicButton
                if btn != nil{
                    // println(topic.main_icon_name)
                    btn!.setImage(UIImage(named: topic.main_icon_name! as String), forState: .Normal)
                } else {
                    println("no button found for tag " + String(idx))
                }
            }
            
            is_initialized = true
        }
    }
    
    
    // MARK: - Ad Banner
    
    func appdelegate () -> AppDelegate{
        return UIApplication.sharedApplication().delegate as AppDelegate
    }
    
//    func hide_adbanner(){
//        // self.iAdBanner?.hidden = true
//    }
    
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
    
    func show_alert(title:String, message:String, controller_title:String){
        dispatch_async(dispatch_get_main_queue()) {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: controller_title, style: UIAlertActionStyle.Default,handler: nil))
            
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    func show_game_complete_screen(){
        dispatch_async(dispatch_get_main_queue()) {
            
            let gameController : GameCompleteViewController = GameCompleteViewController(nibName: "GameCompleteViewController", bundle: nil)
            
            self.navigationController?.pushViewController(gameController, animated: true)
        }
    }

}

