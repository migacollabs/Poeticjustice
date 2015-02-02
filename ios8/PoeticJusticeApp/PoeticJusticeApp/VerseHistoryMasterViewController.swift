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
        if segue.identifier == "placeholder" {
            if let indexPath = self.tableView.indexPathForSelectedRow() {
                //let property = PropertyStore.sharedInstance.get(indexPath.row)
                //(segue.destinationViewController as DetailViewController).detailItem = property
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




