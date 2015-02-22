//
//  User.swift
//  PoeticJusticeApp
//
//  Created by Mat Mathews on 1/15/15.
//  Copyright (c) 2015 Miga Collabs. All rights reserved.
//

import Foundation

class GameState{
    let game_data: NSDictionary
    
    init(gameData:NSDictionary){
        self.game_data = gameData
    }
    
    var open_topics: AnyObject? {
        get {
            if let x = self.game_data["open_topics"] as? NSArray{
                return x
            }
            return nil
        }
    }
}

struct PlayerLineRec{
    var position = -1
    var text = ""
    var player_id = -1
}

struct PlayerRec{
    var user_id = -1
    var user_name = ""
    var avatar_name = "avatar_default.png"
}