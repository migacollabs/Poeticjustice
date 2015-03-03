//
//  VerseResultsScreenViewController.swift
//  PoeticJusticeApp
//
//  Created by Mat Mathews on 2/9/15.
//  Copyright (c) 2015 Miga Col.Labs. All rights reserved.
//

import UIKit


class VerseHistoryDetailViewController: UIViewController, UITableViewDataSource,
UITableViewDelegate, UIGestureRecognizerDelegate, PlayerDataViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var voteMsgLabel: UILabel!
    
    @IBOutlet weak var topicImage: UIImageView!
    @IBOutlet weak var topicButton: UIButton!
    
    @IBOutlet weak var avatarPlayerOne: UIImageView!
    @IBOutlet weak var avatarPlayerTwo: UIImageView!
    @IBOutlet weak var avatarPlayerThree: UIImageView!
    @IBOutlet weak var avatarPlayerFour: UIImageView!
    @IBOutlet weak var avatarPlayerFive: UIImageView!
    
    @IBOutlet weak var currentUserName: UILabel!
    @IBOutlet weak var currentUserNameConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var currentUserLevel: UIImageView!
    @IBOutlet weak var currentUserPoints: UILabel!
    @IBOutlet weak var currentUserAvatarImage: UIImageView!
    @IBOutlet weak var currentUserCoinsImg: UIImageView!
    
    @IBOutlet weak var winnerUserName: UILabel!
    @IBOutlet weak var winnerIcon: UIImageView!
    
    @IBOutlet weak var playerDataView: UIView!
    
    var currentPlayerModal: PlayerDataViewController?
    var blurFrame:UIVisualEffectView?
    
    var selectedRow:Int?
    var currentPlayerVotedFor:NSIndexPath?
    
    var viewLoaded: Bool = false
    var verseRec: VerseResultScreenRec?
    var verseLinesForTable:[VerseResultScreenLineRec] = []
    var verseLinesForVoting = [Int:VerseResultScreenLineRec]()
    var avatar = Avatar()
    var stillVoting = false
    
    var verseId: Int?
    var topic: Topic?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        // clear the labels
        self.currentUserName.text = ""
        self.winnerUserName.text = ""
        
        self.viewLoaded = true
        
        self.tableView.allowsMultipleSelection = false
        self.tableView.allowsSelection = true
        self.tableView.backgroundColor = UIColor.clearColor()
        
        self.tableView.separatorColor = UIColor.clearColor()
        
        let tap1 = UITapGestureRecognizer(target: self, action:Selector("onAvatarTap:"))
        tap1.delegate = self
        self.avatarPlayerOne.addGestureRecognizer(tap1)
        
        let tap2 = UITapGestureRecognizer(target: self, action:Selector("onAvatarTap:"))
        tap2.delegate = self
        self.avatarPlayerTwo.addGestureRecognizer(tap2)
        
        let tap3 = UITapGestureRecognizer(target: self, action:Selector("onAvatarTap:"))
        tap3.delegate = self
        self.avatarPlayerThree.addGestureRecognizer(tap3)
        
        let tap4 = UITapGestureRecognizer(target: self, action:Selector("onAvatarTap:"))
        tap4.delegate = self
        self.avatarPlayerFour.addGestureRecognizer(tap4)
        
        let tap5 = UITapGestureRecognizer(target: self, action:Selector("onAvatarTap:"))
        tap5.delegate = self
        self.avatarPlayerFive.addGestureRecognizer(tap5)
        
        self.configureView()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureView() {
        
        if self.viewLoaded{

            if let vr = self.verseRec{
                
                if let topic = self.topic{
                    println("theres a topic \(topic.main_icon_name)")
                    if let t_btn = self.topicButton{
                        println("theres a topic button \(t_btn)")
                        t_btn.setImage(UIImage(named: topic.main_icon_name as String), forState: .Normal)
                    }
                }
                
                if let lineRecs = self.verseRec?.lines_recs{
                    
                    // sort asc because lines have pks that asc
                    let sortedLinePos = Array(lineRecs.keys).sorted(<)
                    
                    for linePos in sortedLinePos{
                        self.verseLinesForTable.append(lineRecs[linePos]!)
                        self.verseLinesForVoting[linePos] = self.verseRec!.lines_recs[linePos]
                    }
                }
                
                
                self.tableView.reloadData()
                
                if let vr = self.verseRec{
 
                    // if all the votes are in
                    if vr.votes.count == vr.user_ids.count{
                        
                        //self.voteMsgLabel.text = "All votes are in! \(vr.votes.count)\\\(vr.user_ids.count)"
                        
                        var linesForPlayer = [Int:Int]()
                        
                        for pid in vr.user_ids{
                            linesForPlayer[pid as Int] = 0 as Int
                        }
                        // tally votes for each player's line
                        for (voter, line_id) in vr.votes{
                            if let vlfv = self.verseLinesForVoting[line_id as Int]{
                                if (contains(linesForPlayer.keys, vlfv.player_id)) {
                                    linesForPlayer[vlfv.player_id]! += 1
                                }
                            }
                        }
                        
                        var winners:[Int] = []
                        var highestScore = 0
                        for (player_id, tally) in linesForPlayer{
                            if tally > highestScore{
                                highestScore = tally
                                winners = [player_id]
                            }else if tally == highestScore{
                                winners.append(player_id)
                            }
                        }
                        
                        if winners.count == 1{
                            var userName = self.verseRec?.players[winners[0]]?.user_name
                            // there is a winner
                            self.winnerUserName.text = userName
                            self.winnerIcon.image = UIImage(named:"medal-ribbon.png")
                            //self.dispatch_alert("We have a winner!", message: userName!, controller_title: "Ok")
                        }else{
                            // we have a tie
                            self.dispatch_alert("Winner", message: "We have a tie", controller_title: "Ok")
                        }
                        
                    }
                }
                
                var i = 0
                for user_id in vr.players.keys {
                    
                    switch i{
                    case 0:
                        self.avatarPlayerOne.image = self.getPlayerAvatarImageName(user_id)
                    case 1:
                        self.avatarPlayerTwo.image = self.getPlayerAvatarImageName(user_id)
                    case 2:
                        self.avatarPlayerThree.image = self.getPlayerAvatarImageName(user_id)
                    case 3:
                        self.avatarPlayerFour.image = self.getPlayerAvatarImageName(user_id)
                    case 4:
                        self.avatarPlayerFive.image = self.getPlayerAvatarImageName(user_id)
                    default:
                        ()
                    }
                    
                    i++
                }
                
                // check if this user has voted on this verse and select the row
                if let player_vote = self.verseRec?.votes[NetOpers.sharedInstance.user.id]{
                    
                    //self.voteMsgLabel.text = "You've voted! \(vr.votes.count)\\\(vr.user_ids.count)"
                    
                    var i = 0
                    var foundMatch = false
                    for vlft in self.verseLinesForTable{
                        if vlft.position == self.verseRec?.votes[NetOpers.sharedInstance.user.id]{
                            foundMatch = true
                            break
                        }else{
                            i++
                        }
                    }
                    
                    if foundMatch{
                        let indexPath = NSIndexPath(forRow:i,inSection:0)
                        self.currentPlayerVotedFor = indexPath
                        self.tableView.selectRowAtIndexPath(
                            indexPath, animated: true, scrollPosition: UITableViewScrollPosition.None)
                    }
                    
                }
                
            }
        }
    }
    
    func highlightAvatar(userId:Int){
        
        self.avatarPlayerOne.backgroundColor = UIColor.clearColor()
        self.avatarPlayerTwo.backgroundColor = UIColor.clearColor()
        self.avatarPlayerThree.backgroundColor = UIColor.clearColor()
        self.avatarPlayerFour.backgroundColor = UIColor.clearColor()
        self.avatarPlayerFive.backgroundColor = UIColor.clearColor()
        
        var arr:[Int] = Array(self.verseRec!.players.keys)
        
        if let idx = find(arr, userId){
            
            var avatarPlayer: UIImageView?
            
            switch idx{
            case 0:
                avatarPlayer = self.avatarPlayerOne
            case 1:
                avatarPlayer = self.avatarPlayerTwo
            case 2:
                avatarPlayer = self.avatarPlayerThree
            case 3:
                avatarPlayer = self.avatarPlayerFour
            case 4:
                avatarPlayer = self.avatarPlayerFive
            default:
                ()
            }
            
            if avatarPlayer != nil{
                avatarPlayer!.backgroundColor = GameStateColors.LightBlueT
                
                if avatarPlayer!.frame.origin.x != self.currentUserName!.frame.origin.x{
                    
                    self.currentUserName.frame.origin.x = avatarPlayer!.frame.origin.x
                    
                    UIView.animateWithDuration(0.5, delay: 0.25, options: .CurveEaseOut, animations: {
                        var offset = avatarPlayer!.frame.origin.x
                        self.currentUserName!.frame = CGRectOffset( self.currentUserName!.frame, offset, 0 )
                        self.currentUserNameConstraint.constant = offset
                        }, nil
                    )
                }
            }
        }
    }
    
    func updateCurrentUser(userId:Int){
        var player = self.verseRec!.players[userId]
        if let x = self.currentUserName{
            x.text = player!.user_name
        }
        if let x = self.currentUserLevel{
            x.image = UIImage(named: "lvl_" + String(player!.level) + ".png")
        }
        if let x = self.currentUserCoinsImg{
            x.image = UIImage(named: "tea-plant-leaf-icon.png")
        }
        if let x = self.currentUserPoints{
            x.text = String(format: "x%03d", player!.user_score)
        }
        
        if let x = self.currentUserAvatarImage{
            x.image = self.getPlayerAvatarImageName(userId)
        }
    }
    
    func setStarOnRow(indexPath:NSIndexPath){
        var cell = tableView.cellForRowAtIndexPath(indexPath) as PlayerLineTableViewCell
        cell.votedStar.image = UIImage(named: "star_gold_256.png")
    }
    
    
    // MARK: - Table View
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.verseLinesForTable.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell
        if let pc = cell as? PlayerLineTableViewCell{
            
            //pc.yourPickLabel.text = "" // clear it
            pc.votedStar.image = nil
            
            // get the line
            var vlr = verseLinesForTable[indexPath.row]
            
            // get the player record so we can
            // set the avatar and userName
            // TODO: should we display the players who joined but then left?
            if let vr = self.verseRec {
                var found : Bool = false
                for id in vr.players.keys {
                    if (id==vlr.player_id) {
                        found = true
                        let playerRec : VerseResultScreenPlayerRec = vr.players[vlr.player_id]!

                        if pc.userName != nil{
                            pc.userName.text = playerRec.user_name
                        }
                        
                        if self.currentPlayerVotedFor != nil && self.currentPlayerVotedFor!.row == indexPath.row{
                            pc.votedStar.image = UIImage(named: "star_gold_256.png")
                        }
                        
                        break
                    }
                }
                
            }
            
            pc.verseLabel.text = vlr.text
            pc.verseLabel.font.fontName
        
        }
        
        var customView = UIView()
        customView.backgroundColor = GameStateColors.LightBlueT
        cell.selectedBackgroundView = customView
        return cell
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            //            PropertyStore.sharedInstance.removePropertyAtIndex(indexPath.row)
            //            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.selectedRow = indexPath.row
    }
    
    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        
        var vlr = self.verseLinesForTable[indexPath.row]
        
        self.updateCurrentUser(vlr.player_id)
        self.highlightAvatar(vlr.player_id)
        
        return indexPath
        
    }
    
