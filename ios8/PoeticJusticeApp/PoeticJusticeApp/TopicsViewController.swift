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
    var id : Int = -1
    var src : String = ""
    var verse_id : Int = -1
    var next_index_user_ids : Int = -1
    var verse_user_ids : [Int] = []
    var email_address : String = ""
    var user_name : String = ""
    var owner_id : Int = -1
}

class TopicsViewController: UIViewController, UserDelegate {

    @IBOutlet weak var topicButton: TopicButton!
    @IBOutlet var topicScrollView: UIScrollView!
    
    var iAdBanner: ADBannerView?
    var topics = Dictionary<Int, AnyObject>()
    var topic_order:[Int] = []
    var active_topics:[ActiveTopicRec] = []
    var should_begin_banner = true
    var lastTabbed : NSDate?
    var audioPlayer : AVAudioPlayer?
    
    var is_busy : Bool = false
    var has_topics : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var refreshButton : UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Refresh, target: self, action: "refresh")
        self.navigationItem.rightBarButtonItem = refreshButton
        
        reset_topic_labels()
        
        title = "Topics"
        
        self.get_topics()
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        
        println("TopicsViewController.viewWillAppear called")
        
        if (!has_topics) {
            self.get_topics()
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
            
            NetOpers.sharedInstance.user.addUserDelegate(self)
            
            self.get_active_topics()
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
            self.get_topics()
        }
    }
    
    func refresh() {
        if (NetOpers.sharedInstance.user.is_logged_in()) {
            
            var refresh : Bool = false
            
            if (lastTabbed==nil) {
                refresh = true
            } else {
                var elapsedTime = NSDate().timeIntervalSinceDate(lastTabbed!)
                refresh = (elapsedTime>NSTimeInterval(10.0))
            }
            
            if (refresh) {
                if (!is_busy) {
                    get_active_topics()
                }
                
                lastTabbed = NSDate()
            }
            
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func playButtonSound(){
        var error:NSError?
        
        if let path = NSBundle.mainBundle().pathForResource("Button Press", ofType: "wav") {
            audioPlayer = AVAudioPlayer(contentsOfURL: NSURL(fileURLWithPath: path), fileTypeHint: "wav", error: &error)
            
            if let sound = audioPlayer {
                
                sound.prepareToPlay()
                
                sound.play()
                println("play sound")
            }
        }
        println(error)
    }
    
    var is_initialized : Bool = false;
    
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
                
                for tb in self.active_topics {
                    
                    if (tb.id==tid) {
                        
                        println("tb.verse_user_ids \(tb.verse_user_ids)")
                        
                        // i've either joined or created these verses
                        if (contains(tb.verse_user_ids as [Int], NetOpers.sharedInstance.user.id as Int) || tb.owner_id==NetOpers.sharedInstance.user.id ){
                            verseId = tb.verse_id
                            activeTopic = tb
                            break
                        }else{
                            // just some open verses with available user slots available
                            if tb.src == "world" || tb.src=="friend" {
                                verseId = tb.verse_id
                                isOpen = true
                                activeTopic = tb
                                break
                            }
                        }
                        
                    }
                }
                
                /**
                Verse creation scenarios:
                
                My verse open to world
                My verse open to friends
                Friend verse open to world
                Friend verse open to friends
                Stranger verse open to world
                
                Display scenarios:
                
                My verse
                Friend verse I've not joined (open to world or friends)
                Friend verse I've joined (open to world or friends)
                World verse I've not joined
                World verse I've joined
                **/
                
                if let vid = verseId {
                    
                    if isOpen{
                        let vc = WorldVerseViewController(nibName: "WorldVerseViewController", bundle:nil)
                        vc.activeTopic = activeTopic
                        vc.topic = topic
                        navigationController?.pushViewController(vc, animated: true)
                        
                    }else{
                        let vc = WriteLineViewController(nibName: "WriteLineViewController", bundle:nil)
                        vc.verseId = vid
                        vc.topic = topic
                        navigationController?.pushViewController(vc, animated: true)
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
    
    // MARK - Topics
    
    
    func get_topics(){
        // get all the available topics (has nothing to do with active / world
        NetOpers.sharedInstance._load_topics(on_loaded_topics_completion)
    }
    
    func on_loaded_topics_completion(data:NSData?, response:NSURLResponse?, error:NSError?){
        
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
                    self.present_topics()
                })
                
            }else{
                // TODO: handle specific errors
                self.dispatch_alert("Error: Unable to load Topics", message: "Please make sure to sign in", controller_title: "Ok")

            }
        }
    }
    
    func get_active_topics() {
        // TODO: don't let this be spammed
        is_busy = true
        reset_topic_labels()
        println("get_active_topics called")
        self.active_topics = []
        NetOpers.sharedInstance.get(NetOpers.sharedInstance.appserver_hostname! + "/u/active-topics", update_active_topics)
    }
    
    func update_active_topics(data:NSData?, response:NSURLResponse?, error:NSError?){
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        
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
                    
                    self.active_topics.removeAll()
                    
                    if let results = jsonResult["results"] as? NSArray {
                        
                        for r in results {
                            
                            var atr = ActiveTopicRec()
                            
                            if let id = r["topic_id"] as? Int {
                                atr.id = id
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
                            
                            self.active_topics.append(atr)
                        }
                        
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        self.update_topic_labels()
                    })
                    
                }
                
            }else{
                
                self.dispatch_alert("Error", message: "Cannot load Topics", controller_title: "Ok")
                
                self.is_busy = false
                
            }
        } else {
            self.is_busy = false
        }

    }
    
    func get_topic_label(index : Int) -> TopicLabel? {
        for view in self.topicScrollView.subviews as [UIView] {
            if let lbl = view as? TopicLabel {
                if (lbl.index==index) {
                    return lbl
                }
            }
        }
        return nil
    }
    
    func reset_topic_labels() {
        for view in self.topicScrollView.subviews as [UIView] {
            if let lbl = view as? TopicLabel {
                lbl.text = ""
            }
        }
    }
    
    func update_topic_labels() {
        
        println("TopicsViewController.update_topic_labels called")
        
        for at in self.active_topics {
            
            if let f = find(self.topic_order, at.id) {
                
                var index : Int = f + 1
                
                if let tl = get_topic_label(index) {
                    
                    switch at.src {
                    case "mine":
                        // i created this verse for friends or world
                        tl.text = at.user_name
                    case "joined":
                        // TODO: still need to signify if joined a friends verse or world verse?
                        tl.text = "j: " + at.user_name
                    case "world":
                        // open world verse
                        tl.text = "w: " + at.user_name
                    case "friend":
                        // open friend verse
                        tl.text = "f: " + at.user_name
                    default:
                        break
                        
                    }
                }
                
            }
        }
        
        is_busy = false
    }
    
    
    func present_topics(){
        if self.topic_order.count > 0{
            
            var maxTopics : Int = 16
            
            if (NetOpers.sharedInstance.user.is_logged_in()) {
                if (NetOpers.sharedInstance.user.level>1) {
                    maxTopics = 16 + ( (NetOpers.sharedInstance.user.level-1) * 8)
                }
            }
            
            println("user max topics: " + String(maxTopics))
            
            // self.topic_order = self.shuffle(self.topic_order)
            for idx in 1...maxTopics{
                
                var tid = self.topic_order[idx-1]
                var topic = self.topics[tid] as Topic
                
                var btn: TopicButton? = self.view.viewWithTag(idx) as? TopicButton
                if btn != nil{
                    println(topic.main_icon_name)
                    btn!.setImage(UIImage(named: topic.main_icon_name! as String), forState: .Normal)
                } else {
                    println("No button found for tag " + String(idx))
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
            self.present_topics()
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

