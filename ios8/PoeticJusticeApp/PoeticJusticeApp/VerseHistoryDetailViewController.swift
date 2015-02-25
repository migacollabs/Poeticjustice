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
    
    @IBOutlet weak var avatarPlayerOne: UIImageView!
    @IBOutlet weak var avatarPlayerTwo: UIImageView!
    @IBOutlet weak var avatarPlayerThree: UIImageView!
    @IBOutlet weak var avatarPlayerFour: UIImageView!
    @IBOutlet weak var avatarPlayerFive: UIImageView!
    
    @IBOutlet weak var currentUserName: UILabel!
    @IBOutlet weak var leafPointsIcon: UIImageView!
    @IBOutlet weak var currentUserPoints: UILabel!
    @IBOutlet weak var currentUserLevel: UIImageView!
    
    var topic: Topic?
    
    var playerData: [PlayerLines] = []
    
    var detailItem: VerseResultScreenRec? {
        didSet {
            // Might not have to do anything here
            ()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.currentUserName.text = ""
        self.currentUserPoints.text = ""
        
        self.configureView()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureView() {
        
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
        
        if let topic = self.topic{
            if let topicImg = self.topicIconImage{
                topicImg.image = UIImage(named:topic.main_icon_name as String)
            }
        }
        
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
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell
        if let pc = cell as? PlayerLineTableViewCell{
            var playerLine = playerData[indexPath.row]
            pc.verseLabel.text = playerLine.line
        }

        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    }
    
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        
        var vlr = self.playerData[indexPath.row]
        
        if let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as? UITableViewCell{
            if let pc = cell as? PlayerLineTableViewCell{
                
                var h = self.heightForLabel(vlr.line, font:pc.verseLabel.font, width:pc.verseLabel.frame.width)
                
                if h > 17.0{
                    return 35.0 + 17.0
                }
            }
        }
        
        return 35.0
    }
    
    func heightForLabel(text:String, font:UIFont, width:CGFloat) -> CGFloat{
        var label:UILabel = UILabel(frame: CGRectMake(0, 0, width, CGFloat.max))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.ByWordWrapping
        label.font = font
        label.text = text
        label.sizeToFit()
        return label.frame.height
    }
    
//    func highlightAvatar(userId:Int){
//        
//        self.avatarPlayerOne.backgroundColor = UIColor.clearColor()
//        self.avatarPlayerTwo.backgroundColor = UIColor.clearColor()
//        self.avatarPlayerThree.backgroundColor = UIColor.clearColor()
//        self.avatarPlayerFour.backgroundColor = UIColor.clearColor()
//        self.avatarPlayerFive.backgroundColor = UIColor.clearColor()
//        
//        var arr:[Int] = Array(self.verseRec!.players.keys)
//        
//        if let idx = find(arr, userId){
//            
//            for uid in self.verseRec!.players.keys {
//                
//                switch idx{
//                case 0:
//                    self.avatarPlayerOne.backgroundColor = GameStateColors.LightBlueD
//                case 1:
//                    self.avatarPlayerTwo.backgroundColor = GameStateColors.LightBlueD
//                case 2:
//                    self.avatarPlayerThree.backgroundColor = GameStateColors.LightBlueD
//                case 3:
//                    self.avatarPlayerFour.backgroundColor = GameStateColors.LightBlueD
//                case 4:
//                    self.avatarPlayerFive.backgroundColor = GameStateColors.LightBlueD
//                default:
//                    ()
//                }
//            }
//            
//        }
//        
//    }
//    
//    func updateCurrentUser(userId:Int){
//        var player = self.verseRec!.players[userId]
//        println("updateCurrentUser \(player)")
//        if let x = self.currentUserName{
//            println("updateCurrentUser \(x)")
//            x.text = player!.user_name
//        }
//        if let x = self.currentUserLevel{
//            println("updateCurrentUser \(x)")
//            x.image = UIImage(named: "lvl_" + String(player!.level) + ".png")
//        }
//        if let x = self.currentUserCoinsImg{
//            x.image = UIImage(named: "tea-plant-leaf-icon.png")
//        }
//        if let x = self.currentUserPoints{
//            x.text = String(format: "x%03d", player!.user_score)
//            //x.text = String(player!.user_score) + "pnts"
//        }
//    }
    
    
 
}




