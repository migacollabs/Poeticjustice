//
//  SecondViewController.swift
//  PoeticJusticeApp
//
//  Created by Larry Johnson on 1/21/15.
//  Copyright (c) 2015 Miga Col.Labs. All rights reserved.
//

import Foundation
import iAd

class Friend {
    let friend_data: NSDictionary
    
    init(rec:NSDictionary){
        self.friend_data = rec
    }
    
    var src: AnyObject? {
        get {
            if let x = self.friend_data["src"] as? String{
                return x
            }
            return nil
        }
    }
    
    var friend_id: AnyObject? {
        get {
            if let x = self.friend_data["friend_id"] as? Int{
                return x
            }
            return nil
        }
    }
    
    var email_address: AnyObject? {
        get {
            if let x = self.friend_data["email_address"] as? String{
                return x
            }
            return nil
        }
    }
    
    var user_name: AnyObject? {
        get {
            if let x = self.friend_data["user_name"] as? String{
                return x
            }
            return nil
        }
    }
    
    var approved: AnyObject? {
        get {
            if let x = self.friend_data["approved"] as? Bool{
                return x
            }
            return nil
        }
    }
    
    var display_name : AnyObject? {
        /*
        if src is 'me' then show whether my
        friend is approved or not.
        
        if src is 'them' then show whether i've
        approved them or not.
        */
        
        if let s = self.friend_data["src"] as? String {
            if ((s)=="me") {
                if let x = self.friend_data["approved"] as? Bool{
                    if (x) {
                        return email_address
                    } else {
                        if let e = email_address as? String {
                            return "* " + e
                        } else {
                            return user_name
                        }
                    }
                }
            } else if ((s)=="them") {
                if let x = self.friend_data["approved"] as? Bool{
                    if (x) {
                        return email_address
                    } else {
                        if let e = email_address as? String {
                            return "? " + e
                        } else {
                            return user_name
                        }
                    }
                }
            }
        }
        
        return email_address
    }
}

import UIKit

class FriendsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ADBannerViewDelegate {
    
    @IBOutlet var myTableView: UITableView!
    
    var friends : [Friend] = []
    var lastTabbed : NSDate?
    var iAdBanner: ADBannerView?
    
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
        self.iAdBanner?.delegate = self
        self.iAdBanner?.frame = CGRectMake(0,screen_height-98, 0, 0)
        if let adb = self.iAdBanner{
            self.view.addSubview(adb)
        }
        
