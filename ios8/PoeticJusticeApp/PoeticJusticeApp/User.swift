//
//  User.swift
//  PoeticJusticeApp
//
//  Created by Mat Mathews on 1/15/15.
//  Copyright (c) 2015 Miga Collabs. All rights reserved.
//

import Foundation

protocol UserDelegate : class {
    func handleUserLevelChange(oldLevel : Int, newLevel : Int)
}

class User{
    
    private var userDelegates : [UserDelegate] = []
    
    var id: Int = -1
    var user_name: String = ""
    var email_address: String = ""
    var twitter_name: String = ""
    var facebook_name: String = ""
    var is_active: Bool = false
    var is_playing: Bool = false
    var mobile_number: String = ""
    var access_token: String = ""
    var device_token: String = ""
    var user_prefs: String = ""
    var user_score : Int = 0
    var level : Int = 0 {
        didSet{
            for ul : UserDelegate in userDelegates {
                ul.handleUserLevelChange(oldValue, newLevel: self.level)
            }
        }
    }
    
    func is_logged_in() -> Bool {
        return self.id > 0
    }
    
    func addUserDelegate(delegate : UserDelegate) {
        if (!contains(userDelegates, {$0===delegate})) {
            userDelegates.append(delegate)
        }
    }
    
    init() {
    }
    
    init(user_data : NSDictionary) {
        if let i = user_data["id"] as? Int {
            self.id = i
        }
        if let un = user_data["user_name"] as? String {
            self.user_name = un
        }
        if let ea = user_data["email_address"] as? String {
            self.email_address = ea
        }
        if let tn = user_data["twitter_name"] as? String {
            self.twitter_name = tn
        }
        if let fn = user_data["facebook_name"] as? String {
            self.facebook_name = fn
        }
        if let ia = user_data["is_active"] as? Bool {
            self.is_active = ia
        }
        if let ip = user_data["is_playing"] as? Bool {
            self.is_playing = ip
        }
        if let mn = user_data["mobile_number"] as? String {
            self.mobile_number = mn
        }
        if let at = user_data["access_token"] as? String {
            self.access_token = at
        }
        if let dt = user_data["device_token"] as? String {
            self.device_token = dt
        }
        if let up = user_data["user_prefs"] as? String {
            self.user_prefs = up
        }
        if let us = user_data["user_score"] as? Int {
            self.user_score = us
        }
        if let l = user_data["level"] as? Int {
            self.level = l
        }
        
    }
    
}