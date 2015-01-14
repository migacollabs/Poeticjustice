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
    
    var userId: Int? = nil
    var userKey: String? = nil
    
    init(){
        self.session = NSURLSession.sharedSession()
    }
    
    func login(params : Dictionary<String, AnyObject>, url : String) {
        
        println("NetOpers.login called")
        
        var request = NSMutableURLRequest(URL: NSURL(string: url)!)
        
        request.HTTPShouldHandleCookies = true
        request.HTTPMethod = "POST"
        request.HTTPBody = stringFromParameters(params).dataUsingEncoding(NSUTF8StringEncoding)
        
        var task = self.session?.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            if let httpResponse = response as? NSHTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    
                    if data != nil {
                        
                        var json: JSON? = nil
                        
                        if let jsonResult: NSDictionary =
                            NSJSONSerialization.JSONObjectWithData(
                                data, options: NSJSONReadingOptions.MutableContainers,
                                error: nil) as? NSDictionary{
                                    
                                    if let results = jsonResult["user"] as? NSDictionary{
                                        
                                        if let x = results["key"] as? String{
                                            self.userKey = x
                                            println("UserKey \(x)")
                                            
                                            if let y = results["id"] as? Int{
                                                self.userId = y
                                                println("UserId \(y)")
                                            }
                                        }
                                        
                                    }
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
            
        })
        
        task?.resume()
    }
    
}