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
    var lines_recs:[VerseResultScreenLineRec] = []
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

class VerseResultsScreenViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    func load_verse(data: NSData?, response: NSURLResponse?, error: NSError?){
        
        let httpResponse = response as NSHTTPURLResponse
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
                        
                    }
                    
                    if let linesDict = results["lines"] as? NSDictionary{
                    
                        // TODO: line_position sorting
                    
                        for (line_position, line_tuple) in linesDict{
                            
                            var p:Int? = (line_position as? String)!.toInt()
                            if let lp = p{
                                var vlr = VerseResultScreenLineRec(
                                    position:p!, text:line_tuple[1] as String, player_id:line_tuple[0] as Int)
                                
                                vrsr.lines_recs.append(vlr)
                                
                            }else{
                                println("corrupt data")
                            }
                            
                        }
                    }
                    
                    if let playersArray = results["user_data"] as? NSArray{
                        for player in playersArray as NSArray{
                            var pid = player[0] as Int
                            var usrnm = player[1] as String
                            var avn = player[2] as String
                            vrsr.players[pid] = VerseResultScreenPlayerRec(user_id: pid, user_name: usrnm, avatar_name:avn)
                        }
                        
                    }
                    
                    println(vrsr)
                    
                    
                    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
                        dispatch_async(dispatch_get_main_queue(),{
                            
                            // TODO: reload table
                            
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

}
