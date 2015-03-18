//
//  SecondViewController.swift
//  PoeticJusticeApp
//
//  Created by Larry Johnson on 1/21/15.
//  Copyright (c) 2015 Miga Col.Labs. All rights reserved.
//

import Foundation
import iAd
import UIKit

struct FriendRec {
    var src : String = ""
    var friend_id : Int = -1
    var email_address : String = ""
    var user_name : String = ""
    var approved : Bool = false
    var user_score: Int = -1
    var level: Int = -1
    var num_favs : Int = 0
    var user_prefs: String = ""
    var avatar_name: String = "avatar_default.png"
}

class FriendsHelper {
    
    class var sharedInstance: FriendsHelper {
        struct Static {
            static let instance = FriendsHelper();
        }
        return Static.instance
    }
    
    func convertToFriendRecs(results : NSArray) -> [FriendRec] {
        var friends : [FriendRec] = []
        for f in results {
            
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
            
            if let score = f["user_score"] as? Int {
                fr.user_score = score
            }
            
            if let nf = f["num_of_favorited_lines"] as? Int {
                fr.num_favs = nf
            }
            
            if let up = f["user_prefs"] as? String {
                fr.user_prefs = up
                
                if !up.isEmpty{
                    let upData = (up as NSString).dataUsingEncoding(NSUTF8StringEncoding)
                    let userPrefs: NSDictionary = NSJSONSerialization.JSONObjectWithData(
                        upData!, options: NSJSONReadingOptions.MutableContainers,
                        error: nil) as NSDictionary
                    if let avn = userPrefs["avatar_name"] as? String{
                        fr.avatar_name = avn
                    }
                }
                
            }
            
            if let lvl = f["level"] as? Int{
                fr.level = lvl
            }
            
            friends.append(fr)
        }
        
        return friends
    }
}

class FriendsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    @IBOutlet var myTableView: UITableView!
    
    var friends : [FriendRec] = []
    var lastTabbed : NSDate?
    // var iAdBanner: ADBannerView?
    
    @IBOutlet var addButton: UIButton!
    @IBOutlet var removeButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.myTableView.backgroundColor = UIColor.clearColor()
        
        var refreshButton : UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Refresh, target: self, action: "refresh")
        self.navigationItem.rightBarButtonItem = refreshButton
        
        title = "Friends"
        
