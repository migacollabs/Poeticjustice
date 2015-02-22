//
//  CloseVerseViewController.swift
//  PoeticJusticeApp
//
//  Created by Mat Mathews on 2/4/15.
//  Copyright (c) 2015 Miga Col.Labs. All rights reserved.
//

import UIKit

class CloseVerseViewController: UIViewController {

    @IBOutlet weak var verseTitle: UILabel!
    
    var verseId: Int = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onClose(sender: AnyObject) {
        println("onClose called")
        
        if self.verseId > 0 {
            NetOpers.sharedInstance.get(
                NetOpers.sharedInstance.appserver_hostname! + "/v/close/id=\(self.verseId)", {data, response, error -> Void in
                    
                    if let httpResponse = response as? NSHTTPURLResponse {
                        if httpResponse.statusCode == 200 {
                            if data != nil {
                                
                                let jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(
                                    data!, options: NSJSONReadingOptions.MutableContainers,
                                    error: nil) as NSDictionary
                                
                                if let status = jsonResult["status"] as? String{
                                    if status == "Ok"{
                                        
                                    }
                                }
                                
                                dispatch_async(dispatch_get_main_queue(),{
                                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                                })
                                
                            }
                        } else {
                            self.show_alert("\(httpResponse.statusCode) Oops", message: "There was a problem closing this verse.  Please try again.", controller_title:"Ok")
                            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                        }
                    }
                    
                    if (error != nil) {
                        if let e = error?.localizedDescription {
                            self.show_alert("Unable to close verse", message: e, controller_title:"Ok")
                        } else {
                            self.show_alert("Network error", message: "Unable to close verse", controller_title:"Ok")
                        }
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    }
            })
        }else{
            //raise error message
        }
        
    }
    
    
    func load_verse(){
        
        if self.verseId > 0 {
            NetOpers.sharedInstance.get(
                NetOpers.sharedInstance.appserver_hostname! + "/v/view/id=\(self.verseId)", {data, response, error -> Void in
                    
                    if let httpResponse = response as? NSHTTPURLResponse {
                        if httpResponse.statusCode == 200 {
                            if data != nil {
                                
                                let jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(
                                    data!, options: NSJSONReadingOptions.MutableContainers,
                                    error: nil) as NSDictionary
                                
                                var verse = ""
                                if let results = jsonResult["results"] as? NSDictionary{
                                    if let lines = results["lines"] as? NSArray{
                                        for line in lines{
                                            verse += "\(line)"
                                        }
                                    }
                                }
                                
                                dispatch_async(dispatch_get_main_queue(),{
                                    //                                self.verseText.text = verse
                                    
                                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                                })
                                
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
                
            })
        }else{
            //raise error message
        }
        
    }
    
    func show_alert(title:String, message:String, controller_title:String){
        dispatch_async(dispatch_get_main_queue()) {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: controller_title, style: UIAlertActionStyle.Default,handler: nil))
            
            self.presentViewController(alertController, animated: true, completion: nil)
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
