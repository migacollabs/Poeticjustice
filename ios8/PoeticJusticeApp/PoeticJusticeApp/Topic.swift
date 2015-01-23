//
//  User.swift
//  PoeticJusticeApp
//
//  Created by Mat Mathews on 1/15/15.
//  Copyright (c) 2015 Miga Collabs. All rights reserved.
//

import Foundation

class Topic{
    let topic_data: NSDictionary
    
    init(rec:NSDictionary){
        self.topic_data = rec
    }
    
    var id: AnyObject? {
        get {
            if let x = self.topic_data["id"] as? Int{
                return x
            }
            return nil
        }
    }
    
    var name: AnyObject? {
        get {
            if let x = self.topic_data["name"] as? String{
                return x
            }
            return nil
        }
    }
    
    var min_points_req: AnyObject? {
        get {
            if let x = self.topic_data["min_points_req"] as? Int{
                return x
            }
            return nil
        }
    }
    
    var score_modifier: AnyObject? {
        get {
            if let x = self.topic_data["score_modifier"] as? Int{
                return x
            }
            return nil
        }
    }
    
    var main_icon_name: AnyObject? {
        get {
            if let x = self.topic_data["main_icon_name"] as? String{
                return x
            }
            return nil
        }
    }
    
    var verse_category_type_id: AnyObject? {
        get {
            if let x = self.topic_data["verse_category_type_id"] as? Int{
                return x
            }
            return nil
        }
    }
    
    
}