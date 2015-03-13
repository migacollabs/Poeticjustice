//
//  VerseResultsScreenViewController.swift
//  PoeticJusticeApp
//
//  Created by Mat Mathews on 2/9/15.
//  Copyright (c) 2015 Miga Col.Labs. All rights reserved.
//

import UIKit
import iAd


let HOSTNAME = NetOpers.sharedInstance.appserver_hostname!


class VerseResultsScreenViewController: UIViewController, UITableViewDataSource,
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
    @IBOutlet weak var currentUserNameLeadingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var currentUserLevel: UIImageView!
    @IBOutlet weak var currentUserPoints: UILabel!
    @IBOutlet weak var currentUserAvatarImage: UIImageView!
    @IBOutlet weak var currentUserCoinsImg: UIImageView!
    
    var currentUserId: Int = -1
    var prevUserId: Int = -1
    
    // @IBOutlet weak var winnerUserName: UILabel!
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
    var sortedLineIndexes = [Int]()
    var avatar = Avatar()
    var stillVoting = false
    
    // var iAdBanner: ADBannerView?
    
    
    var verseId: Int? {
        didSet {
            if self.viewLoaded{
                self.configureView()
            }
        }
    }
    
    var topic: Topic?{
        didSet{
            if self.viewLoaded{
                self.configureView()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // clear the labels
        self.currentUserName.text = ""
        // self.winnerUserName.text = ""
        self.voteMsgLabel.text = ""
        
//        var screen_height = UIScreen.mainScreen().bounds.height
//        self.iAdBanner = self.appdelegate().iAdBanner
//        //self.iAdBanner?.delegate = self
//        self.iAdBanner?.frame = CGRectMake(0,screen_height-98, 0, 0)
//        if let adb = self.iAdBanner{
//            // println("adding ad banner subview ")
//            // self.view.addSubview(adb)
//        }
        
        self.viewLoaded = true
        
        self.loadVerseData()
        
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
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadVerseData(){
        if let vid = self.verseId{
            
            // TODO: switch view_callable to POST and use params
            var params = Dictionary<String,AnyObject>()
            params["id"]=vid
            
            NetOpers.sharedInstance.get(
                NetOpers.sharedInstance.appserver_hostname! + "/v/viewable/id=\(vid)", loadVerse)
            
        }
    }
    
    
    func loadVerse(data: NSData?, response: NSURLResponse?, error: NSError?){
        
        if let httpResponse = response as? NSHTTPURLResponse {
            if httpResponse.statusCode == 200 {
                if data != nil {
                    
                    let jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(
                        data!, options: NSJSONReadingOptions.MutableContainers,
                        error: nil) as NSDictionary
                    
                    if let results = jsonResult["results"] as? NSDictionary{
                        
                        var vrsr = VerseResultScreenRec()
                        
                        var verseDict: NSDictionary?
                        
                        if let x = results["verse"] as? NSDictionary{
                            verseDict = x
                        }else{
                            println("corrupt verse results data")
                        }
                        
                        if let verse = verseDict{
                            
                            if let x = verse["id"] as? Int{
                                vrsr.id = x
                            }
                            
                            if let x = verse["title"] as? String{
                                vrsr.title = x
                            }
                            
                            if let x = verse["owner_id"] as? Int{
                                vrsr.owner_id = x
                            }
                            
                            if let x = verse["user_ids"] as? [Int]{
                                vrsr.user_ids = x
                            }
                            
                            if let x = verse["participant_count"] as? Int{
                                vrsr.participantCount = x
                            }
                            
                            if let x = verse["votes"] as? String{
                                let voteData = (x as NSString).dataUsingEncoding(NSUTF8StringEncoding)
                                if let votesDict = NSJSONSerialization.JSONObjectWithData(
                                    voteData!, options: NSJSONReadingOptions.MutableContainers,
                                    error: nil) as? NSDictionary{
                                        //ok safely have a dict of votes
                                        
                                        for (player_id, linePos) in votesDict{
                                            
                                            var pid:Int? = (player_id as? String)!.toInt()
                                            if let pid_ = pid{
                                                vrsr.votes[pid_] = linePos as? Int
                                            }
                                        }
                                }
                                
                            }
                            
                        }else{
                            println("corrupt verse data")
                        }
                        
                        if let linesDict = results["lines"] as? NSDictionary{
                            
                            for (line_position, line_tuple) in linesDict{
                                
                                // json dict key is str, change to int
                                var p:Int? = (line_position as? String)!.toInt()
                                
                                if let lp = p{
                                    var vlr = VerseResultScreenLineRec(
                                        position:p!,
                                        text:line_tuple[1] as String,
                                        player_id:line_tuple[0] as Int,
                                        line_score:0)
                                    
                                    vrsr.lines_recs[p!] = vlr
                                    
                                    self.verseLinesForVoting[vlr.position] = vlr
                                    
                                }else{
                                    println("corrupt line pk")
                                }
                                
                            }
                        }else{
                            println("corrupt lines data")
                        }
                        
                        if let playersArray = results["user_data"] as? NSArray{
                            for player in playersArray as NSArray{
                                
                                var pid = player[0] as Int
                                var usrnm = player[1] as String
                                
                                var avnStr:String? = player[2] as? String
                                if avnStr == nil{
                                    avnStr = ""
                                }
                                
                                if !avnStr!.isEmpty{
                                    let upData = (avnStr! as NSString).dataUsingEncoding(NSUTF8StringEncoding)
                                    let userPrefs: NSDictionary = NSJSONSerialization.JSONObjectWithData(
                                        upData!, options: NSJSONReadingOptions.MutableContainers,
                                        error: nil) as NSDictionary
                                    avnStr = userPrefs["avatar_name"] as? String
                                }else{
                                    avnStr = "avatar_default.png"
                                }
                                
                                var pnts = player[3] as Int
                                var lvl = player[4] as Int
                                var flag = player[5] as String
                                var numFavs = player[6] as Int
                                
                                vrsr.players[pid] = VerseResultScreenPlayerRec(
                                    user_id: pid, user_name: usrnm, user_score:pnts,
                                    num_of_favorited_lines: numFavs,
                                    level:lvl, flag_icon:flag,
                                    avatar_name:avnStr!)
                                
                            }
                            
                        }else{
                            println("corrupt user_data")
                        }
                        
                        self.verseRec = vrsr
                        
                        
                        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
                            dispatch_async(dispatch_get_main_queue(),{
                                
                                self.configureView()
                                
                                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                                
                            })
                        })
                    }
                    
                }
            } else {
                self.show_alert("\(httpResponse.statusCode) Oops", message: "There was a problem loading the verse.  Please try again.", controller_title:"Ok")
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            }

        }
        
        if (error != nil) {
            if let e = error?.localizedDescription {
                self.show_alert("Unable to load verse", message: e, controller_title:"Ok")
            } else {
                self.show_alert("Network error", message: "Unable to load verse", controller_title:"Ok")
            }
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
    }

    
    func configureView() {
        
        if self.viewLoaded{
            if let vr = self.verseRec{
                
                if let topic = self.topic{
                    if let t_btn = self.topicButton{
                        t_btn.setImage(UIImage(named: topic.main_icon_name as String), forState: .Normal)
                    }
                }
                
                if let lineRecs = self.verseRec?.lines_recs{
                    
                    // sort asc because lines have pks that asc
                    self.sortedLineIndexes = Array(lineRecs.keys).sorted(<)
                    
                    for linePos in self.sortedLineIndexes{
                        self.verseLinesForTable.append(lineRecs[linePos]!)
                    }
                    
                }
                
                self.animateTable()
                
                self.checkVotes()

                var i = 0
                for user_id in vr.user_ids {
                    
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
                        self.tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: UITableViewScrollPosition.None)
                        //self.highlightAvatar(NetOpers.sharedInstance.user.id)
                        //self.updateCurrentUser(NetOpers.sharedInstance.user.id)
                    }
                    
                }else{
                    //self.voteMsgLabel.text = "Time to pick your favorite line! \(vr.votes.count)\\\(vr.user_ids.count)"
                    self.show_alert("Complete", message: "Time to pick your favorite line!", controller_title: "Ok")
                }
                
            }
        }
        
        //self.tableView.reloadData()
    }
    
    
    func checkVotes(){
        
        if let vr = self.verseRec{
            
            // if all the votes are in
            if vr.votes.count == vr.user_ids.count{
                
                var rightButton : UIBarButtonItem = UIBarButtonItem(
                    barButtonSystemItem: UIBarButtonSystemItem.Action, target: self, action: "showActivityPanel")
                self.navigationItem.rightBarButtonItem = rightButton
                
                var linesForPlayer = [Int:Int]()
                var starsForLines = [Int:Int]()
                
                for pid in vr.user_ids{
                    linesForPlayer[pid as Int] = 0 as Int
                }
                
                // tally votes for each player's line
                for (voter, line_id) in vr.votes{
                    
                    if var vlfv = self.verseLinesForVoting[line_id as Int]{
                        if (contains(linesForPlayer.keys, vlfv.player_id)) {
                            linesForPlayer[vlfv.player_id]! += 1
                        }
                        
                        vlfv.line_score += 1
                        
                        if(contains(starsForLines.keys, line_id)){
                            starsForLines[line_id]! += 1
                        }else{
                            starsForLines[line_id] = 1
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
                    // self.winnerUserName.text = userName
                    self.winnerIcon.image = UIImage(named:"medal-ribbon.png")
                    self.voteMsgLabel.text = "And the winner is " + userName! + "!"
                } else {
                    self.voteMsgLabel.text = "It's a draw!"
                }
                
                for(lineId, starCount) in starsForLines{
                    var rowNumber = find(self.sortedLineIndexes, lineId)
                    self.verseLinesForTable[rowNumber!].line_score += 1
                    
                    if rowNumber != nil{
                        self.setVoteStarOnRow(NSIndexPath(forRow:rowNumber!, inSection:0), numOfStars: starCount)
                    }
                    
                }
                
            }else{
                var rightButton : UIBarButtonItem = UIBarButtonItem(
                    title: "Help", style: UIBarButtonItemStyle.Plain, target: self, action: "showHelp")
                self.navigationItem.rightBarButtonItem = rightButton
            }
            
        }
    }
    
    
    func highlightAvatar(userId:Int){
        
        if userId != self.prevUserId{
        
            self.avatarPlayerOne.backgroundColor = UIColor.clearColor()
            self.avatarPlayerTwo.backgroundColor = UIColor.clearColor()
            self.avatarPlayerThree.backgroundColor = UIColor.clearColor()
            self.avatarPlayerFour.backgroundColor = UIColor.clearColor()
            self.avatarPlayerFive.backgroundColor = UIColor.clearColor()
            
            var avatarPlayer: UIImageView?
            
            var u_idx = -1
            if let idx = find(self.verseRec!.user_ids, userId){
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
            }
            
            if avatarPlayer != nil{
                avatarPlayer!.backgroundColor = GameStateColors.LightBlueT
                
                if avatarPlayer!.frame.origin.x != self.currentUserName!.frame.origin.x{
                    
                    self.currentUserName.frame.origin.x = avatarPlayer!.frame.origin.x
                    
                    UIView.animateWithDuration(0.5, delay: 0.25, options: .CurveEaseOut, animations: {
                        var offset = avatarPlayer!.frame.origin.x
                        self.currentUserName!.frame = CGRectOffset( self.currentUserName!.frame, offset, 0 )
                        self.currentUserNameLeadingConstraint.constant = offset
                        }, nil
                    )
                }
                
            }
            
        }
    
    }
    
    func updateCurrentUser(userId:Int){
        var player = self.verseRec!.players[userId]
        if player != nil{
            if let x = self.currentUserName{
                self.prevUserId = self.currentUserId
                self.currentUserId = player!.user_id
                x.text = player!.user_name
            }
        }
    }
    
    func setStarOnRow(indexPath:NSIndexPath){
        var cell = tableView.cellForRowAtIndexPath(indexPath) as PlayerLineTableViewCell
        cell.votedStar.image = UIImage(named: "star_gold_256.png")
    }
    
    func setVoteStarOnRow(indexPath:NSIndexPath, numOfStars:Int){
        if self.tableView != nil{
            if var cell = self.tableView.cellForRowAtIndexPath(indexPath) as? PlayerLineTableViewCell{
                if numOfStars >= 1{
                    cell.votedStar.image = UIImage(named: "star_gold_256.png")
                    cell.votedStar.alpha = 0.25
                }
                if numOfStars >= 2{
                    cell.starTwo.image = UIImage(named: "star_gold_256.png")
                    cell.starTwo.alpha = 0.25
                }
                if numOfStars >= 3{
                    cell.starThree.image = UIImage(named: "star_gold_256.png")
                    cell.starThree.alpha = 0.25
                }
                if numOfStars >= 4{
                    cell.starFour.image = UIImage(named: "star_gold_256.png")
                    cell.starFour.alpha = 0.25
                }
            }
        }
    }
    
    
    // MARK: - Table View
    
    
    func animateTable() {
        tableView.reloadData()
        
        let cells = tableView.visibleCells()
        let tableHeight: CGFloat = tableView.bounds.size.height
        
        for i in cells {
            let cell: UITableViewCell = i as UITableViewCell
            cell.transform = CGAffineTransformMakeTranslation(0, tableHeight)
        }
        
        var index = 0
        
        for a in cells {
            let cell: UITableViewCell = a as UITableViewCell
            UIView.animateWithDuration(1.5, delay: 0.05 * Double(index), usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: nil, animations: {
                cell.transform = CGAffineTransformMakeTranslation(0, 0);
                }, completion: nil)
            
            index += 1
        }
    }
    
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
                        
                        var numOfStars = vlr.line_score
                        
                        if numOfStars >= 1{
                            pc.votedStar.image = UIImage(named: "star_gold_256.png")
                            pc.votedStar.alpha = 0.25
                        }
                        if numOfStars >= 2{
                            pc.starTwo.image = UIImage(named: "star_gold_256.png")
                            pc.starTwo.alpha = 0.25
                        }
                        if numOfStars >= 3{
                            pc.starThree.image = UIImage(named: "star_gold_256.png")
                            pc.starThree.alpha = 0.25
                        }
                        if numOfStars >= 4{
                            pc.starFour.image = UIImage(named: "star_gold_256.png")
                            pc.starFour.alpha = 0.25
                        }
                        
                        break
                    }
                }
                
            }
            
            // set the line text
            //pc.verseLine.text = vlr.text
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
        
        if self.verseRec?.votes.count != self.verseRec?.participantCount{
            
            if let player_id = self.verseRec?.votes[NetOpers.sharedInstance.user.id]{
                
            }else{
            
                if let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as? UITableViewCell{
                    if let pc = cell as? PlayerLineTableViewCell{
                        var vlr = self.verseLinesForTable[indexPath.row]
                        
                        // pid is the user to vote for
                        var pid = vlr.player_id
                        var lid = vlr.position
                        
                        
                        let voteController = UIAlertController(title: "Confirm Vote", message: "You sure? Last chance!", preferredStyle: UIAlertControllerStyle.ActionSheet)
                        
                        let noAction = UIAlertAction(title: "No", style: .Default, handler: {
                            (alert: UIAlertAction!) -> Void in
                            // delete friend
                            return
                        })
                        let yesAction = UIAlertAction(title: "Yes", style: .Default, handler: {
                            (alert: UIAlertAction!) -> Void in
                            
                            self.stillVoting = true
                            
                            // TODO: this should be a post
                            NetOpers.sharedInstance.get(HOSTNAME + "/v/vote/pid=\(pid)/vid=\(self.verseId!)/lid=\(lid)", completion_handler: { (data:NSData?, response:NSURLResponse?, error:NSError?) -> Void in
                                
                                if let httpResponse = response as? NSHTTPURLResponse {
                                    if httpResponse.statusCode == 200 {
                                        if data != nil {
                                            
                                            // add the vote here for immediacy, the votes will be refreshed
                                            // later, but the table has to respond correctly
                                            self.verseRec?.votes[NetOpers.sharedInstance.user.id] = lid
                                            
                                            self.stillVoting = false
                                            
                                            // update label for some feedback
                                            dispatch_async(dispatch_get_main_queue(), {
                                                //self.voteMsgLabel.text = "Vote confirmed!"
                                                self.setStarOnRow(indexPath)
                                                self.checkVotes()
                                            })
                                            
                                            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                                            
                                        }
                                    }
                                    
                                    if (error != nil) {
                                        if let e = error?.localizedDescription {
                                            self.show_alert("Unable to vote", message: e, controller_title:"Ok")
                                        } else {
                                            self.show_alert("Network error", message: "Unable to leave verse", controller_title:"Ok")
                                        }
                                        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                                    }
                                }
                                
                            })
                            
                        })
                        
                        voteController.addAction(noAction)
                        voteController.addAction(yesAction)
                        
                        self.presentViewController(voteController, animated: true, completion: nil)
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
//    func tableView(tableView: UITableView, willDeselectRowAtIndexPath indexPath: NSIndexPath) {
//        println("willDeselectRowAtIndexPath called")
//    }
//    
//    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
//        println("didDeselectRowAtIndexPath called")
//    }
    
    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        
        println("willSelectRowAtIndexPath clicked " + String(indexPath.row))
        
//        if self.selectedRow != nil && self.selectedRow != indexPath.row{
//            println("calling deselect row \(self.selectedRow)")
//            let sindexPath = NSIndexPath(forRow:self.selectedRow!,inSection:0)
//            self.tableView.deselectRowAtIndexPath(sindexPath, animated: true)
//            var cell = self.tableView.cellForRowAtIndexPath(sindexPath)
//            cell?.contentView.backgroundColor = UIColor.whiteColor()
//            cell?.backgroundColor = UIColor.whiteColor()
//            println("changed background")
//        }
        
        if self.stillVoting{
            return nil
        }
        
        var vlr = self.verseLinesForTable[indexPath.row]
        
        self.updateCurrentUser(vlr.player_id)
        self.highlightAvatar(vlr.player_id)
        

        
//        // if every player has voted, don't allow selection
//        if self.verseRec?.votes.count == self.verseRec?.participantCount{
//            self.dispatch_alert("Whoops!", message: "Voting is closed!", controller_title: "Ok!")
//            return nil
//        }
//        
//        // check to see if this player has already voted
//        if let player_id = self.verseRec?.votes[NetOpers.sharedInstance.user.id]{
//            self.dispatch_alert("Whoops!", message: "You've already voted!", controller_title: "Ok!")
//            return nil
//        }
        
        return indexPath
        
    }
    
    func tableView(tableView: UITableView, didHighlightRowAtIndexPath indexPath: NSIndexPath) {
        println("didHighlightRowAtIndexPath called")
//        var cell = tableView.cellForRowAtIndexPath(indexPath)
//        cell?.contentView.backgroundColor = GameStateColors.LighBlue
//        cell?.backgroundColor = GameStateColors.LighBlue
    }
    
    func tableView(tableView: UITableView, didUnHighlightRowAtIndexPath indexPath: NSIndexPath) {
        println("didUnHighlightRowAtIndexPath called")
//        var cell = tableView.cellForRowAtIndexPath(indexPath)
//        cell?.contentView.backgroundColor = UIColor.whiteColor()
//        cell?.backgroundColor = UIColor.whiteColor()
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        
        var vlr = self.verseLinesForTable[indexPath.row]
        
        if let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as? UITableViewCell{
            if let pc = cell as? PlayerLineTableViewCell{
                
                var w = UIScreen.mainScreen().bounds.width * 0.8
                
                var h = self.heightForLabel(vlr.text, font:pc.verseLabel.font, width:w)
                
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
    
    func appdelegate () -> AppDelegate{
        return UIApplication.sharedApplication().delegate as AppDelegate
    }
    
//    func hide_adbanner(){
//        self.iAdBanner?.hidden = true
//    }
    
    
    func showHelp(){
        self.show_alert("What's this?",
            message: "After each player awards their favorite line with a gold star you can see them all here. The player with the most stars wins this verse!", controller_title:"Ok, got it!")
        
    }
    
    func showActivityPanel(){
        
        if self.verseLinesForTable.count > 0{
            
            var url = NetOpers.sharedInstance.appserver_hostname! + "/v/p/vid=\(self.verseRec?.id)"
            
            var params = Dictionary<String,AnyObject>()
            params["vid"]=self.verseRec?.id
            params["user_id"]=NetOpers.sharedInstance.user.id
            
            var result = NetOpers.sharedInstance.sync_post(url, params: params)
            if result != nil{
                if let vk = result!["verse_key"] as? String{
                    
                    var site = result!["site_addr"] as String
                    
                    var verseUrl = "http://\(site)/v/p/k=\(vk)"
                    
                    var verseText:String = "A Verse from Iambic, Are You?\n----\n\(verseUrl)\n\n"
                    
                    verseText += self.verseRec!.title + "\n\n"
                    
                    for line in self.verseLinesForTable{
                        verseText += line.text + "\n"
                    }
                    
                    let objectsToShare = [verseText]
                    let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
                    self.presentViewController(activityVC, animated: true, completion: nil)
                    
                }
            }
            
            
        }
        
    }
    

    
}



























