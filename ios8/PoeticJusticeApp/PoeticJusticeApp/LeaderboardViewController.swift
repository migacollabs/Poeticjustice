//
//  LeaderboardViewController.swift
//  PoeticJusticeApp
//
//  Created by Larry Johnson on 1/31/15.
//  Copyright (c) 2015 Miga Col.Labs. All rights reserved.
//

import UIKit

class LeaderboardUser {
    let user_data: NSDictionary
    
    init(rec:NSDictionary){
        self.user_data = rec
    }
    
    var user_name: AnyObject? {
        get {
            if let x = self.user_data["user_name"] as? String{
                return x
            }
            return nil
        }
    }
    
    var user_score: AnyObject? {
        get {
            if let x = self.user_data["user_score"] as? Int{
                return x
            }
            return nil
        }
    }
    
    var user_id: AnyObject? {
        get {
            if let x = self.user_data["user_id"] as? Int{
                return x
            }
            return nil
        }
    }
}

class LeaderboardViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var leaderboard_users : [LeaderboardUser] = []
    @IBOutlet var myTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Leaderboard"

        // Do any additional setup after loading the view.
        self.myTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier : "cell")
        self.myTableView.dataSource = self
        self.myTableView.delegate = self
    }
    
    var lastTabbed : NSDate?
    
    override func viewWillAppear(animated : Bool) {
        
        var refresh : Bool = false
        
        if (lastTabbed==nil) {
            refresh = true
        } else {
            var elapsedTime = NSDate().timeIntervalSinceDate(lastTabbed!)
            refresh = (elapsedTime>NSTimeInterval(10.0))
        }
        
        if (refresh) {
            println("hitting leaderboard")
            NetOpers.sharedInstance.get(NetOpers.sharedInstance.appserver_hostname! + "/u/leaderboard", loadLeaderboard)
            lastTabbed = NSDate()
        }
        
    
    }
    
    @IBAction func refreshView(sender: AnyObject) {
        viewWillAppear(true)
    }
    
    func loadLeaderboard(data: NSData?, response: NSURLResponse?, error: NSError?) {
        let httpResponse = response as NSHTTPURLResponse
        if httpResponse.statusCode == 200 {
            if data != nil {
                
                let jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(
                    data!, options: NSJSONReadingOptions.MutableContainers,
                    error: nil) as NSDictionary
                
                if let results = jsonResult["results"] as? NSArray{
                    
                    self.leaderboard_users.removeAll()
                    
                    for lu in results {
                        var user = LeaderboardUser(rec:lu as NSDictionary)
                        self.leaderboard_users.append(user)
                    }
                    
                    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
                        dispatch_async(dispatch_get_main_queue(),{
                            self.myTableView.reloadData()
                            
                            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                        })
                    })
                }
                
            }
        }
        
        if (error != nil) {
            println(error)
        }
        
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Leaderboard"
    }
    
    func tableView(tableView : UITableView, numberOfRowsInSection section : Int) -> Int {
        return leaderboard_users.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell : UITableViewCell = self.myTableView.dequeueReusableCellWithIdentifier("cell") as UITableViewCell
        if let u = self.leaderboard_users[indexPath.row] as LeaderboardUser? {
            if let d = u.user_name as? String {
                cell.textLabel?.text = String(u.user_score! as Int) + " - " + d
                
                if let noid = NetOpers.sharedInstance.userId as Int? {
                    if ((u.user_id as Int)==noid) {
                        cell.contentView.backgroundColor = UIColor.yellowColor()
                    }
                } else {
                    cell.contentView.backgroundColor = UIColor.whiteColor()
                }
                
            }
        }
        return cell
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
