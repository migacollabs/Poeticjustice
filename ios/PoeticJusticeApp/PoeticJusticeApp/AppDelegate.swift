//
//  AppDelegate.swift
//  PoeticJusticeApp
//
//  Created by Mat Mathews on 1/13/15.
//  Copyright (c) 2015 Miga Collabs. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        var myDict: NSDictionary?
        if let path = NSBundle.mainBundle().pathForResource("Config", ofType: "plist") {
            myDict = NSDictionary(contentsOfFile: path)
        }
        if let dict = myDict {
            // Use your dict here
            if let ah = dict["appserver_hostname"] as String?{
                
                println("Connecting to \(ah)")
                
                if let tu = dict["test_user_email_address"] as String?{
                    
                    println("Connectintg as \(tu)")
                    
                    var params = Dictionary<String,AnyObject>()
                    params["login"] = tu
                    params["form.submitted"] = true
                    params["country_code"] = "USA"
                    
                    var login_url = ah + "/login"
                    
                    NetOpers.sharedInstance.login(params, url: login_url)
                    
                }else{
                    
                    () // do no test user email address msg
                    
                }
            }else{
                
                () // do no app server error msg
                
            }
            
        }
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

