//
//  MasterViewController.swift
//  MividioCam2
//
//  Created by Mat Mathews on 12/20/14.
//  Copyright (c) 2014 Miga Collabs. All rights reserved.
//

import UIKit
import iAd


class VerseHistoryMasterViewController: UITableViewController {
    
    var topics = Dictionary<Int, AnyObject>()

    var verses:[VerseResultScreenRec] = []
    
    // var iAdBanner: ADBannerView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //self.navigationItem.leftBarButtonItem = self.editButtonItem()
        
        
        NetOpers.sharedInstance._load_topics(loadTopicData)
        
        NetOpers.sharedInstance.get(NetOpers.sharedInstance.appserver_hostname! + "/u/verse-history", load_verses)
        
//        var screen_height = UIScreen.mainScreen().bounds.height
//        self.iAdBanner = self.appdelegate().iAdBanner
//        //self.iAdBanner?.delegate = self
//        self.iAdBanner?.frame = CGRectMake(0,screen_height-50, 0, 0)
//        if let adb = self.iAdBanner{
//            // println("adding ad banner subview ")
//            // self.view.addSubview(adb)
//        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Loading topics
    
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
                                
                                for topic in results {
                                    var t = Topic(rec:topic as NSDictionary)
                                    var tid = t.id! as Int
                                    self.topics[tid] = t
                                }
                            }
                        
                            
                    }else{
                        self.show_alert("Error", message: "No topics found", controller_title: "Ok")
                    }
                    
                }
                
            }else{
                self.show_alert("\(httpResponse.statusCode) Oops",
                    message: "There was a problem loading the topics.  Please try again.",
                    controller_title:"Ok")
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
    
    
    
    // MARK: - Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow() {
                let vhr = self.verses[indexPath.row]
                
                if var topic = self.topics[vhr.topicId] as? Topic{
                    
                    (segue.destinationViewController as VerseHistoryDetailViewController).verseId = vhr.id
                    (segue.destinationViewController as VerseHistoryDetailViewController).verseRec = vhr
                    (segue.destinationViewController as VerseHistoryDetailViewController).topic = topic
                }
                
            }
        }
    }
    
    // MARK: - verses 
    
    func load_verses(data: NSData?, response: NSURLResponse?, error: NSError?){
        
        if let httpResponse = response as? NSHTTPURLResponse {
            if httpResponse.statusCode == 200 {
                if data != nil {
                    
                    let jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(
                        data!, options: NSJSONReadingOptions.MutableContainers,
                        error: nil) as NSDictionary
                    
                    if let results = jsonResult["results"] as? NSArray{
                        
                        var verses:[VerseResultScreenRec] = []
                        
                        for v in results {
                            
                            var vh = VerseResultScreenRec()
                            
                            if let x = v["id"] as? Int{
                                vh.id = x
                            }
                            
                            if let x = v["verse_key"] as? String{
                                vh.verseKey = x
                            }
                            
                            if let x = v["title"] as? String{
                                vh.title = x
                            }
                            
                            if let x = v["topic_id"] as? Int{
                                vh.topicId = x
                            }
                            
                            if let x = v["owner_id"] as? Int{
                                vh.owner_id = x
                            }
                            
                            if let x = v["user_ids"] as? [Int]{
                                vh.user_ids = x
                            }
                            
                            if let x = v["lines_record"] as? String{
                                let data = (x as NSString).dataUsingEncoding(NSUTF8StringEncoding)
                                let linesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(
                                    data!, options: NSJSONReadingOptions.MutableContainers,
                                    error: nil) as NSDictionary
                                
                                for (line_position, line_tuple) in linesDict{
                                    
                                    var p:Int? = (line_position as? String)!.toInt()
                                    if let lp = p{
                                        var vlr = VerseResultScreenLineRec(position:p!, text:line_tuple[1] as String, player_id:line_tuple[0] as Int, line_score:0)
                                        vh.lines_recs[vlr.position] = vlr
                                        
                                    }else{
                                        println("corrupt data")
                                    }
                                    
                                }
                            }
                            
                            if let x = v["votes_record"] as? String{
                                let data = (x as NSString).dataUsingEncoding(NSUTF8StringEncoding)
                                let votesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(
                                    data!, options: NSJSONReadingOptions.MutableContainers,
                                    error: nil) as NSDictionary
                                for(voterId, linePos) in votesDict{
                                    var k:Int? = (voterId as? String)!.toInt()
                                    if k != nil{
                                        vh.votes[k!] = linePos as? Int
                                    }
                                }
                            }
                            
                            if let x = v["players_record"] as? String{
                                
                                let data = (x as NSString).dataUsingEncoding(NSUTF8StringEncoding)
                                let playersArray: NSArray = NSJSONSerialization.JSONObjectWithData(
                                    data!, options: NSJSONReadingOptions.MutableContainers,
                                    error: nil) as NSArray
                                for player in playersArray as NSArray{
                                    
                                    // U.id, U.user_name, U.user_prefs, U.user_score, U.level
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
                                    
                                    var score = player[3] as Int
                                    var level = player[4] as Int
                                    var flag = player[5] as String
                                    var numFavs = player[6] as Int
                                    
                                    vh.players[pid] = VerseResultScreenPlayerRec(
                                                        user_id: pid,
                                                        user_name: usrnm,
                                                        user_score:score,
                                                        num_of_favorited_lines:numFavs,
                                                        level:level,
                                                        flag_icon:flag,
                                                        avatar_name:avnStr!)
                                }
                                
                            }

                            self.verses.append(vh)
                            
                        }
                        
                        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
                            dispatch_async(dispatch_get_main_queue(),{
                                
                                self.tableView.reloadData()
                                //self.animateTable()
                                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                                
                            })
                        })
                        
                    }
                }
            } else {
                self.show_alert(
                    "\(httpResponse.statusCode) Oops",
                    message: "There was a problem loading the verse history.  Please try again.",
                    controller_title:"Ok")
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            }
        }
        
        if (error != nil) {
            if let e = error?.localizedDescription {
                self.show_alert("Unable to load verse history", message: e, controller_title:"Ok")
            } else {
                self.show_alert("Network error", message: "Unable to load verse history", controller_title:"Ok")
            }
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
    }
    
    // MARK: - Table View
    

    func animateTable() {
        tableView.reloadData()
        
        let cells = tableView.visibleCells()
        let tableHeight: CGFloat = tableView.bounds.size.height
        
        for i in cells {
            let cell: UITableViewCell = i as UITableViewCell
            cell.transform = CGAffineTransformMakeTranslation(0, tableHeight)
        }
        
        var index = 0
        
        for a in cells {
            let cell: UITableViewCell = a as UITableViewCell
            UIView.animateWithDuration(1.5, delay: 0.05 * Double(index), usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: nil, animations: {
                cell.transform = CGAffineTransformMakeTranslation(0, 0);
                }, completion: nil)
            
            index += 1
        }
    }

    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.verses.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell
        if let tc = cell as? VerseHistoryTableViewCell{
            if (self.verses.count>0 && self.topics.count>0) {
                // ran into a rare error here (depending on sequence of which views the user navigates) where self.verses has data while self.topics does not.  this is just to make sure
                var verse = self.verses[indexPath.row]
                var topic = self.topics[verse.topicId] as Topic
                tc.verseTitle?.text = verse.title
                tc.topicImage?.image = UIImage(named: topic.main_icon_name as String)
            }
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
//            PropertyStore.sharedInstance.removePropertyAtIndex(indexPath.row)
//            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
    
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 65.0
    }
    
    func show_alert(title:String, message:String, controller_title:String){
        dispatch_async(dispatch_get_main_queue()) {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: controller_title, style: UIAlertActionStyle.Default,handler: nil))
            
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    func appdelegate () -> AppDelegate{
        return UIApplication.sharedApplication().delegate as AppDelegate
    }
    
//    func hide_adbanner(){
//        self.iAdBanner?.hidden = true
//    }
    
}




