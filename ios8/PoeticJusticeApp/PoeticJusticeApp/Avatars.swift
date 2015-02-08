//
//  Avatars.swift
//  PoeticJusticeApp
//
//  Created by Mat Mathews on 2/8/15.
//  Copyright (c) 2015 Miga Col.Labs. All rights reserved.
//

import Foundation


class Avatar{
    
    let avatars:[String] = [
        "avatar_afro_guy.png",
        "avatar_basketball_guy.png",
        "avatar_beanie_girl.png",
        "avatar_blond_guy.png",
        "avatar_bussiness_man.png",
        "avatar_emo_girl",
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