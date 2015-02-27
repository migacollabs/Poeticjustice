//
//  AppDelegate.swift
//  PoeticJusticeApp
//
//  Created by Larry Johnson on 1/21/15.
//  Copyright (c) 2015 Miga Col.Labs. All rights reserved.
//

import UIKit
import iAd
import Foundation
import AVFoundation


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, ADBannerViewDelegate {

    var window: UIWindow?
    var iAdBanner: ADBannerView = ADBannerView()
    var timer : NSTimer?
    var tabBarController : UITabBarController?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        tabBarController = application.windows[0].rootViewController as UITabBarController
        
        self.iAdBanner.delegate = self
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        if let t = timer {
            println("Stopping timer from refreshing navigation badges")
            t.invalidate()
        }
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        println("Starting timer to refresh navigation badges")
        timer = NSTimer.scheduledTimerWithTimeInterval(45.0, target: self, selector: Selector("refreshNavigationBadges"), userInfo: nil, repeats: true)
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func refreshNavigationBadges() {
        if (NetOpers.sharedInstance.user.is_logged_in()) {
            
            if let tbc : UITabBarController = tabBarController {
                if let nc = tbc.viewControllers?[1] as? UINavigationController {
                    if nc.topViewController is TopicsViewController {
                        println("Automatically refreshing through TopicsViewController")
                        var tvc = nc.topViewController as TopicsViewController
                        tvc.refresh()
                    } else {
                        println("Refreshing topic navigation badge for user")
                        NetOpers.sharedInstance.get(NetOpers.sharedInstance.appserver_hostname! + "/u/active-topics", updateActiveTopics)
                    }
                }
                
            }
            
        } else {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            println("Not refreshing navigation badges as no user is logged in")
        }
    }
    
    func updateActiveTopics(data:NSData?, response:NSURLResponse?, error:NSError?){
        if let httpResponse = response as? NSHTTPURLResponse {
            if httpResponse.statusCode == 200 {
                if data != nil {
                    let jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(
                        data!, options: NSJSONReadingOptions.MutableContainers,
                        error: nil) as NSDictionary
                    
                    var upNextCount : Int = 0
                    
                    if let results = jsonResult["results"] as? NSArray {
                        var recs : [ActiveTopicRec] = TopicsHelper.sharedInstance.convertToActiveTopicRecs(results)
                        
                        for atr : ActiveTopicRec in recs {
                            
                            if (TopicsHelper.sharedInstance.isUserUpNext(atr, userId: NetOpers.sharedInstance.user.id) && !atr.current_user_has_voted) {
                                upNextCount += 1;
                            }
                            
                        }
                    }
                    
                    if let tbc : UITabBarController = tabBarController {
                        
                        dispatch_async(dispatch_get_main_queue(), {
                        
                            var tabArray = tbc.tabBar.items as NSArray!
                            var tabItem = tabArray.objectAtIndex(1) as UITabBarItem
                            
                            if (upNextCount > 0) {
                                tabItem.badgeValue = String(upNextCount)
                            } else {
                                tabItem.badgeValue = nil
                            }
                            
                            println("Updating navigation badge to \(upNextCount)")
                        
                            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                            
                        })
                        
                    }
                    
                }
            } else {
                println("Unable to refresh navigation badges: \(httpResponse.statusCode)")
            }
        }
    }
    
    
    // MARK: - Ad Banner
    
    func bannerViewWillLoadAd(banner: ADBannerView!) {
        println("bannerViewWillLoadAd called")
    }
    
    func bannerViewDidLoadAd(banner: ADBannerView!) {
        println("bannerViewDidLoadAd called")
        //UIView.beginAnimations(nil, context:nil)
        //UIView.setAnimationDuration(1)
        //self.iAdBanner?.alpha = 1
        self.iAdBanner.hidden = false
        //UIView.commitAnimations()
        
    }
    
    func bannerViewActionDidFinish(banner: ADBannerView!) {
        println("bannerViewACtionDidFinish called")
    }
    
    func bannerViewActionShouldBegin(banner: ADBannerView!, willLeaveApplication willLeave: Bool) -> Bool{
        return true
    }
    
    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
        println("bannerView didFailToReceiveAdWithError called")
        self.iAdBanner.hidden = true
        println("bannerView didFailToReceiveAdWithError set banner to hidden")

    }


}

