//
//  DetailViewController.swift
//  MividioCam2
//
//  Created by Mat Mathews on 12/20/14.
//  Copyright (c) 2014 Miga Collabs. All rights reserved.
//

import UIKit

struct PlayerLines{
    var userId = -1
    var userName = ""
    var line = ""
    var avatar = "avatar_default.png"
    var level = 1
}

class VerseHistoryDetailViewController: UIViewController, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var verseTitle: UILabel!
    @IBOutlet weak var verseText: UITextView!
    @IBOutlet weak var playersTable: UITableView!
    @IBOutlet weak var topicIconImage: UIImageView!
    
    var playerData: [PlayerLines] = []
    
    var detailItem: VerseHistoryRec? {
        didSet {
            // Might not have to do anything here
            ()
        }
    }
    
    func configureView() {
        println("configureView called")
        // Update the user interface for the detail item.
        if let vhr: VerseHistoryRec = self.detailItem {
            if let title = self.verseTitle{
                title.text = vhr.title
            }
            
        
                
            // sort asc because lines have pks that asc
            let sortedLinePos = Array(vhr.lines_recs.keys).sorted(<)
            
            for linePos in sortedLinePos{
                
                var lineRec = vhr.lines_recs[linePos]!
                
                var user_name = ""
                var level = 1
                var avatar = "avatar_default.png"
                
                if let pr = vhr.players[lineRec.player_id]{
                    user_name = pr.user_name
                    level = pr.level
                    avatar = pr.avatar_name
                }
                
                var pl = PlayerLines(userId: lineRec.player_id,
                    userName: user_name, line: lineRec.text, avatar: avatar, level:level)
                
                self.playerData.append(pl)
                
            }
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
//        self.load_verse()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: UITextFieldDelegate methods
    
    func textFieldDidBeginEditing(textField: UITextField!) {    //delegate method
        println("textFieldDidBeginEditing called")
    }
    
    func textFieldShouldEndEditing(textField: UITextField!) -> Bool {  //delegate method
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField!) -> Bool {   //delegate method
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: TableViewDataSource and Delegate methods
    
    func tableView(tableView : UITableView, numberOfRowsInSection section : Int) -> Int {
        return self.playerData.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell : PlayerLineTableViewCell = self.playersTable.dequeueReusableCellWithIdentifier("PlayerCell") as PlayerLineTableViewCell
        var playerLine = playerData[indexPath.row]
        cell.avatarImage.image = UIImage(named:playerLine.avatar)
        cell.userName.text = playerLine.userName
        cell.verseLine.text = playerLine.line
        cell.levelBadgeImage.image = UIImage(named: "lvl_" + String(playerLine.level) + ".png")
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    }
    
    
 
}




