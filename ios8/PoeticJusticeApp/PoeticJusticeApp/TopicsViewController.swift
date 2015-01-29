//
//  TopicsViewController.swift
//  PoeticJusticeApp
//
//  Created by Mat Mathews on 1/17/15.
//  Copyright (c) 2015 Miga Collabs. All rights reserved.
//

import UIKit
import iAd

@IBDesignable
class TopicButton : UIButton {
    @IBInspectable var index: Int = 0
}

@IBDesignable
class TopicLabel : UILabel {
    @IBInspectable var index: Int = 0
}


class ActiveTopic {
    let active_topic_data: NSDictionary
    
    /*
{
"verse_id": 2,
"src": "world",
"email_address": "larry+world@miga.me",
"user_name": null,
"topic_id": 2
}
    */

    init(rec:NSDictionary){
        self.active_topic_data = rec
    }
    
    var id: AnyObject? {
        get {
            if let x = self.active_topic_data["topic_id"] as? Int{
                return x
            }
            return nil
        }
    }
    
    var src : AnyObject? {
        get {
            if let x = self.active_topic_data["src"] as? String {
                return x
            }
            return nil
        }
    }
    
    var verse_id : AnyObject? {
        get {
            if let x = self.active_topic_data["verse_id"] as? Int{
                return x
            }
            return nil
        }
    }
    
    var email_address : AnyObject? {
        get {
            if let x = self.active_topic_data["email_address"] as? String {
                return x
            }
            return nil
        }
    }
    
    var user_name : AnyObject? {
        get {
            if let x = self.active_topic_data["user_name"] as? String {
                return x
            }
            return nil
        }
    }
    
}

class TopicsViewController: UIViewController, ADBannerViewDelegate {

    @IBOutlet weak var topicButton: TopicButton!
    @IBOutlet var topicScrollView: UIScrollView!
    @IBOutlet weak var adBanner: ADBannerView!
    
    var topics = Dictionary<Int, AnyObject>()
    var topic_order:[Int] = []
    var active_topics:[ActiveTopic] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.adBanner.delegate = self
        self.adBanner.hidden = true
        
        for view in self.topicScrollView.subviews as [UIView] {
            if let lbl = view as? TopicLabel {
                lbl.text = ""
            }
        }
        
        title = "Topics"
        
        self.get_topics()
        