//    func tableView(tableView: UITableView, didHighlightRowAtIndexPath indexPath: NSIndexPath) {
//        println("didHighlightRowAtIndexPath called")
//        //        var cell = tableView.cellForRowAtIndexPath(indexPath)
//        //        cell?.contentView.backgroundColor = GameStateColors.LighBlue
//        //        cell?.backgroundColor = GameStateColors.LighBlue
//    }
//    
//    func tableView(tableView: UITableView, didUnHighlightRowAtIndexPath indexPath: NSIndexPath) {
//        println("didUnHighlightRowAtIndexPath called")
//        //        var cell = tableView.cellForRowAtIndexPath(indexPath)
//        //        cell?.contentView.backgroundColor = UIColor.whiteColor()
//        //        cell?.backgroundColor = UIColor.whiteColor()
//    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        
        var vlr = self.verseLinesForTable[indexPath.row]
        
        if let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as? UITableViewCell{
            if let pc = cell as? PlayerLineTableViewCell{
                
                var h = self.heightForLabel(vlr.text, font:pc.verseLabel.font, width:pc.verseLabel.frame.width)
                
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
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: - Alerts
    
    func dispatch_alert(title:String, message:String, controller_title:String){
        
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0), { ()->() in
            dispatch_async(dispatch_get_main_queue(), {
                
                let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
                alertController.addAction(UIAlertAction(title: controller_title, style: UIAlertActionStyle.Default,handler: nil))
                
                self.presentViewController(alertController, animated: true, completion: nil)
                
            })
        })
    }
    
    func show_alert(title:String, message:String, controller_title:String){
        dispatch_async(dispatch_get_main_queue()) {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: controller_title, style: UIAlertActionStyle.Default,handler: nil))
            
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    func getPlayerAvatarImageName(userId : Int) -> UIImage {
        if let pr = self.verseRec?.players[userId]{
            return UIImage(named: pr.avatar_name)!
        }
        return UIImage(named: "man_48.png")!
    }
    
    @IBAction func onTopicButtonClick(sender: AnyObject) {
        
        dispatch_async(dispatch_get_main_queue()) {
            
            let alertController = UIAlertController(title: "Title", message: self.verseRec?.title, preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
            
            if let v = self.verseRec{
                
                if let url = NSURL(string:v.title) {
                    let open: ((UIAlertAction!) -> Void)! = { action in
                        UIApplication.sharedApplication().openURL(url)
                        return
                    }
                    
                    alertController.addAction(UIAlertAction(title: "Open in Safari", style: UIAlertActionStyle.Default, handler: open ))
                }
                
                self.presentViewController(alertController, animated: true, completion: nil)
                
            }
            
        }
    }
    
    func onAvatarTap(recognizer: UITapGestureRecognizer){
        if let imageView = recognizer.view as? UIImageView{
            if imageView.image != nil{
                
                var selectedPlayerRec:VerseResultScreenPlayerRec?
                
                if let vr = self.verseRec{
                    var uid = vr.user_ids[imageView.tag-1]
                    selectedPlayerRec = vr.players[uid]
                }
                
                
                let presentingViewController = PlayerDataViewController(nibName: "PlayerDataViewController", bundle:nil)
                
                var presentationStyle = UIModalPresentationStyle.PageSheet
                
                presentingViewController.providesPresentationContextTransitionStyle = true
                presentingViewController.definesPresentationContext = true
                presentingViewController.modalPresentationStyle = presentationStyle
                presentingViewController.view.backgroundColor = UIColor.clearColor()
                presentingViewController.parentView = self
                presentingViewController.dataRecord = selectedPlayerRec!
                presentingViewController.view.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
                
                self.currentPlayerModal = presentingViewController
                
                let blur = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.Light))
                blur.frame = view.frame
                self.blurFrame = blur
                view.addSubview(blur)
                blur.contentView.addSubview(presentingViewController.view)
                
            }
        }
    }
    
    func dismissModal(){
        if let cpm = self.currentPlayerModal{
            cpm.view.removeFromSuperview()
        }
        if let blur = self.blurFrame{
            blur.removeFromSuperview()
        }
    }
    
}



























