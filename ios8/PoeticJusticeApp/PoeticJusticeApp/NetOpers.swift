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
    var loginHandler: AnyObject?
    
    var userId: Int? = nil
    var userKey: String? = nil
    var user: User? = nil
    
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
            var url:String = self.appserver_hostname! + "/m/search/VerseCategoryTopic"
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
        
        var task = self.session?.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            if let httpResponse = response as? NSHTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    
                    if data != nil {
                        
                        var json: JSON? = nil
                        var user_data: NSDictionary?
                        
                        if let jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(
                            data, options: NSJSONReadingOptions.MutableContainers,
                            error: nil) as? NSDictionary{
                                
                                if let results = jsonResult["user"] as? NSDictionary{
                                    
                                    user_data = results
                                    
                                    if let x = results["key"] as? String{
                                        self.userKey = x
                                        
                                        if let y = results["id"] as? Int{
                                            self.userId = y
                                        }
                                    }
                                }
                        }
                        
                        if self.userId != nil && self.userKey != nil && user_data != nil{
                            
                            self.user = User(userData: user_data!)
                            
                            let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
                            dispatch_async(dispatch_get_global_queue(priority, 0), { ()->() in
                                dispatch_async(dispatch_get_main_queue(), {
                                    on_login()
                                })
                            })
                            
                        }
                        
                        if (json != nil){
                            
                            () // do more with the json object
                            
                        }
                        
                    }
                    
                }else{
                    print("Error signing in")
                    // do something, figure out how to do async error handling
                    // without exceptions, because there are no exceptions in
                    // swift :(
                }
            }
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            
        })
        
        task?.resume()
    }
    
    func update_main_player_score(increment_by:Int, on_score_updated:((NSData?, NSURLResponse?, NSError?)->Void)? ) -> Bool{
        if self.userId != nil && self.appserver_hostname != nil{
            
            var url_string:String = self.appserver_hostname! + "/u/update/score"
            
            var params = Dictionary<String, AnyObject>()
            params["id"] = self.userId
            params["score_increment"] = increment_by
            
            self.post(url_string, params: params, on_score_updated?)
            
            return true
            
        }else{
            // cant show an err here because its not view
            return false
        }
    }
    
    func update_player_score(increment_by:Int, on_score_updated:((NSData?, NSURLResponse?, NSError?)->Void)? ) -> Bool{
        if self.userId != nil && self.appserver_hostname != nil{
            
            var url_string:String = self.appserver_hostname! + "/u/update/player-score"
            
            var params = Dictionary<String, AnyObject>()
            params["id"] = self.userId
            params["score_increment"] = increment_by
            
            self.post(url_string, params: params, on_score_updated?)
            
            return true
            
        }else{
            return false
        }
    }
    
    func update_verse_score(verse_id:Int, increment_by:Int, on_score_updated:((NSData?, NSURLResponse?, NSError?)->Void)? ) -> Bool{
        if self.userId != nil && self.appserver_hostname != nil{
            
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





