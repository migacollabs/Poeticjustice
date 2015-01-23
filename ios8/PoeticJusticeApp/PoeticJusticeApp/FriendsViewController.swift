//
//  SecondViewController.swift
//  PoeticJusticeApp
//
//  Created by Larry Johnson on 1/21/15.
//  Copyright (c) 2015 Miga Col.Labs. All rights reserved.
//

import Foundation

class Friend {
    let friend_data: NSDictionary
    
    init(rec:NSDictionary){
        self.friend_data = rec
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
        if let x = self.friend_data["approved"] as? Bool{
            return email_address
        } else {
            return user_name
        }
    }
}

import UIKit

class FriendsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var myTableView: UITableView!
    
    var friends : [Friend] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Manage Friends"
        
        self.myTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier : "cell")
        self.myTableView.dataSource = self
    }
    
    override func viewWillAppear(animated : Bool) {
        if (NetOpers.sharedInstance.userId>0) {
            var uId : String = String(NetOpers.sharedInstance.userId!)
            println("hitting url " + "/m/search/UserXUser/user_id=" + uId)
            NetOpers.sharedInstance.get(NetOpers.sharedInstance.appserver_hostname! + "/m/search/UserXUser/user_id=" + uId, loadFriends)
        }
    }
    
    func loadFriends(data: NSData?, response: NSURLResponse?, error: NSError?) {
        let httpResponse = response as NSHTTPURLResponse
        if httpResponse.statusCode == 200 {
            if data != nil {
                let jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(
                    data!, options: NSJSONReadingOptions.MutableContainers,
                    error: nil) as NSDictionary
                
                if let len = jsonResult["length"] as? Int{
                    if let results = jsonResult["results"] as? NSArray{
                        for friend in results {
                            
                            var f = Friend(rec:friend as NSDictionary)
                            self.friends.append(f)
                            
                        }
                    }
                }
            }
        }
        if (error != nil) {
            println(error)
        }
//        println(response)
//        println(data);
//        println(error);
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
    func isValidEmail(testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
        let range = testStr.rangeOfString(emailRegEx, options:.RegularExpressionSearch)
        let result = range != nil ? true : false
        return result
    }
    
    func updateFriendTable(data: NSData?, response: NSURLResponse?, error: NSError?) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
    var newFriendUserId : Int!
    
    func checkFriend(data: NSData?, response: NSURLResponse?, error: NSError?) {
        if let httpResponse = response as? NSHTTPURLResponse {
            if httpResponse.statusCode == 200 {
                
                if data != nil {
                    
                    var json: JSON? = nil
                    
                    if let jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(
                        data!, options: NSJSONReadingOptions.MutableContainers,
                        error: nil) as? NSDictionary {
                            
                        if let results = jsonResult["results"] as? NSDictionary{
                                
                            if let y = results["id"] as? Int{
                                self.newFriendUserId = y
                                println(self.newFriendUserId)
                            }
                        }
                    }
                }
            }
        }
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
    @IBOutlet var friendEmailAddress: UITextField!
    
    @IBAction func addFriend(sender: AnyObject) {
        newFriendUserId = -1
        if (!self.friendEmailAddress.text.isEmpty) {
            if (isValidEmail(self.friendEmailAddress.text)) {
                
                NetOpers.sharedInstance.get(NetOpers.sharedInstance.appserver_hostname! + "/m/search/User/email_address=" + self.friendEmailAddress.text, checkFriend)
                
                if (newFriendUserId>0) {
                    var params : Dictionary<String, AnyObject> = Dictionary<String, AnyObject>()
                    params["user_id"]=NetOpers.sharedInstance.userId
                    params["friend_id"]=self.newFriendUserId
                    
                    NetOpers.sharedInstance.post(NetOpers.sharedInstance.appserver_hostname! + "/m/edit/UserXUser/", params: params, updateFriendTable)
                }
                
            } else {
                // TODO: popup error
            }
        }    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView : UITableView, numberOfRowsInSection section : Int) -> Int {
        return friends.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell : UITableViewCell = self.myTableView.dequeueReusableCellWithIdentifier("cell") as UITableViewCell
        if let f = self.friends[indexPath.row] as Friend? {
            if let d = f.display_name as? String {
                cell.textLabel?.text = d
            }
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //CODE TO BE RUN ON CELL TOUCH
        println("touched")
    }
    
    func addFriend(userId : Int) {
        
    }
    
    func findRandomFriends(count : Int) {
        
    }
}