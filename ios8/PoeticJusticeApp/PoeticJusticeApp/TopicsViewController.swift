//
//  TopicsViewController.swift
//  PoeticJusticeApp
//
//  Created by Mat Mathews on 1/17/15.
//  Copyright (c) 2015 Miga Collabs. All rights reserved.
//

import UIKit

class TopicsViewController: UIViewController {

    @IBOutlet weak var topicButton: UIButton!
    
    var topics = Dictionary<Int, AnyObject>()
    var topic_order:[Int] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        var tag = (sender as UIButton).tag
        var tid = self.topic_order[tag-1]
        var topic = self.topics[tid] as Topic
        let vc = WriteLineViewController(nibName: "WriteLineViewController", bundle: nil)
        vc.topic = topic
        navigationController?.pushViewController(vc, animated: false)
        
        println("loading WriteLineViewController")
        // don't remove the nav bar so the user can go back
    }
    
    func on_loaded_topics_completion(data:NSData?, response:NSURLResponse?, error:NSError?){
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        
        if let httpResponse = response as? NSHTTPURLResponse {
            if httpResponse.statusCode == 200 {
                
                var user = NetOpers.sharedInstance.user
                
                var open_topics: NSArray = (NetOpers.sharedInstance.game_state!.open_topics! as NSArray)
                var open_topics_set = Set<Int>()
                for ot in open_topics{
                    open_topics_set.add(ot as Int)
                }
                
                if data != nil {
                    
                    var data_str = NSString(data:data!, encoding:NSUTF8StringEncoding)
                    
                    if let jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(
                        data!, options: NSJSONReadingOptions.MutableContainers,
                        error: nil) as? NSDictionary{
                            
                            if let len = jsonResult["length"] as? Int{
                                if let results = jsonResult["results"] as? NSArray{
                                    
                                    for topic in results{
                                        var t = Topic(rec:topic as NSDictionary)
                                        var tid = t.id! as Int
                                        self.topics[tid] = t
                                    }
                                    
                                    for tid in open_topics_set{
                                        self.topic_order.append(tid)
                                    }
                                    
                                    for (tid, topic) in self.topics{
                                        if !open_topics_set.contains(tid as Int){
                                            var t = topic as Topic
                                            if t.min_points_req? as Int == 0 || user?.user_score? as Int >= t.min_points_req? as Int{
                                                self.topic_order.append(tid)
                                            }
                                        }
                                    }
                                    
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
            self.topic_order = self.shuffle(self.topic_order)
            for idx in 1...16{
                
                var tid = self.topic_order[idx-1]
                var topic = self.topics[tid] as Topic
                
                
                var btn: UIButton? = self.view.viewWithTag(idx) as? UIButton
                if btn != nil{
                    btn!.setImage(UIImage(named: topic.main_icon_name! as String), forState: .Normal)
                }
            }
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

}




















