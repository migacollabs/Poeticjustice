//
//  VerseResultsScreenViewController.swift
//  PoeticJusticeApp
//
//  Created by Mat Mathews on 2/9/15.
//  Copyright (c) 2015 Miga Col.Labs. All rights reserved.
//

import UIKit


let HOSTNAME = NetOpers.sharedInstance.appserver_hostname!


struct VerseResultScreenRec{
    var id = -1
    var title = ""
    var owner_id = -1
    var user_ids:[Int] = []
    var participantCount = -1
    
    // int is pk and position
    var lines_recs = Dictionary<Int,VerseResultScreenLineRec>()
    
    // int is user id
    var players = Dictionary<Int,VerseResultScreenPlayerRec >()
    
    // int is user_id and val is line position
    var votes = Dictionary<Int,Int>()
}

struct VerseResultScreenLineRec{
    var position = -1
    var text = ""
    var player_id = -1
}

struct VerseResultScreenPlayerRec{
    var user_id = -1
    var user_name = ""
    var avatar_name = "avatar_mexican_guy.png"
}

class VerseResultsScreenViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var verseTitle: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var votesLeftLabel: UILabel!
    @IBOutlet weak var voteMsgLabel: UILabel!
    
    var viewLoaded: Bool = false
    
    var verseRec: VerseResultScreenRec?
    
    var verseLinesForTable:[VerseResultScreenLineRec] = []
    
    var verseLinesForVoting = [Int:VerseResultScreenLineRec]()
    
    var avatar = Avatar()
    
    var stillVoting = false
    
    var verseId: Int? {
        didSet {
            if self.viewLoaded{
                self.configureView()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.viewLoaded = true
        
        println("VerseResultsScreenViewController loaded")
        
        self.loadVerseData()
        
        self.tableView.allowsMultipleSelection = false
        self.tableView.allowsSelection = true
        
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
        
        println("loadVerse called")
        
        let httpResponse = response as NSHTTPURLResponse
        if httpResponse.statusCode == 200 {
            if data != nil {
                
                let jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(
                    data!, options: NSJSONReadingOptions.MutableContainers,
                    error: nil) as NSDictionary
                
                println(jsonResult)
                
                if let results = jsonResult["results"] as? NSDictionary{
                    
                    var vrsr = VerseResultScreenRec()
                    
                    var verseDict: NSDictionary?
                    
                    if let x = results["verse"] as? NSDictionary{
                        verseDict = x
                    }else{
                        println("corrupt verse results data")
                    }
                    
                    if let verse = verseDict{
                        
                        println(verse)
                        
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

                        }else{
                            println("no votes yet")
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
                                    position:p!, text:line_tuple[1] as String, player_id:line_tuple[0] as Int)
                                
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
                            
                            println(player)
                            
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
                                avnStr = "avatar_mexican_guy.png"
                            }
                            
                            vrsr.players[pid] = VerseResultScreenPlayerRec(
                                user_id: pid, user_name: usrnm, avatar_name:avnStr!)
                            
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
        }
        
        if (error != nil) {
            println(error)
        }
    }

    
    func configureView() {
        println("configureView called")
        
        if self.viewLoaded{
            if let vr = self.verseRec{
                
                // set the title
                if let title = self.verseTitle{
                    title.text = vr.title
                }
                
                if let lineRecs = self.verseRec?.lines_recs{
                    
                    // sort asc because lines have pks that asc
                    let sortedLinePos = Array(lineRecs.keys).sorted(<)
                    
                    for linePos in sortedLinePos{
                        
                        self.verseLinesForTable.append(lineRecs[linePos]!)
                        
                    }
                }
                
                
                self.tableView.reloadData()
                
                // check if this user has voted on this verse and select the row
                if let player_id = self.verseRec?.votes[NetOpers.sharedInstance.user.id]{
                    
                    self.voteMsgLabel.text = "You've voted!"

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
                        self.tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: UITableViewScrollPosition.None)
                    }
                    
                }
                
                if let vr = self.verseRec{
                    
                    self.votesLeftLabel.text = "\(vr.votes.count)\\\(vr.user_ids.count)"
                    
                    // if all the votes are in
                    if vr.votes.count == vr.user_ids.count{
                        
                        self.voteMsgLabel.text = "All votes are in!"
                        
                        var linesForPlayer = [Int:Int]()
                        
                        for pid in vr.user_ids{
                            linesForPlayer[pid as Int] = 0 as Int
                        }
                        
                        // tally votes for each player's line
                        for (voter, line_id) in vr.votes{
                            if let vlfv = self.verseLinesForVoting[line_id as Int]{
                                linesForPlayer[vlfv.player_id]! += 1
                            }
                        }
                        
                        var winnerId = 0
                        var prevScore = 0
                        for (player_id, tally) in linesForPlayer{
                            if tally > prevScore{
                                prevScore = tally
                                winnerId = player_id
                            }
                        }
                        if winnerId > 0{
                            var userName = self.verseRec?.players[winnerId]?.user_name
                            // there is a winner
                            self.dispatch_alert("We have a winner!", message: userName!, controller_title: "Ok")
                        }else{
                            // we have a tie
                            self.dispatch_alert("Winner", message: "We have a tie", controller_title: "Ok")
                        }
                        
                    }
                }
                
            }
        }
        
        
        
    }
    
    
    // MARK: - Table View
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        println("numOfRowsinSection called")
        return self.verseLinesForTable.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell
        if let pc = cell as? PlayerLineTableViewCell{
            
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
                        pc.avatarImage.image = UIImage(named: playerRec.avatar_name)
                        pc.userName.text = playerRec.user_name
                        break
                    }
                }
                if (found==false) {
                    pc.avatarImage.image = UIImage(named: "man_24.png")
                    pc.userName.text = ""
                }
            }
            
            // set the line text
            pc.verseLine.text = vlr.text
            
            
        }
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
        
        println("clicked " + String(indexPath.row))

        if let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as? UITableViewCell{
            if let pc = cell as? PlayerLineTableViewCell{
                var vlr = self.verseLinesForTable[indexPath.row]
                
                // TODO: set the player's vote at the server
                
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
                        
                        // add the vote here for immediacy, the votes will be refreshed
                        // later, but the table has to respond correctly
                        self.verseRec?.votes[NetOpers.sharedInstance.user.id] = lid
                        
                        self.stillVoting = false
                        
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                        
                        // update label for some feedback
                        dispatch_async(dispatch_get_main_queue(), {
                            self.voteMsgLabel.text = "Vote confirmed!"
                        })
                        
                    })

                })
                
                voteController.addAction(noAction)
                voteController.addAction(yesAction)

                
                self.presentViewController(voteController, animated: true, completion: nil)
                
            }
        }
        
    }
    
    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        
        println("willSelectRowAtIndexPath clicked " + String(indexPath.row))
        
        if self.stillVoting{
            return nil
        }
        
        // if every player has voted, don't allow selection
        if self.verseRec?.votes.count == self.verseRec?.participantCount{
            self.dispatch_alert("Whoops!", message: "Voting is closed!", controller_title: "Ok!")
            return nil
        }
        
        // check to see if this player has already voted
        if let player_id = self.verseRec?.votes[NetOpers.sharedInstance.user.id]{
            self.dispatch_alert("Whoops!", message: "You've already voted!", controller_title: "Ok!")
            return nil
        }
        
        return indexPath
        
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        return 100.0
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
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: controller_title, style: UIAlertActionStyle.Default,handler: nil))
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
}



























