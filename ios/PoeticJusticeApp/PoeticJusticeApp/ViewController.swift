//
//  ViewController.swift
//  PoeticJusticeApp
//
//  Created by Mat Mathews on 1/16/15.
//  Copyright (c) 2015 Miga Collabs. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var userNameOrEmail: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    @IBAction func openHelp(sender: AnyObject) {
        let vc = HelpViewController(nibName: "HelpViewController", bundle: nil)
        navigationController?.pushViewController(vc, animated: true)
        
    }
    @IBAction func onStart(sender: AnyObject) {
        
        println(self.userNameOrEmail.text)
        
        // create a new obj-c 'native' dictionary optional, meaning the myDict
        // var can be nil.
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
                
                if let em = self.userNameOrEmail.text{
                    params["login"] = em
                    
                }else{
                    
                    if let tu = dict["test_user_email_address"] as String?{
                        params["login"] = tu
                        
                    }
                    
                }
                
                if let login_em = params["login"] as? String{
                    
                    println("Connectintg as \(login_em)")
                    
                    NetOpers.sharedInstance.loginHandler = self
                    NetOpers.sharedInstance.login(params, url: login_url)
                    
                }else{
                    () // do no user email address msg
                }
            }else{
                () // do no app server error msg
            }
        }
  
    }
    
    
}

