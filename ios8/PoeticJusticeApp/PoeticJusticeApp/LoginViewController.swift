
//
//  ViewController.swift
//  PoeticJusticeApp
//
//  Created by Mat Mathews on 1/16/15.
//  Copyright (c) 2015 Miga Collabs. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var user_name: UITextField!
    @IBOutlet weak var email_address: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        NetOpers.sharedInstance.loginHandler = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func on_go(sender: AnyObject) {
        
        println("attempting login...")
        
        var myDict: NSDictionary?
        
        // use a optional let assignment thing to check for the existence of
        // the Config plist file.
        if let path = NSBundle.mainBundle().pathForResource("Config", ofType: "plist") {
            myDict = NSDictionary(contentsOfFile: path)
        }
        
        // i'm pretty sure this sets 'dict' to a pointer to
        // myDict if myDict isn't nil. This is supposed to work
        // because myDict is an optional
        if let dict = myDict {
            if let ah = dict["appserver_hostname"] as String?{
                
                // the println is better than NSLog
                // the cool \(var) formatting handle almost everything
                println("Connecting to \(ah)")
                
                var login_url = ah + "/login"
                
                var params = Dictionary<String,AnyObject>()
                params["form.submitted"] = true
                params["country_code"] = "USA"
                
                if let em = self.email_address.text{
                    params["login"] = em
                    
                }
                
                if let un = self.user_name.text{
                    params["user_name"] = un
                }
                
                if let login_em = params["login"] as? String{
                    
                    println("Connectintg as \(login_em)")
                    
                    NetOpers.sharedInstance.login(params, url: login_url, {() -> (Void) in
                        
                        // we are logged in!
                        self.show_alert("Login", message: "Successfully logged in", controller_title: "Thanks!")
                        
                    })
                    
//                    // TODO: open up a clickable topics view
//                    tabBarController?.selectedIndex = 1
                    
                }else{
                    () // do no user email address msg
                }
            }else{
                () // do no app server error msg
            }
        }
        
    }
    
    func on_login(){
        // TODO: open up a clickable topics view
        tabBarController?.selectedIndex = 1
    }
    
    func show_alert(title:String, message:String, controller_title:String){
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: controller_title, style: UIAlertActionStyle.Default,handler: nil))
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
}