        updateUserLabel()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        updateUserLabel()
    }
    
    @IBOutlet var userLabel: UILabel!

    func updateUserLabel() {
        if let un = NetOpers.sharedInstance.user?.user_name as? String {
            if let us = NetOpers.sharedInstance.user?.user_score as? Int {
                self.userLabel.text = un + " // " + String(us) + " points"
            }
        } else {
            self.userLabel.text = "You are not signed in"
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func handleTopicButton(sender: AnyObject) {
        
        var tb = (sender as TopicButton)

        println(tb.index)
        
        for view in self.topicScrollView.subviews as [UIView] {
            if let lbl = view as? TopicLabel {
                if (lbl.index==tb.index) {
                    if let un = NetOpers.sharedInstance.user?.user_name as? String {
                        lbl.text = un
                    }
                    break
                }
            }
        }
        
        var tag = (sender as TopicButton).tag
        var tid = self.topic_order[tag-1]
        var topic = self.topics[tid] as Topic
        
        
        // TODO: if already participating
        
//        let vc = WriteLineViewController(nibName: "WriteLineViewController", bundle: nil)
//        vc.topic = topic
//        navigationController?.pushViewController(vc, animated: false)
        
        let vc = NewVerseViewController(nibName: "NewVerseViewController", bundle:nil)
        vc.topic = topic
        navigationController?.pushViewController(vc, animated: false)
        
        println("loading NewVerseViewController")
        
        // TODO: otherwise load up the verse creation screen
        
    }
    
    func on_loaded_topics_completion(data:NSData?, response:NSURLResponse?, error:NSError?){
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        
        if let httpResponse = response as? NSHTTPURLResponse {
            if httpResponse.statusCode == 200 {
                
                var user = NetOpers.sharedInstance.user
                
                if data != nil {
                    
                    var data_str = NSString(data:data!, encoding:NSUTF8StringEncoding)
                    
                    if let jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(
                        data!, options: NSJSONReadingOptions.MutableContainers,
                        error: nil) as? NSDictionary{
                            
                            if let results = jsonResult["results"] as? NSArray{
                                
                                for topic in results{
                                    var t = Topic(rec:topic as NSDictionary)
                                    var tid = t.id! as Int
                                    self.topics[tid] = t
                                    self.topic_order.append(tid)
                                }
                            }
                           
                    }else{
                        self.dispatch_alert("Error", message: "No Topics", controller_title: "Ok")
                    }

                }
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.present_topics()
                })
                
            }else{
                
                self.dispatch_alert("Error", message: "Cannot load Topics", controller_title: "Ok")

            }
        }
    }
    
    func get_topics(){
        NetOpers.sharedInstance._load_topics(on_loaded_topics_completion)

        NetOpers.sharedInstance.get(NetOpers.sharedInstance.appserver_hostname! + "/u/active-topics", update_active_topics)
    }
    
    func update_active_topics(data:NSData?, response:NSURLResponse?, error:NSError?){
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        
        if let httpResponse = response as? NSHTTPURLResponse {
            if httpResponse.statusCode == 200 {
                
                if data != nil {
                    
                    var data_str = NSString(data:data!, encoding:NSUTF8StringEncoding)
                    
                    if let jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(
                        data!, options: NSJSONReadingOptions.MutableContainers,
                        error: nil) as? NSDictionary{
                            
                            if let results = jsonResult["results"] as? NSArray{
                                    
                                for topic in results{
                                    var t = ActiveTopic(rec:topic as NSDictionary)
                                    self.active_topics.append(t)
                                    
                                }
                            }
                        
                            
                    }else{
                        self.dispatch_alert("Error", message: "No Active Topics Found", controller_title: "Ok")
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        self.update_topic_labels()
                    })
                    
                }
                
            }else{
                
                self.dispatch_alert("Error", message: "Cannot load Topics", controller_title: "Ok")
                
            }
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
    
    func update_topic_labels() {
     
        for at in self.active_topics {
            
            println("***** topic id for email")
            println(at.email_address)
            println(at.id)
            
            var index = find(self.topic_order, at.id as Int)! + 1
            
            println(index)
            
            if let tl = get_topic_label(index) {
                println(tl)
                if let s = at.src as? String {
                    println(at.src)
                    if s=="mine" {
                        tl.text = at.email_address as? String
                    } else if s=="world" {
                        tl.text = "w: " + (at.email_address as? String)!
                    } else if s=="friend" {
                        tl.text = "f: " + (at.email_address as? String)!
                    }
                }
            }
            
        }
        
    }
    
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
    
    func present_topics(){
        if self.topic_order.count > 0{
            // self.topic_order = self.shuffle(self.topic_order)
            for idx in 1...16{
                
                var tid = self.topic_order[idx-1]
                var topic = self.topics[tid] as Topic
                
                var btn: TopicButton? = self.view.viewWithTag(idx) as? TopicButton
                if btn != nil{
                    btn!.setImage(UIImage(named: topic.main_icon_name! as String), forState: .Normal)
                }
            }
        }
    }
    
    
    // MARK: - Ad Banner
    
    func bannerViewWillLoadAd(banner: ADBannerView!) {
        println("bannerViewWillLoadAd called")
    }
    
    func bannerViewDidLoadAd(banner: ADBannerView!) {
       println("bannerViewDidLoadAd called")
        self.adBanner.hidden = false
    }
    
    func bannerViewActionDidFinish(banner: ADBannerView!) {
        println("bannerViewACtionDidFinish called")
    }
    
    func bannerViewActionShouldBegin(banner: ADBannerView!, willLeaveApplication willLeave: Bool) -> Bool{
        println("bannerViewActionShouldBegin called")
        return true
    }
    
    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
        println("bannerView called")
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

