//
//  MasterViewController.swift
//  MividioCam2
//
//  Created by Mat Mathews on 12/20/14.
//  Copyright (c) 2014 Miga Collabs. All rights reserved.
//

import UIKit


struct VerseHistoryRec{
    var id = -1
    var title = ""
    var owner_id = -1
    var user_ids:[Int] = []
    var lines_recs:[VerseLineRec] = []
    var players = Dictionary<Int,VersePlayerRec>()
}

struct VerseLineRec{
    var position = -1
    var text = ""
    var player_id = -1
}

struct VersePlayerRec{
    var user_id = -1
    var user_name = ""
}

class VerseHistoryMasterViewController: UITableViewController {
    
    var verses:[VerseHistoryRec] = []
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //self.navigationItem.leftBarButtonItem = self.editButtonItem()
        
        NetOpers.sharedInstance.get(NetOpers.sharedInstance.appserver_hostname! + "/u/verse-history", load_verses)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow() {
                println("indexPath \(indexPath)")
                let vhr = self.verses[indexPath.row]
                println("vhr \(vhr)")
                (segue.destinationViewController as VerseHistoryDetailViewController).detailItem = vhr
            }
        }
    }
    
    // MARK: - verses 
    
    func load_verses(data: NSData?, response: NSURLResponse?, error: NSError?){
        println("load_verses called")
        
        let httpResponse = response as NSHTTPURLResponse
        if httpResponse.statusCode == 200 {
            if data != nil {
                
                let jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(
                    data!, options: NSJSONReadingOptions.MutableContainers,
                    error: nil) as NSDictionary
                
                if let results = jsonResult["results"] as? NSArray{
                    
                    var verses:[VerseHistoryRec] = []
                    
                    for v in results {
                        
                        var vh = VerseHistoryRec()
                        
                        if let x = v["id"] as? Int{
                            vh.id = x
                        }
                        
                        if let x = v["title"] as? String{
                            vh.title = x
                        }
                        
                        if let x = v["owner_id"] as? Int{
                            vh.owner_id = x
                        }
                        
                        if let x = v["user_ids"] as? [Int]{
                            vh.user_ids = x
                        }
                        
                        if let x = v["lines_record"] as? String{
                            let data = (x as NSString).dataUsingEncoding(NSUTF8StringEncoding)
                            let linesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(
                                data!, options: NSJSONReadingOptions.MutableContainers,
                                error: nil) as NSDictionary

                            for (line_position, line_tuple) in linesDict{
                                
                                if let lp = line_position as? String{
                                    
                                }
                                
                                var p:Int? = (line_position as? String)!.toInt()
                                if let lp = p{
                                    var vlr = VerseLineRec(position:p!, text:line_tuple[1] as String, player_id:line_tuple[0] as Int)
                                    vh.lines_recs.append(vlr)
                                    
                                }else{
                                    println("corrupt data")
                                }

                            }
                        }
                        
                        if let x = v["players_record"] as? String{
                            let data = (x as NSString).dataUsingEncoding(NSUTF8StringEncoding)
                            let playersArray: NSArray = NSJSONSerialization.JSONObjectWithData(
                                data!, options: NSJSONReadingOptions.MutableContainers,
                                error: nil) as NSArray
                            for player in playersArray as NSArray{
                                var pid = player[0] as Int
                                var usrnm = player[1] as String
                                vh.players[pid] = VersePlayerRec(user_id: pid, user_name: usrnm)
                            }
                            
                        }

                        self.verses.append(vh)
                        
                    }
                    
                    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
                        dispatch_async(dispatch_get_main_queue(),{
                            
                            self.tableView.reloadData()
                            
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
    
    // MARK: - Table View
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.verses.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell
        var verse = self.verses[indexPath.row]
        cell.textLabel?.text = verse.title
        return cell
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
//            PropertyStore.sharedInstance.removePropertyAtIndex(indexPath.row)
//            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
    
}




