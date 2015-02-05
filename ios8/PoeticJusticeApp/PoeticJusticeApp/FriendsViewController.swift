//
//  SecondViewController.swift
//  PoeticJusticeApp
//
//  Created by Larry Johnson on 1/21/15.
//  Copyright (c) 2015 Miga Col.Labs. All rights reserved.
//

import Foundation
import iAd

struct FriendRec {
    var src : String = ""
    var friend_id : Int = -1
    var email_address : String = ""
    var user_name : String = ""
    var approved : Bool = false
}

import UIKit

class FriendsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var myTableView: UITableView!
    
    var friends : [FriendRec] = []
    var lastTabbed : NSDate?
    var iAdBanner: ADBannerView?
    
    @IBOutlet var addButton: UIButton!
    @IBOutlet var removeButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Friends"
        
        self.myTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier : "cell")
        self.myTableView.dataSource = self
        self.myTableView.delegate = self
        
    }
    
    override func viewWillAppear(animated : Bool) {
        
        // set up adbanner
        var screen_height = UIScreen.mainScreen().bounds.height
        self.iAdBanner = self.appdelegate().iAdBanner
        //self.iAdBanner?.delegate = self
        self.iAdBanner?.frame = CGRectMake(0,screen_height-98, 0, 0)
        if let adb = self.iAdBanner{
            self.view.addSubview(adb)
        }
        
        if (NetOpers.sharedInstance.user.is_logged_in()) {
            
            var refresh : Bool = false
            
            if (lastTabbed==nil) {
                refresh = true
            } else {
                var elapsedTime = NSDate().timeIntervalSinceDate(lastTabbed!)
                refresh = (elapsedTime>NSTimeInterval(10.0))
            }
            
            if (refresh) {
                println("refreshing friends")
                var uId : String = String(NetOpers.sharedInstance.user.id)
                NetOpers.sharedInstance.get(NetOpers.sharedInstance.appserver_hostname! + "/u/user-friends", loadFriends)
                lastTabbed = NSDate()
            }
            
        }
        
        updateUserLabel()
        
        is_busy = false
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
    var is_busy : Bool = false
    
    override func viewWillDisappear(animated: Bool){
//        self.iAdBanner?.delegate = nil
//        self.iAdBanner?.removeFromSuperview()
    }
    
    func show_alert(title:String, message:String, controller_title:String){
        // TODO: this shows a warning "Presenting view controllers on detached view controllers is discouraged"
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: controller_title, style: UIAlertActionStyle.Default,handler: nil))
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func delete_friend(fr : FriendRec?) {
    
        var params = Dictionary<String,AnyObject>()
        params["friend_id"]=fr?.friend_id
        params["user_id"]=NetOpers.sharedInstance.user.id
        
        NetOpers.sharedInstance.post(NetOpers.sharedInstance.appserver_hostname! + "/u/removefriend", params: params, loadFriends)
    
    }
    
    @IBAction func removeFriends(sender: AnyObject) {
        if ((removeFriend) != nil) {
            // TODO: confirmation dialog here
            if (!is_busy) {
                is_busy = true
                if (NetOpers.sharedInstance.user.is_logged_in()) {
                    delete_friend(removeFriend!)
                }
            }
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Friends"
    }
    
    func updateUserLabel() {
        
        var user = NetOpers.sharedInstance.user
        if (user.is_logged_in()) {
            self.userLabel.text = "Level " + String(user.level) + " / " + String(user.user_score) + " points"
        } else {
            self.userLabel.text = "You are not signed in"
        }
        
    }
    
    func loadFriends(data: NSData?, response: NSURLResponse?, error: NSError?) {
        println("loading friends")
        let httpResponse = response as NSHTTPURLResponse
        if httpResponse.statusCode == 200 {
            if data != nil {
                
                let jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(
                    data!, options: NSJSONReadingOptions.MutableContainers,
                    error: nil) as NSDictionary
                
                if let results = jsonResult["results"] as? NSArray{
                    
                    println("updating friends")
                    
                    self.friends.removeAll()
                    
                    for f in results {
                        
                        /*
                        var src : String = ""
                        var friend_id : Int = -1
                        var email_address : String = ""
                        var user_name : String = ""
                        var approved : String = ""
                        */
                        
                        var fr = FriendRec()
                        
                        if let src = f["src"] as? String {
                            fr.src = src
                        }
                        
                        if let fid = f["friend_id"] as? Int {
                            fr.friend_id = fid
                        }
                        
                        if let ea = f["email_address"] as? String {
                            fr.email_address = ea
                        }
                        
                        if let un = f["user_name"] as? String {
                            fr.user_name = un
                        }
                        
                        if let ap = f["approved"] as? Bool {
                            fr.approved = ap
                        }

                        self.friends.append(fr)
                        
                    }
                    
                    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
                        dispatch_async(dispatch_get_main_queue(),{
                            self.myTableView.reloadData()
                            
                            // TODO: maybe make the badge value friend request counts and update
                            // the name of the badge to the total count.  for example the
                            // the name could '7 Friends' with a badge of '2' to show
                            // the user has 7 friends and 2 friend requests
                            self.navigationController?.tabBarItem.badgeValue = String(self.friends.count)
                            
                            self.is_busy = false
                            
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
    
    func isValidEmail(testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
        let range = testStr.rangeOfString(emailRegEx, options:.RegularExpressionSearch)
        let result = range != nil ? true : false
        return result
    }
    
    func add_friend(frEmailAddress : String?) {
        
        var params = Dictionary<String,AnyObject>()
        params["user_id"]=NetOpers.sharedInstance.user.id
        params["friend_email_address"]=frEmailAddress
        
        NetOpers.sharedInstance.post(NetOpers.sharedInstance.appserver_hostname! + "/u/addfriend", params: params, loadFriends)
    
    }
    
    @IBOutlet var friendEmailAddress: UITextField!
    
    @IBAction func addFriend(sender: AnyObject) {
        if (!self.friendEmailAddress.text.isEmpty) {
            
            if (!is_busy) {
                is_busy = true
             
                if (isValidEmail(self.friendEmailAddress.text)) {
                    if (NetOpers.sharedInstance.user.is_logged_in()) {
                        add_friend(self.friendEmailAddress.text)
                    }
                } else {
                    show_alert("Invalid email address", message: "Please enter a valid email address", controller_title:"Ok")
                    is_busy = false
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                }
                
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView : UITableView, numberOfRowsInSection section : Int) -> Int {
        return friends.count
    }
    
    @IBOutlet var userLabel: UILabel!
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell : UITableViewCell = self.myTableView.dequeueReusableCellWithIdentifier("cell") as UITableViewCell
        if let fr = self.friends[indexPath.row] as FriendRec? {
            cell.textLabel?.text = get_display_name(fr)
        }
        return cell
    }
    
    func get_display_name(fr : FriendRec) -> String {
        if fr.src=="me" {
            if fr.approved {
                return fr.email_address
            } else {
                return "* " + fr.email_address
            }
        } else if fr.src=="them" {
            if fr.approved {
                return fr.email_address
            } else {
                return "? " + fr.email_address
            }
        }
        return fr.user_name
    }

    var removeFriend : FriendRec?

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        println("clicked " + String(indexPath.row))
        if let friend = self.friends[indexPath.row] as FriendRec? {
            removeFriend = friend
        }

        var cell : UITableViewCell = self.myTableView.dequeueReusableCellWithIdentifier("cell") as UITableViewCell

        if let f = self.friends[indexPath.row] as FriendRec? {
            
            if !f.approved {
                if f.src=="them" {
                    var name : String = f.email_address
                    
                    let friendController = UIAlertController(title: "Confirm Friend", message: "Is " + name + " your friend?", preferredStyle: UIAlertControllerStyle.ActionSheet)
                    
                    let noAction = UIAlertAction(title: "No", style: .Default, handler: {
                        (alert: UIAlertAction!) -> Void in
                        // delete friend
                        self.delete_friend(f)
                    })
                    let yesAction = UIAlertAction(title: "Yes", style: .Default, handler: {
                        (alert: UIAlertAction!) -> Void in
                        println("Is a friend!")
                        self.add_friend(f.email_address)
                    })
                    let notSureAction = UIAlertAction(title: "Not Sure", style: .Default, handler: {
                        (alert: UIAlertAction!) -> Void in
                        // do nothing
                    })
                    
                    friendController.addAction(noAction)
                    friendController.addAction(yesAction)
                    friendController.addAction(notSureAction)
                    
                    self.presentViewController(friendController, animated: true, completion: nil)
                }
            }
        }
    }
    
    @IBAction func refreshView(sender: AnyObject) {
        viewWillAppear(true)
    }
    
    // MARK: - Ad Banner
    
    func appdelegate () -> AppDelegate{
        return UIApplication.sharedApplication().delegate as AppDelegate
    }
    
}