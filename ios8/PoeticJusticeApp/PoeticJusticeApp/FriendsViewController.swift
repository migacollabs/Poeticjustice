//
//  SecondViewController.swift
//  PoeticJusticeApp
//
//  Created by Larry Johnson on 1/21/15.
//  Copyright (c) 2015 Miga Col.Labs. All rights reserved.
//

import UIKit

class FriendsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var myTableView: UITableView!
    
    var items : [Int] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
                
                if let results = jsonResult["results"] as? NSArray{
                    for friend in results{
                        println(friend) // TODO: how to get the "friend_id"?
                    }
                }
                
            }
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
        return items.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell : UITableViewCell = self.myTableView.dequeueReusableCellWithIdentifier("cell") as UITableViewCell
        cell.textLabel?.text = String(self.items[indexPath.row])
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