//        self.myTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier : "cell")
        self.myTableView.registerNib(UINib(nibName: "FriendsTableViewCell", bundle: nil), forCellReuseIdentifier: "FriendCell")
        self.myTableView.dataSource = self
        self.myTableView.delegate = self
        self.friendEmailAddress.delegate = self
        
    }
    
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        self.view.endEditing(true);
        return false;
    }
    
    override func viewWillAppear(animated : Bool) {
        
        // set up adbanner
//        var screen_height = UIScreen.mainScreen().bounds.height
//        self.iAdBanner = self.appdelegate().iAdBanner
//        //self.iAdBanner?.delegate = self
//        self.iAdBanner?.frame = CGRectMake(0,screen_height-98, 0, 0)
//        if let adb = self.iAdBanner{
//            // self.view.addSubview(adb)
//        }
        
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
            
        } else {
            self.show_alert("You are not signed in", message: "Please sign in before playing with friends.", controller_title: "Ok")
        }
        
        is_busy = false
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
    var is_busy : Bool = false
    
    override func viewWillDisappear(animated: Bool){
//        self.iAdBanner?.delegate = nil
//        self.iAdBanner?.removeFromSuperview()
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
        return ""
    }
    
    func loadFriends(data: NSData?, response: NSURLResponse?, error: NSError?) {
        println("loading friends")
        if let httpResponse = response as? NSHTTPURLResponse {
            if httpResponse.statusCode == 200 {
                if data != nil {
                    
                    let jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(
                        data!, options: NSJSONReadingOptions.MutableContainers,
                        error: nil) as NSDictionary
                    if let results = jsonResult["results"] as? NSArray {
                            friends = FriendsHelper.sharedInstance.convertToFriendRecs(results)
                    }
                    
                    dispatch_async(dispatch_get_main_queue(),{
                        
                        self.friendEmailAddress.resignFirstResponder()
                        
                        self.myTableView.reloadData()
                        
                        var resetField : Bool = false
                        var currentText = self.friendEmailAddress.text
                        
                        if (!currentText.isEmpty) {
                            currentText = currentText.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
                        }
                        
                        var badgeCount : Int = 0
                        for fr : FriendRec in self.friends {
                            if (!fr.approved && fr.src=="them") {
                                badgeCount += 1
                            }
                            
                            if (currentText==fr.email_address) {
                                resetField = true
                            }
                        }
                        
                        if (resetField) {
                            self.friendEmailAddress.text = ""
                        }
                        
                        if (badgeCount>0) {
                            self.navigationController?.tabBarItem.badgeValue = String(badgeCount)
                        } else {
                            self.navigationController?.tabBarItem.badgeValue = nil
                        }
                        
                        self.is_busy = false
                        
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    })
                    
                }
            } else {
                self.show_alert("\(httpResponse.statusCode) Oops", message: "There was a problem loading friends.  Please try again.", controller_title:"Ok")
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            }
        }
        
        if (error != nil) {
            if let e = error?.localizedDescription {
                self.show_alert("Unable to load friends", message: e, controller_title:"Ok")
            } else {
                self.show_alert("Network error", message: "Unable to load friends", controller_title:"Ok")
            }
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
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
        var frEmail : String = self.friendEmailAddress.text
        if (!frEmail.isEmpty) {
            
            frEmail = frEmail.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            
            if (!is_busy) {
                is_busy = true
                
                if (isValidEmail(frEmail)) {
                    
                    var exists : Bool = false
                    
                    for fr in self.friends {
                        if (fr.email_address==frEmail) {
                            exists = true
                            is_busy = false
                            break
                        }
                    }
                    
                    if (!exists && NetOpers.sharedInstance.user.is_logged_in()) {
                        if (NetOpers.sharedInstance.user.email_address != frEmail) {
                            add_friend(frEmail)
                        } else {
                            self.show_alert("Invalid email address", message: "Please enter a valid email address that is not your own", controller_title:"Ok")
                            is_busy = false
                            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                        }
                    }
                } else {
                    self.show_alert("Invalid email address", message: "Please enter a valid email address", controller_title:"Ok")
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
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let dqd = tableView.dequeueReusableCellWithIdentifier("FriendCell", forIndexPath: indexPath) as UITableViewCell
        
        if let cell = dqd as? FriendsTableViewCell{
            if let fr = self.friends[indexPath.row] as FriendRec? {
                
                // for now, hide information until friendship is confirmed
                if (isIncoming(fr)) {
                    cell.requestStatus.image = UIImage(named: "incoming.png")
                    cell.username.text = "Friend Request"
                    cell.username.textColor = UIColor.lightGrayColor()
                    cell.avatar.image = UIImage(named: "avatar_default.png")
                    cell.points.text = String(format: "x%03d", 0)
                    cell.favs.text = String(format: "x%03d", 0)
                    cell.level.image = UIImage(named: "lvl_1.png")
                } else if (isOutgoing(fr)) {
                    cell.requestStatus.image = UIImage(named: "outgoing.png")
                    cell.username.text = "Friend Request"
                    cell.username.textColor = UIColor.lightGrayColor()
                    cell.avatar.image = UIImage(named: "avatar_default.png")
                    cell.points.text = String(format: "x%03d", 0)
                    cell.favs.text = String(format: "x%03d", 0)
                    cell.level.image = UIImage(named: "lvl_1.png")
                } else {
                    cell.requestStatus.image = UIImage(named : "group.png")
                    cell.username.text = fr.user_name
                    cell.username.textColor = UIColor.blackColor()
                    cell.avatar.image = UIImage(named: fr.avatar_name)
                    cell.points.text = String(format: "x%03d", fr.user_score)
                    cell.favs.text = String(format: "x%03d", fr.num_favs)
                    cell.level.image = UIImage(named: "lvl_" + String(fr.level) + ".png")
                }
                
                cell.emailAddress.text = fr.email_address
                
            }
        }
        
        dqd.backgroundColor = UIColor.clearColor()
        
        var customView = UIView()
        // customView.backgroundColor = GameStateColors.LightBlueT
        customView.backgroundColor = UIColor.clearColor()
        dqd.selectedBackgroundView = customView
        
        return dqd
    }
    
//    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
//        return 100.0
//    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            println("commitEditingStyle called")

            if let friend = self.friends[indexPath.row] as FriendRec? {
                
                removeFriend = friend
                
                if (!is_busy) {
                    is_busy = true
                    if (NetOpers.sharedInstance.user.is_logged_in()) {
                        
                        delete_friend(removeFriend!)
                        
                        //tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                    }
                }
                
            }
        }
    }
    
    
    func isOutgoing(fr : FriendRec) -> Bool {
        if fr.src=="me" {
            if !fr.approved {
                return true
            }
        }
        return false
    }
    
    func isIncoming(fr : FriendRec) -> Bool {
        if fr.src=="them" {
            if !fr.approved {
                return true
            }
        }
        return false
    }

    var removeFriend : FriendRec?

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        println("clicked " + String(indexPath.row))
        if let friend = self.friends[indexPath.row] as FriendRec? {
            removeFriend = friend
        }

        var cell : FriendsTableViewCell = self.myTableView.dequeueReusableCellWithIdentifier("FriendCell") as FriendsTableViewCell

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
    
    func refresh() {
        viewWillAppear(true)
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        return 78.0
    }
    
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