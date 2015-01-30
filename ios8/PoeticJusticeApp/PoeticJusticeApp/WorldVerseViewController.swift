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
                    NetOpers.sharedInstance.appserver_hostname! + "/v/users/id=\(at.verse_id)", load_players)
            }
            
        }
    }
    

    @IBAction func onJoin(sender: AnyObject) {
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
                
                println(jsonResult)
                
                if let players = jsonResult["verse_users"] as? NSArray{
                    
                    self.players.removeAll()
                    
                    for player in players{
                        var u = User(userData:player as NSDictionary)
                        self.players.append(u)
                    }
                    
                    println(self.players)
                    
                    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
                        dispatch_async(dispatch_get_main_queue(),{
                            
//                            self.playerTable.reloadData()
                            
                            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                        })
                    })
                    
                }
                
            }
        }
        
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Players"
    }
    
    func tableView(tableView : UITableView, numberOfRowsInSection section : Int) -> Int {
        if let users = self.user_ids{
            return users.count
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell : UITableViewCell = self.playerTable.dequeueReusableCellWithIdentifier("cell") as UITableViewCell
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        println(indexPath)
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
