//
//  VerseResultsScreenViewController.swift
//  PoeticJusticeApp
//
//  Created by Mat Mathews on 2/9/15.
//  Copyright (c) 2015 Miga Col.Labs. All rights reserved.
//

import UIKit



struct VerseResultScreenRec{
    var id = -1
    var title = ""
    var owner_id = -1
    var user_ids:[Int] = []
    
    // int is pk and position
    var lines_recs = Dictionary<Int,VerseResultScreenLineRec>()
    
    // int is user id
    var players = Dictionary<Int,VerseResultScreenPlayerRec >()
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
    
    var viewLoaded: Bool = false
    
    var verseRec: VerseResultScreenRec?
    
    var verseLinesForTable:[VerseResultScreenLineRec] = []
    
    var avatar = Avatar()
    
    var votingClosed = false
    
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
                            
                            var avnStr = player[2] as String
                            if !avnStr.isEmpty{
                                let upData = (avnStr as NSString).dataUsingEncoding(NSUTF8StringEncoding)
                                let userPrefs: NSDictionary = NSJSONSerialization.JSONObjectWithData(
                                    upData!, options: NSJSONReadingOptions.MutableContainers,
                                    error: nil) as NSDictionary
                                avnStr = userPrefs["avatar_name"] as String
                            }
                            
                            vrsr.players[pid] = VerseResultScreenPlayerRec(user_id: pid, user_name: usrnm, avatar_name:avnStr)
                            
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
        println("cellForRowAtIndexPath called\(indexPath.row)")
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell
        if let pc = cell as? PlayerLineTableViewCell{
            
            // get the line
            var vlr = verseLinesForTable[indexPath.row]
            
            // get the player record so we can 
            // set the avatar and userName
            var playerRec = self.verseRec?.players[vlr.player_id]
    
            pc.avatarImage.image = UIImage(named: playerRec!.avatar_name)
            pc.userName.text = playerRec!.user_name
            
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
                println(vlr.player_id)
            }
        }
        
    }
    
    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        
        println("willSelectRowAtIndexPath clicked " + String(indexPath.row))
        
        if self.votingClosed{
            return nil
        }else{
            return indexPath
        }
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
}



























