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


struct VerseResultScreenRec{
    var id = -1
    var title = ""
    var owner_id = -1
    var user_ids:[Int] = []
    var participantCount = -1
    var topicId = -1
    
    // int is pk and position
    var lines_recs = Dictionary<Int,VerseResultScreenLineRec>()
    
    // int is user id
    var players = Dictionary<Int,VerseResultScreenPlayerRec >()
    
    // int is user_id and val is line position
    var votes = Dictionary<Int,Int>()
}

struct VerseResultScreenLineRec{
    var position = -1
    var text = ""
    var player_id = -1
}

struct VerseResultScreenPlayerRec{
    var user_id = -1
    var user_name = ""
    var user_score = -1
    var level = 1
    var avatar_name = "avatar_default.png"
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
    
    class var LightBlue: UIColor {
        return UIColor(red:84/255, green:199/255, blue:252/255, alpha:1.0)
    }
    
    class var Yellow: UIColor {
        return UIColor(red:255/255, green:205/255, blue:0/255, alpha:1.0)
    }
    
    class var Gold: UIColor {
        return UIColor(red:255/255, green:150/255, blue:0/255, alpha:1.0)
    }
    
    class var Pink: UIColor {
        return UIColor(red:255/255, green:40/255, blue:81/255, alpha:1.0)
    }

    class var Blue: UIColor {
        return UIColor(red:0/255, green:118/255, blue:255/255, alpha:1.0)
    }
    
    class var Green: UIColor {
        return UIColor(red:68/255, green:216/255, blue:94/255, alpha:1.0)
    }
    
    class var Red: UIColor {
        return UIColor(red:255/255, green:56/255, blue:36/255, alpha:1.0)
    }
    
    class var Grey: UIColor {
        return UIColor(red:142/255, green:142/255, blue:147/255, alpha:1.0)
    }
    

    class var LightBlueD: UIColor {
        return UIColor(red:63/255, green:149/255, blue:188/255, alpha:1.0)
    }
    
    class var YellowD: UIColor {
        return UIColor(red:191/255, green:154/255, blue:0/255, alpha:1.0)
    }
    
    class var GoldD: UIColor {
        return UIColor(red:191/255, green:112/255, blue:0/255, alpha:1.0)
    }
    
    class var PinkD: UIColor {
        return UIColor(red:191/255, green:30/255, blue:61/255, alpha:1.0)
    }
    
    class var BlueD: UIColor {
        return UIColor(red:0/255, green:88/255, blue:191/255, alpha:1.0)
    }
    
    class var GreenD: UIColor {
        return UIColor(red:48/255, green:155/255, blue:67/255, alpha:1.0)
    }
    
    class var RedD: UIColor {
        return UIColor(red:191/255, green:42/255, blue:27/255, alpha:1.0)
    }
    
    class var GreyD: UIColor {
        return UIColor(red:80/255, green:80/255, blue:83/255, alpha:1.0)
    }
    
    class var VeryLightGreyD: UIColor {
        return UIColor(red:250/255, green:250/255, blue:250/255, alpha:0.9)
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