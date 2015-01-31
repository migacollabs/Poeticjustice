//
//  WorldVerseViewController.swift
//  PoeticJusticeApp
//
//  Created by Mat Mathews on 1/30/15.
//  Copyright (c) 2015 Miga Col.Labs. All rights reserved.
//

import UIKit

class WorldVerseViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var playerTable: UITableView!
    @IBOutlet weak var verseTitle: UILabel!
    
    var user_ids:[Int]?
    var players: [User] = []
    
    var activeTopic:ActiveTopic?{
        didSet(newValue){
//            self.configureView()
            self.user_ids = newValue?.verse_user_ids as? [Int]
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.playerTable.registerClass(UITableViewCell.self, forCellReuseIdentifier : "cell")
        self.playerTable.dataSource = self
        self.playerTable.delegate = self
        
        self.configureView()
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureView(){
        if let at = self.activeTopic{
            self.user_ids = at.verse_user_ids as? [Int]
            if self.user_ids != nil{
                NetOpers.sharedInstance.get(
                    NetOpers.sharedInstance.appserver_hostname! + "/v/users/id=\(at.verse_id!)", load_players)
            }
            
        }
    }
    

    @IBAction func onJoin(sender: AnyObject) {
        if let at = self.activeTopic{
            if let vid = at.verse_id as? Int{
                var params = [String:AnyObject]()
                params["user_id"] = NetOpers.sharedInstance.user?.id!
                params["id"] = vid
                NetOpers.sharedInstance.post(
                    NetOpers.sharedInstance.appserver_hostname! + "/v/join/id=\(vid)",
                    params: params,
                    onJoinedCompletionHandeler)
            }
        }
    }
    
    // MARK - Gameplay
    
    func onJoinedCompletionHandeler(data:NSData?, response:NSURLResponse?, error:NSError?){
        println("onJoinedCompletionHandeler called")
        let httpResponse = response as NSHTTPURLResponse
        if httpResponse.statusCode == 200{
            
            if data != nil{
                let jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(
                    data!, options: NSJSONReadingOptions.MutableContainers,
                    error: nil) as NSDictionary
                
                println(jsonResult)
                
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
        }
    }
    

    @IBAction func onStart(sender: AnyObject) {
    }
    
    // MARK - TableView
    
    func load_players(data:NSData?, response:NSURLResponse?, error:NSError?){
        println("load_players called")
        let httpResponse = response as NSHTTPURLResponse
        if httpResponse.statusCode == 200 {
            if data != nil {
                
                let jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(
                    data!, options: NSJSONReadingOptions.MutableContainers,
                    error: nil) as NSDictionary
                
                if let players = jsonResult["verse_users"] as? NSArray{
                    
                    self.players.removeAll()
                    
                    for player in players{
                        var u = User(userData:player as NSDictionary)
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
            println(httpResponse.statusCode)
        }
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        
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
            if let u = self.players[indexPath.row] as User?{
                if let un = u.user_name as? String{
                    cell.textLabel?.text = un
                }
            }
        }
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
        self.presentViewController(tvc, animated: true, completion: nil)
    }
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
//    func loadPlayers(data: NSData?, response: NSURLResponse?, error: NSError?) {
//        let httpResponse = response as NSHTTPURLResponse
//        if httpResponse.statusCode == 200 {
//            if data != nil {
//                
//                let jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(
//                    data!, options: NSJSONReadingOptions.MutableContainers,
//                    error: nil) as NSDictionary
//                
//                if let results = jsonResult["results"] as? NSArray{
//                    
//                    self.players.removeAll()
//                    
//                    for p in results {
//                        
//                    }
//                    
//                    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
//                        dispatch_async(dispatch_get_main_queue(),{
//                            
//                            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
//                        })
//                    })
//                    
//                }
//                
//            }
//        }
//        
//        if (error != nil) {
//            println(error)
//        }
//        
//    }
    
}
