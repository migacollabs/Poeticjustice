//
//  User.swift
//  PoeticJusticeApp
//
//  Created by Mat Mathews on 1/15/15.
//  Copyright (c) 2015 Miga Collabs. All rights reserved.
//

import UIKit
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
    var avatar_name = "avatar_mexican_guy.png"
}



// MARK: - Colours 

class GameStateColors{
    
    class var SelectedColor: UIColor {
        return UIColor(red:0.67, green:0.93, blue:0.94, alpha:1.0)
    }
    
    class var LightBlue: UIColor {
        return UIColor(red:84/256, green:199/256, blue:252/256, alpha:1.0)
    }
    
    class var Green: UIColor {
        return UIColor(red:68/256, green:216/256, blue:94/256, alpha:1.0)
    }
    
}


// MARK: - Avatars

class Avatar{
    
    let avatars:[String] = [
        "avatar_afro_guy.png",
        "avatar_basketball_guy.png",
        "avatar_beanie_girl.png",
        "avatar_blond_guy.png",
        "avatar_bussiness_man.png",
        "avatar_emo_girl.png",
        "avatar_fashion_girl.png",
        "avatar_ginger_girl.png",
        "avatar_ginger_guy.png",
        "avatar_handsome_guy.png",
        "avatar_hiphop_guy.png",
        "avatar_hipster_guy.png",
        "avatar_hoody_guy.png",
        "avatar_jamaican_guy.png",
        "avatar_latin_guy.png",
        "avatar_longhair_girl.png",
        "avatar_mexican_guy.png",
        "avatar_nerd_guy.png",
        "avatar_nice_guy.png",
        "avatar_old_wise_man.png",
        "avatar_pixie_girl.png",
        "avatar_rocker_guy.png",
        "avatar_shorthair_girl.png",
        "avatar_singer_guy.png",
        "avatar_skater_guy.png",
        "avatar_smart_girl.png",
        "avatar_smart_guy.png",
        "avatar_sport_girl.png",
        "avatar_sport_guy.png",
        "avatar_working_girl.png"
    ]
    
    func get_avatar_file_name(avatarId:Int) -> String?{
        return self.avatars[avatarId]
    }
    
}