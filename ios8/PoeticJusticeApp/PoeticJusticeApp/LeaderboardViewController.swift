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
    var avatar_name : String = "avatar_default.png"
    var user_id : Int = -1
    var num_favorited_lines : Int = 0
}

class LeaderboardTableViewCell: UITableViewCell {
    
    
    @IBOutlet var lineNum: UILabel!
    @IBOutlet var userScore: UILabel!
    @IBOutlet var numFavs: UILabel!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var avatarImage: UIImageView!
    @IBOutlet weak var levelImage : UIImageView!
    
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
    
    private var refreshButton : UIBarButtonItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Global Leaderboard"
        
        // register our custom cell
        self.myTableView.registerNib(UINib(nibName: "LeaderboardTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")

        // Do any additional setup after loading the view.
        self.myTableView.dataSource = self
        self.myTableView.delegate = self
        
        self.myTableView.backgroundColor = UIColor.clearColor()
    }
    
    private var filterByFriends : Bool = false
    
    override func viewWillAppear(animated : Bool) {
        
        if (NetOpers.sharedInstance.user.is_logged_in()) {
            if (filterByFriends) {
                refreshButton = UIBarButtonItem(title: "Global", style: UIBarButtonItemStyle.Plain, target: self, action: "refresh")
            } else {
                refreshButton = UIBarButtonItem(title: "Friends", style: UIBarButtonItemStyle.Plain, target: self, action: "refresh")
            }
        } else {
            refreshButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Refresh, target: self, action: "refresh")
        }
        
        self.navigationItem.rightBarButtonItem = refreshButton
        
        var params : String = ""
        
        if (filterByFriends) {
            params = "?type=Friends&user_id=" + String(NetOpers.sharedInstance.user.id)
        } else {
            params = "?type=Global"
        }
        
        println("hitting leaderboard at \(params)")
        
        NetOpers.sharedInstance.get(NetOpers.sharedInstance.appserver_hostname! + "/u/leaderboard" + params, loadLeaderboard)
    
    }
    
    func refresh() {
        
        if (NetOpers.sharedInstance.user.is_logged_in()) {
            filterByFriends = !filterByFriends
            
            if (filterByFriends) {
                refreshButton?.title = "Global"
                title = "Friends Leaderboard"
            } else {
                title = "Global Leaderboard"
            }
        }
        
        viewWillAppear(true)
    }
    
    func loadLeaderboard(data: NSData?, response: NSURLResponse?, error: NSError?) {
        if let httpResponse = response as? NSHTTPURLResponse {
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
                            
                            if let n = lu["num_of_favorited_lines"] as? Int {
                                lr.num_favorited_lines = n
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
            } else {
                self.show_alert("\(httpResponse.statusCode) Oops", message: "There was a problem loading the leaderboard.  Please try again.", controller_title:"Ok")
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            }
        }
        
        if (error != nil) {
            if let e = error?.localizedDescription {
                self.show_alert("Unable to load leaderboard", message: e, controller_title:"Ok")
            } else {
                self.show_alert("Network error", message: "Unable to load leaderboard", controller_title:"Ok")
            }
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
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
                
                lc.lineNum.text = String(indexPath.row+1) + "."
                lc.userScore.text = String(format: "x%03d", lur.user_score)
                lc.numFavs.text = String(format: "x%03d", lur.num_favorited_lines)
                lc.levelImage.image = UIImage(named: "lvl_" + String(lur.level) + ".png")
                lc.avatarImage.image = UIImage(named: lur.avatar_name)
                lc.userName.text = lur.user_name
                
                if (lur.user_id==NetOpers.sharedInstance.user.id) {
                    // lc.userName.font = UIFont.boldSystemFontOfSize(13.0)
                    lc.backgroundColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.10)
                } else {
                    lc.backgroundColor = UIColor.whiteColor()
                }
            }
        }
        
        cell.contentView.backgroundColor = UIColor.clearColor()
        cell.contentView.alpha = 0.0
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        return 78.0
    }
    
    func show_alert(title:String, message:String, controller_title:String){
        dispatch_async(dispatch_get_main_queue()) {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: controller_title, style: UIAlertActionStyle.Default,handler: nil))
            
            self.presentViewController(alertController, animated: true, completion: nil)
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
