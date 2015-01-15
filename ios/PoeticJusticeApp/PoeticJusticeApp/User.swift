//
//  User.swift
//  PoeticJusticeApp
//
//  Created by Mat Mathews on 1/15/15.
//  Copyright (c) 2015 Miga Collabs. All rights reserved.
//

import Foundation

class User{
    let user_data: NSDictionary
    
    init(userData:NSDictionary){
        self.user_data = userData
    }
    
    var id: AnyObject? {
        get {
            if let x = self.user_data["id"] as? Int{
                return x
            }
            return nil
        }
    }
    
    var key: AnyObject? {
        get {
            if let x = self.user_data["key"] as? String{
                return x
            }
            return nil
        }
    }
    
    var user_name: AnyObject? {
        get {
            if let x = self.user_data["user_name"] as? String{
                return x
            }
            return nil
        }
    }
    
    var email_address: AnyObject? {
        get {
            if let x = self.user_data["email_address"] as? String{
                return x
            }
            return nil
        }
    }
    
    var twitter_name: AnyObject? {
        get {
            if let x = self.user_data["twitter_name"] as? String{
                return x
            }
            return nil
        }
    }
    
    var facebook_name: AnyObject? {
        get {
            if let x = self.user_data["facebook_name"] as? String{
                return x
            }
            return nil
        }
    }
    
    var is_active: AnyObject? {
        get {
            if let x = self.user_data["is_active"] as? Bool{
                return x
            }
            return nil
        }
    }

    var is_playing: AnyObject? {
        get {
            if let x = self.user_data["is_playing"] as? Bool{
                return x
            }
            return nil
        }
    }
    
    var mobile_number: AnyObject? {
        get {
            if let x = self.user_data["mobile_number"] as? String{
                return x
            }
            return nil
        }
    }
    
    var access_token: AnyObject? {
        get {
            if let x = self.user_data["access_token"] as? String{
                return x
            }
            return nil
        }
    }
    
    var device_token: AnyObject? {
        get {
            if let x = self.user_data["device_token"] as? String{
                return x
            }
            return nil
        }
    }
    
    var user_prefs: AnyObject? {
        get {
            if let x = self.user_data["user_prefs"] as? String{
                return x
            }
            return nil
        }
    }
    
    var user_score: AnyObject? {
        get {
            if let x = self.user_data["user_score"] as? Int{
                return x
            }
            return nil
        }
    }

    
}