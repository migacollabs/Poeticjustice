//
//  LeaderboardViewController.swift
//  PoeticJusticeApp
//
//  Created by Larry Johnson on 1/31/15.
//  Copyright (c) 2015 Miga Col.Labs. All rights reserved.
//

import UIKit

struct LeaderboardUserRec {
    var user_name : String = ""
    var user_score : Int = -1
    var user_id : Int = -1
}

class LeaderboardViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var leaderboard_users : [LeaderboardUserRec] = []
    @IBOutlet var myTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var refreshButton : UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Refresh, target: self, action: "refresh")
        self.navigationItem.rightBarButtonItem = refreshButton
        
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
    
    func refresh() {
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
                        
                        var lr : LeaderboardUserRec = LeaderboardUserRec()
                        
                        if let un = lu["user_name"] as? String {
                            lr.user_name = un
                        }

                        if let uid = lu["user_id"] as? Int {
                            lr.user_id = uid
                        }

                        if let us = lu["user_score"] as? Int {
                            lr.user_score = us
                        }
                        
                        println(lr.user_name)
                        
                        self.leaderboard_users.append(lr)
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
        return ""
    }
    
    func tableView(tableView : UITableView, numberOfRowsInSection section : Int) -> Int {
        return leaderboard_users.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell : UITableViewCell = self.myTableView.dequeueReusableCellWithIdentifier("cell") as UITableViewCell
        if let lur = self.leaderboard_users[indexPath.row] as LeaderboardUserRec? {

            cell.textLabel?.text = String(lur.user_score) + " - " + lur.user_name

            if (lur.user_id==NetOpers.sharedInstance.user.id) {
                cell.contentView.backgroundColor = UIColor.lightGrayColor()
            } else {
                cell.contentView.backgroundColor = UIColor.whiteColor()
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
