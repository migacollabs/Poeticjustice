//
//  WorldVerseViewController.swift
//  PoeticJusticeApp
//
//  Created by Mat Mathews on 1/30/15.
//  Copyright (c) 2015 Miga Col.Labs. All rights reserved.
//

import UIKit

class WorldVerseViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var playersTable: UITableView!
    
    var players:[String]
    
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
    
    func loadPlayers(data: NSData?, response: NSURLResponse?, error: NSError?) {
        let httpResponse = response as NSHTTPURLResponse
        if httpResponse.statusCode == 200 {
            if data != nil {
                
                let jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(
                    data!, options: NSJSONReadingOptions.MutableContainers,
                    error: nil) as NSDictionary
                
                if let results = jsonResult["results"] as? NSArray{
                    
                    self.players.removeAll()
                    
                    for p in results {
                        
                        self.player.append(p)
                        
                    }
                    
                    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
                        dispatch_async(dispatch_get_main_queue(),{
                            self.playersTable.reloadData()
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
