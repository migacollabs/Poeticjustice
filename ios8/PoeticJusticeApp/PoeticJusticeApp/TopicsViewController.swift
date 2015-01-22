//
//  TopicsViewController.swift
//  PoeticJusticeApp
//
//  Created by Mat Mathews on 1/17/15.
//  Copyright (c) 2015 Miga Collabs. All rights reserved.
//

import UIKit

class TopicsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.get_topics()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func handleTopicButton(sender: AnyObject) {
        let vc = WriteLineViewController(nibName: "WriteLineViewController", bundle: nil)
        navigationController?.pushViewController(vc, animated: false)
        println("loading WriteLineViewController")
        // don't remove the nav bar so the user can go back
    }
    
    func on_loaded_topics_completion(data:NSData?, response:NSURLResponse?, error:NSError?){
        if let httpResponse = response as? NSHTTPURLResponse {
            if httpResponse.statusCode == 200 {
                
                if data != nil {
                    
                    if let jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(
                        data!, options: NSJSONReadingOptions.MutableContainers,
                        error: nil) as? NSDictionary{
                            
                            if let results = jsonResult["results"] as? NSArray{
                                

                            }
                    }

                }
                
            }else{
                
                let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
                dispatch_async(dispatch_get_global_queue(priority, 0), { ()->() in
                    dispatch_async(dispatch_get_main_queue(), {
                        
                        let alertController = UIAlertController(title: "Error", message:
                            "There was an error!", preferredStyle: UIAlertControllerStyle.Alert)
                        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default,handler: nil))
                        
                        self.presentViewController(alertController, animated: true, completion: nil)
                        
                    })
                })

            }
        }
    }
    
    func get_topics(){
        NetOpers.sharedInstance._load_topics(on_loaded_topics_completion)
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