        if (NetOpers.sharedInstance.userId>0) {
            
            var refresh : Bool = false
            
            if (lastTabbed==nil) {
                refresh = true
            } else {
                var elapsedTime = NSDate().timeIntervalSinceDate(lastTabbed!)
                refresh = (elapsedTime>NSTimeInterval(10.0))
            }
            
            if (refresh) {
                var uId : String = String(NetOpers.sharedInstance.userId!)
                NetOpers.sharedInstance.get(NetOpers.sharedInstance.appserver_hostname! + "/u/user-friends?user_id=" + uId, loadFriends)
                lastTabbed = NSDate()
            }
            
            updateUserLabel()
            
        }
    }
    
    override func viewWillDisappear(animated: Bool){
        self.iAdBanner?.delegate = nil
        self.iAdBanner?.removeFromSuperview()
    }
    
    func show_alert(title:String, message:String, controller_title:String){
        // TODO: this shows a warning "Presenting view controllers on detached view controllers is discouraged"
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: controller_title, style: UIAlertActionStyle.Default,handler: nil))
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func delete_friend(friend : Friend?) {
        var params = Dictionary<String,AnyObject>()
        params["friend_id"]=friend?.friend_id
        params["user_id"]=NetOpers.sharedInstance.userId
        
        NetOpers.sharedInstance.post(NetOpers.sharedInstance.appserver_hostname! + "/u/removefriend", params: params, loadFriends)
    }
    
    @IBAction func removeFriends(sender: AnyObject) {
        if ((removeFriend) != nil) {
            delete_friend(removeFriend!)
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Friends"
    }
    
    func updateUserLabel() {
        if let un = NetOpers.sharedInstance.user?.user_name as? String {
            if let us = NetOpers.sharedInstance.user?.user_score as? Int {
                self.userLabel.text = un + " // " + String(us) + " points"
            }
        } else {
            self.userLabel.text = "You are not signed in"
        }
    }
    
    func loadFriends(data: NSData?, response: NSURLResponse?, error: NSError?) {
        let httpResponse = response as NSHTTPURLResponse
        if httpResponse.statusCode == 200 {
            if data != nil {
                
                println("friend")
                println(data)
                
                let jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(
                    data!, options: NSJSONReadingOptions.MutableContainers,
                    error: nil) as NSDictionary
                
                if let results = jsonResult["results"] as? NSArray{
                    
                    self.friends.removeAll()
                    
                    for friend in results {
                        
                        var f = Friend(rec:friend as NSDictionary)
                        self.friends.append(f)
                        
                    }
                    
                    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
                        dispatch_async(dispatch_get_main_queue(),{
                            self.myTableView.reloadData()
                            
                            // TODO: maybe make the badge value friend request counts and update
                            // the name of the badge to the total count.  for example the
                            // the name could '7 Friends' with a badge of '2' to show
                            // the user has 7 friends and 2 friend requests
                            self.navigationController?.tabBarItem.badgeValue = String(self.friends.count)
                            
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
        params["user_id"]=NetOpers.sharedInstance.userId
        params["friend_email_address"]=frEmailAddress
        
        NetOpers.sharedInstance.post(NetOpers.sharedInstance.appserver_hostname! + "/u/addfriend", params: params, loadFriends)
    }
    
    @IBOutlet var friendEmailAddress: UITextField!
    
    @IBAction func addFriend(sender: AnyObject) {
        if (!self.friendEmailAddress.text.isEmpty) {
            if (isValidEmail(self.friendEmailAddress.text)) {
                add_friend(self.friendEmailAddress.text)
            } else {
                show_alert("Invalid email address", message: "Please enter a valid email address", controller_title:"Ok")
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
        if let f = self.friends[indexPath.row] as Friend? {
            if let d = f.display_name as? String {
                cell.textLabel?.text = d
            }
        }
        return cell
    }
    
    var removeFriend : Friend?
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        println("clicked " + String(indexPath.row))
        if let friend = self.friends[indexPath.row] as Friend? {
            removeFriend = friend
        }
        
        var cell : UITableViewCell = self.myTableView.dequeueReusableCellWithIdentifier("cell") as UITableViewCell
        
        if let f = self.friends[indexPath.row] as Friend? {
            if let a = f.approved as? Bool {
                if a==false {
                    
                    if let s = f.src as? String {
                        if s=="them" {
                            let name = f.email_address as? String
                            
                            let friendController = UIAlertController(title: "Confirm Friend", message: "Is " + name! + " your friend?", preferredStyle: UIAlertControllerStyle.ActionSheet)
                            
                            let noAction = UIAlertAction(title: "No", style: .Default, handler: {
                                (alert: UIAlertAction!) -> Void in
                                // delete friend
                                self.delete_friend(f)
                            })
                            let yesAction = UIAlertAction(title: "Yes", style: .Default, handler: {
                                (alert: UIAlertAction!) -> Void in
                                println("Is a friend!")
                                self.add_friend(f.email_address as? String)
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
        }
    }
    
    @IBAction func refreshView(sender: AnyObject) {
        viewWillAppear(true)
    }
    
    // MARK: - Ad Banner
    
    func appdelegate () -> AppDelegate{
        return UIApplication.sharedApplication().delegate as AppDelegate
    }
    
    func bannerViewWillLoadAd(banner: ADBannerView!) {
        println("bannerViewWillLoadAd called")
    }
    
    func bannerViewDidLoadAd(banner: ADBannerView!) {
        println("bannerViewDidLoadAd called")
        //UIView.beginAnimations(nil, context:nil)
        //UIView.setAnimationDuration(1)
        //self.iAdBanner?.alpha = 1
        self.iAdBanner?.hidden = false
        //UIView.commitAnimations()
        
    }
    
    func bannerViewActionDidFinish(banner: ADBannerView!) {
        println("bannerViewACtionDidFinish called")
    }
    
    func bannerViewActionShouldBegin(banner: ADBannerView!, willLeaveApplication willLeave: Bool) -> Bool{
        return true
    }
    
    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
        println("bannerView didFailToReceiveAdWithError called")
        self.iAdBanner?.hidden = true
    }
    
}