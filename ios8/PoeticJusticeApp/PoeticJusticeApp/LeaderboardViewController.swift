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
    var level : Int = 1
    var avatar_name : String = "avatar_mexican_guy.png"
    var user_id : Int = -1
}

class LeaderboardTableViewCell: UITableViewCell {
    
    @IBOutlet weak var desc: UILabel!
    @IBOutlet weak var avatarImage: UIImageView!
    @IBOutlet weak var levelImage : UIImageView!
    @IBOutlet weak var userName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}

class LeaderboardViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var leaderboard_users : [LeaderboardUserRec] = []
    @IBOutlet var myTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // register our custom cell
        self.myTableView.registerNib(UINib(nibName: "LeaderboardTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
        
        var refreshButton : UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Refresh, target: self, action: "refresh")
        self.navigationItem.rightBarButtonItem = refreshButton
        
        title = "Leaderboard"

        // Do any additional setup after loading the view.
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
                        
                        if let a = lu["avatar_name"] as? String {
                            lr.avatar_name = a
                        }
                        
                        if let l = lu["level"] as? Int {
                            lr.level = l
                        }
                        
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
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell
        
        if let lc = cell as? LeaderboardTableViewCell{
            if let lur = self.leaderboard_users[indexPath.row] as LeaderboardUserRec? {
                
                lc.desc.text = String(indexPath.row+1) + ". " + String(lur.user_score) + " points";
                lc.levelImage.image = UIImage(named: "lvl_" + String(lur.level) + ".png")
                lc.avatarImage.image = UIImage(named: lur.avatar_name)
                lc.userName.text = lur.user_name
                
                if (lur.user_id==NetOpers.sharedInstance.user.id) {
                    // lc.userName.font = UIFont.boldSystemFontOfSize(13.0)
                    lc.backgroundColor = UIColor.lightGrayColor()
                } else {
                    lc.backgroundColor = UIColor.whiteColor()
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
