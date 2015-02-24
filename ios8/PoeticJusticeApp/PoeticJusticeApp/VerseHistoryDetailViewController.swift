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
    
    var detailItem: VerseResultScreenRec? {
        didSet {
            // Might not have to do anything here
            ()
        }
    }
    
    func configureView() {
        println("configureView called")
        // Update the user interface for the detail item.
        if let vhr: VerseResultScreenRec = self.detailItem {
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
                
                println("set data \(self.playerData)")
                
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
        println("cell for row called ")
        
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell
        if let pc = cell as? PlayerLineTableViewCell{
            println("we have a cell")
            var playerLine = playerData[indexPath.row]
            pc.userName.text = playerLine.userName
            pc.verseLabel.text = playerLine.line
        }

        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    }
    
    
 
}




