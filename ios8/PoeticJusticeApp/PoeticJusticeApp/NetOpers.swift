//
//  NetOpers.swift
//  PoeticJusticeApp
//
//  Created by Mat Mathews on 1/13/15.
//  Copyright (c) 2015 Miga Collabs. All rights reserved.
//

import UIKit
import Foundation



class NetOpers {
    
    // Singleton
    class var sharedInstance: NetOpers {
        struct Static {
            static let instance = NetOpers();
        }
        return Static.instance
    }
    
    let session: NSURLSession? = nil
    
    var appserver_hostname: String?
    var loginHandler: LoginViewController?
    var alertHandler: LoginViewController?
    
    var user: User = User()
    
    var game_state: GameState? = nil
    
    init(){
        self.session = NSURLSession.sharedSession()
        
        var myDict: NSDictionary?
        
        // use a optional let assignment thing to check for the existence of
        // the Config plist file.
        if let path = NSBundle.mainBundle().pathForResource("Config", ofType: "plist") {
            myDict = NSDictionary(contentsOfFile: path)
        }
        
        if let dict = myDict {
            if let ah = dict["appserver_hostname"] as String?{
                self.appserver_hostname = ah
            }
        }
        
        
    }
    
    func _load_topics(on_topics_loaded:((NSData?, NSURLResponse?, NSError?)->Void)?) -> Bool{
        if self.appserver_hostname != nil{
            var url:String = self.appserver_hostname! + "/u/get-topics"
            self.get(url, completion_handler: on_topics_loaded)
            return true
        }else{
            return false
        }
    }
    
    func get(url: String, completion_handler:((NSData?, NSURLResponse?, NSError?)->Void)? ){
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        var request = NSMutableURLRequest(URL: NSURL(string: url)!)
        request.HTTPShouldHandleCookies = true
        request.HTTPMethod = "GET"
        
        var task = self.session?.dataTaskWithRequest(request, completionHandler: completion_handler?)
        task?.resume()
    }
    
    func post(url: String, params: Dictionary<String, AnyObject>, completion_handler:((NSData?, NSURLResponse?, NSError?)->Void)? ) {
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        var request = NSMutableURLRequest(URL: NSURL(string: url)!)
        request.HTTPShouldHandleCookies = true
        request.HTTPMethod = "POST"
        request.HTTPBody = stringFromParameters(params).dataUsingEncoding(NSUTF8StringEncoding)
        
        var task = self.session?.dataTaskWithRequest(request, completionHandler: completion_handler?)
        
        task?.resume()
    }
    
    func put(url: String, params: Dictionary<String, AnyObject>, completion_handler:((NSData?, NSURLResponse?, NSError?)->Void)? ) {
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        var request = NSMutableURLRequest(URL: NSURL(string: url)!)
        request.HTTPShouldHandleCookies = true
        request.HTTPMethod = "PUT"
        request.HTTPBody = stringFromParameters(params).dataUsingEncoding(NSUTF8StringEncoding)
        
        var task = self.session?.dataTaskWithRequest(request, completionHandler: completion_handler?)
        
        task?.resume()
    }
    
    func sync_post(url: String, params: Dictionary<String, AnyObject>) -> NSDictionary?{
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        var request = NSMutableURLRequest(URL: NSURL(string: url)!)
        request.HTTPShouldHandleCookies = true
        request.HTTPMethod = "POST"
        request.HTTPBody = stringFromParameters(params).dataUsingEncoding(NSUTF8StringEncoding)
        var response: NSURLResponse?
        var error: NSErrorPointer = nil
        var dataVal: NSData? =  NSURLConnection.sendSynchronousRequest(
            request, returningResponse: &response, error:error)
        if error == nil {
            if dataVal != nil {
                if let actual_response = response as? NSHTTPURLResponse {
                    if actual_response.statusCode == 200{
                        var jsonDictifiedResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(dataVal!, options: NSJSONReadingOptions.MutableContainers, error: error) as NSDictionary
                        
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                        
                        return jsonDictifiedResult
                    }
                }
            }
        }
        
        // where is the swift finally?
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        
        return nil
        
    }
    
