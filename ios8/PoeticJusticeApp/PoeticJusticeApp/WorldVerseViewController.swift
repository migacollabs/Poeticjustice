//
//  WorldVerseViewController.swift
//  PoeticJusticeApp
//
//  Created by Mat Mathews on 1/30/15.
//  Copyright (c) 2015 Miga Col.Labs. All rights reserved.
//

import UIKit
import iAd
import AVFoundation

class WorldVerseViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var playerTable: UITableView!
    @IBOutlet weak var verseTitle: UILabel!
    
    @IBOutlet var topicButton: UIButton!
    @IBOutlet var joinButton: UIButton!
    @IBOutlet var newButton: UIButton!
    
    var topic : Topic?
    var user_ids:[Int] = []
    var players: [User] = []
    var iAdBanner: ADBannerView?
    
    var activeTopic:ActiveTopicRec? {
        // TODO: not necessary?
        didSet(newValue){
//            self.configureView()
            self.user_ids.removeAll()
            if let nv = newValue {
                for id in nv.verse_user_ids {
                    self.user_ids.append(id)
                }
                
            }
            
        
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.playerTable.registerClass(UITableViewCell.self, forCellReuseIdentifier : "cell")
        self.playerTable.dataSource = self
        self.playerTable.delegate = self
        
        self.playerTable.backgroundColor = UIColor.clearColor()
        
        self.configureView()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        
        println("TopicsViewController.viewWillAppear called")
        var screen_height = UIScreen.mainScreen().bounds.height
        self.iAdBanner = self.appdelegate().iAdBanner
        //self.iAdBanner?.delegate = self
        self.iAdBanner?.frame = CGRectMake(0,screen_height-98, 0, 0)
        if let adb = self.iAdBanner{
            println("adding ad banner subview ")
            self.view.addSubview(adb)
        }
        
        is_busy = false
        
    }
    
    override func viewWillDisappear(animated: Bool){
//        self.iAdBanner?.delegate = nil
//        self.iAdBanner?.removeFromSuperview()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureView(){
        if let at = self.activeTopic{
            self.user_ids = at.verse_user_ids
            if self.user_ids.count>0{
                NetOpers.sharedInstance.get(
                    NetOpers.sharedInstance.appserver_hostname! + "/v/users/id=\(at.verse_id)", load_players)
            }
            
            self.verseTitle.text = at.verse_title
            
        }
        
        if let t_btn = self.topicButton{
            if let t = self.topic{
                t_btn.setImage(UIImage(named: t.main_icon_name as String), forState: .Normal)
            }
        }
    }
    
    var audioPlayer : AVAudioPlayer?
    
    func playButtonSound(){
        var error:NSError?
        
        // TODO: needs to subtle if anything
        if let path = NSBundle.mainBundle().pathForResource("SoundFX1", ofType: "wav") {
            audioPlayer = AVAudioPlayer(contentsOfURL: NSURL(fileURLWithPath: path), fileTypeHint: "wav", error: &error)
            
            if let sound = audioPlayer {
                
                sound.prepareToPlay()
                
                sound.play()
                println("play sound")
            }
        }
        println(error)
    }
    
    var verseId : Int?
    var is_busy : Bool = false

    @IBAction func onJoin(sender: AnyObject) {
        
        if (!is_busy) {
            is_busy = true
         
            // playButtonSound()
            if let at = self.activeTopic{
                
                self.verseId = at.verse_id
                var params = [String:AnyObject]()
                params["user_id"] = NetOpers.sharedInstance.user.id
                params["id"] = self.verseId
                NetOpers.sharedInstance.post(
                    NetOpers.sharedInstance.appserver_hostname! + "/v/join/id=" + String(at.verse_id),
                    params: params,
                    onJoinedCompletionHandeler)
            }
            
        }
    }
    
    // MARK - Gameplay
    
    func onJoinedCompletionHandeler(data:NSData?, response:NSURLResponse?, error:NSError?){
        println("onJoinedCompletionHandeler called")
        if let httpResponse = response as? NSHTTPURLResponse {
            if httpResponse.statusCode == 200{
                
                if data != nil{
                    let jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(
                        data!, options: NSJSONReadingOptions.MutableContainers,
                        error: nil) as NSDictionary
                    
                    println(jsonResult)
                    
                    if let new_player = jsonResult["user"] as? NSDictionary{
                        println("new player \(new_player)")
                        var u = User(user_data:new_player as NSDictionary)
                        self.players.append(u)
                        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
                            dispatch_async(dispatch_get_main_queue(),{
                                
                                self.playerTable.reloadData()
                                let vc = WriteLineViewController(nibName: "WriteLineViewController", bundle:nil)
                                vc.verseId = self.verseId!
                                vc.topic = self.topic
                                self.navigationController!.setViewControllers([self.navigationController!.viewControllers[0],vc], animated: true)
                                
                                self.is_busy = false
                                
                            })
                        })
                    }
                }
                
            }else{
                switch httpResponse.statusCode{
                case 401:
                    // 401 Unauthorized, verse not is not open to world
                    dispatch_alert("Unauthorized", message:"Verse is no longer open to the World", controller_title:"Ok", goBackToTopics:true)
                case 409:
                    // 409 Conflict err, verse no longer available
                    dispatch_alert("Unauthorized", message:"Verse is not open to the World", controller_title:"Ok", goBackToTopics:true)
                default:
                    println("Unhandled Err Code \(httpResponse.statusCode)")
                    break;
                }
                is_busy = false
            }
        }
        
        if (error != nil) {
            if let e = error?.localizedDescription {
                self.show_alert("Unable to join verse", message: e, controller_title:"Ok")
            } else {
                self.show_alert("Network error", message: "Unable to join verse", controller_title:"Ok")
            }
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
        
    }
    

    @IBAction func onStart(sender: AnyObject) {
        
        // playButtonSound()
        let vc = NewVerseViewController(nibName: "NewVerseViewController", bundle:nil)
        vc.topic = self.topic
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK - TableView
    
    func load_players(data:NSData?, response:NSURLResponse?, error:NSError?){
        println("load_players called")
        if let httpResponse = response as? NSHTTPURLResponse {
            if httpResponse.statusCode == 200 {
                if data != nil {
                    
                    let jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(
                        data!, options: NSJSONReadingOptions.MutableContainers,
                        error: nil) as NSDictionary
                    
                    if let players = jsonResult["verse_users"] as? NSArray{
                        
                        self.players.removeAll()
                        
                        for player in players{
                            var u = User(user_data:player as NSDictionary)
                            self.players.append(u)
                        }
                        
                        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
                            dispatch_async(dispatch_get_main_queue(),{
                                
                                self.playerTable.reloadData()
                                
                            })
                        })
                        
                    }
                    
                }
            }else{
                self.show_alert("\(httpResponse.statusCode) Oops", message: "There was a problem loading the players.  Please try again.", controller_title:"Ok")
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            }
        }
        
        if (error != nil) {
            if let e = error?.localizedDescription {
                self.show_alert("Unable to load players", message: e, controller_title:"Ok")
            } else {
                self.show_alert("Network error", message: "Unable to load players", controller_title:"Ok")
            }
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
        
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Players"
    }
    
    func tableView(tableView : UITableView, numberOfRowsInSection section : Int) -> Int {
        return self.players.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell : UITableViewCell = self.playerTable.dequeueReusableCellWithIdentifier("cell") as UITableViewCell
        if self.players.count > 0{
            if let u = self.players[indexPath.row] as User? {
                cell.textLabel?.text = u.user_name
            }
        }
        cell.contentView.backgroundColor = UIColor.clearColor()
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        println(indexPath)
    }
    
    
    func dispatch_alert(title:String, message:String, controller_title:String, goBackToTopics:Bool){
        
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0), { ()->() in
            dispatch_async(dispatch_get_main_queue(), {
                
                let alertController = UIAlertController(
                    title: title,
                    message: message,
                    preferredStyle: UIAlertControllerStyle.ActionSheet)
                
                if goBackToTopics{
                    alertController.addAction(
                        UIAlertAction(title: controller_title,
                            style: UIAlertActionStyle.Default, handler: {
                                (alert: UIAlertAction!) -> Void in
                                
                                self.presentTopicsView()
                                
                        }))
                    
                }else{
                   alertController.addAction(UIAlertAction(title: controller_title, style: UIAlertActionStyle.Default, handler: nil))
                }
                
                self.presentViewController(alertController, animated: true, completion: nil)
                
            })
        })
    }
    
    func presentTopicsView(){
        println("presentTopicsView called")
        let tvc = TopicsViewController(nibName: "TopicsViewController", bundle:nil)
        
        // TODO:
        // this doesn't seem to work.. it presents the topics view
        // but the topics view doent't work as expected
        self.navigationController?.popViewControllerAnimated(true)
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
    
    func show_alert(title:String, message:String, controller_title:String){
        dispatch_async(dispatch_get_main_queue()) {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: controller_title, style: UIAlertActionStyle.Default,handler: nil))
            
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
}
