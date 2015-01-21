//
//  FriendsViewController.swift
//  PoeticJusticeApp
//
//  Created by Larry Johnson on 1/20/15.
//  Copyright (c) 2015 Miga Collabs. All rights reserved.
//

import UIKit

class FriendsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var myTableView: UITableView!
    
    var items = ["larry@gerijopa.com", "mat@miga.me", "doran@miga.me"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Friends"
        
        self.myTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier : "cell")
        self.myTableView.dataSource = self
        
        println(items)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView : UITableView, numberOfRowsInSection section : Int) -> Int {
        return items.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell : UITableViewCell = self.myTableView.dequeueReusableCellWithIdentifier("cell") as UITableViewCell
        cell.textLabel?.text = self.items[indexPath.row]
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