    func login(params : Dictionary<String, AnyObject>, url: String, on_login:()->(Void) ) {
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        var request = NSMutableURLRequest(URL: NSURL(string: url)!)
        
        request.HTTPShouldHandleCookies = true
        request.HTTPMethod = "POST"
        request.HTTPBody = stringFromParameters(params).dataUsingEncoding(NSUTF8StringEncoding)
        
        println("sending login request")
        
        var task = self.session?.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            if let httpResponse = response as? NSHTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    
                    if data != nil {
                        
                        var json: JSON? = nil
                        var user_data: NSDictionary?
                        var requires_verification: Bool = true
                        
                        if let jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(
                        data, options: NSJSONReadingOptions.MutableContainers,
                        error: nil) as? NSDictionary{
                                
                            if let results = jsonResult["user"] as? NSDictionary{
                                
                                user_data = results
                                
                            }
                            
                            if let rq_v = jsonResult["verification_req"] as? Bool{
                                requires_verification = rq_v
                            }
                        }
                        
                        if user_data != nil{
                            
                            self.user = User(user_data: user_data!)
                            
                            dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
                                dispatch_async(dispatch_get_main_queue(),{
                                    
                                    if requires_verification{
                                        if self.alertHandler != nil{
                                            self.alertHandler!.show_alert("Verify", message:"Please check your email for verification", controller_title:"Ok!")
                                        }
                                        
                                        if self.loginHandler != nil{
                                            self.loginHandler!.on_email_notification()
                                        }
                                        
                                    }else{
                                        if self.loginHandler != nil{
                                            self.loginHandler!.on_login()
                                        }else{
                                            // TODO: is this possible?
                                            on_login()
                                        }
                                    }
                                    
                                })
                            })
                            
                        }
                        
                    }
                    
                } else if httpResponse.statusCode == 403 {
                    
                    println("Forbidden")
                    dispatch_async(dispatch_get_main_queue(),{
                        if self.alertHandler != nil{
                            self.alertHandler!.show_alert("Verify", message:"Please check your email for verification", controller_title:"Ok")
                        }
                        
                        if self.loginHandler != nil{
                            self.loginHandler!.on_email_notification()
                        }
                        
                    })
                    
                }else{
                    println("error signing in")
                }
                
            }
            
            
        })
        
        if self.loginHandler != nil{
            self.loginHandler!.on_finished_login()
        }
        
        task?.resume()
    }
    
    
    func get_player_game_state(on_received_gate_state:((NSData?, NSURLResponse?, NSError?)->Void)? ) -> Bool{
        
        if self.user.is_logged_in() && self.appserver_hostname != nil{
            
            var url_string:String = self.appserver_hostname! + "/u/game-state"
            
            self.get(url_string, on_received_gate_state?)
            
            return true
            
        }else{
            // cant show an err here because its not view
            return false
        }
    }
    
    func update_main_player_score(increment_by:Int, on_score_updated:((NSData?, NSURLResponse?, NSError?)->Void)? ) -> Bool{
        if self.user.is_logged_in() && self.appserver_hostname != nil{
            
            var url_string:String = self.appserver_hostname! + "/u/update/score"
            
            var params = Dictionary<String, AnyObject>()
            params["id"] = self.user.id
            params["score_increment"] = increment_by
            
            self.post(url_string, params: params, on_score_updated?)
            
            return true
            
        }else{
            // cant show an err here because its not view
            return false
        }
    }
    
    func update_player_score(increment_by:Int, on_score_updated:((NSData?, NSURLResponse?, NSError?)->Void)? ) -> Bool{
        if self.user.is_logged_in() && self.appserver_hostname != nil{
            
            var url_string:String = self.appserver_hostname! + "/u/update/player-score"
            
            var params = Dictionary<String, AnyObject>()
            params["id"] = self.user.id
            params["score_increment"] = increment_by
            
            self.post(url_string, params: params, on_score_updated?)
            
            return true
            
        }else{
            return false
        }
    }
    
    func update_verse_score(verse_id:Int, increment_by:Int, on_score_updated:((NSData?, NSURLResponse?, NSError?)->Void)? ) -> Bool{
        if self.user.is_logged_in() && self.appserver_hostname != nil{
            
            var url_string:String = self.appserver_hostname! + "/v/update/score"
            
            var params = Dictionary<String, AnyObject>()
            params["id"] = verse_id
            params["score_increment"] = increment_by
            
            self.post(url_string, params: params, on_score_updated?)
            
            return true
            
        }else{
            return false
        }
    }
    
}





