//
//  CustomSegues.swift
//  PoeticJusticeApp
//
//  Created by Mat Mathews on 2/3/15.
//  Copyright (c) 2015 Miga Col.Labs. All rights reserved.
//

import UIKit
import Foundation


@objc(MGPushNoAnimationSegue)
class MGPushNoAnimationSegue: UIStoryboardSegue {
    override func perform () {
        
        var sb = UIStoryboard(name: "Main", bundle: nil)
        
        let src = self.sourceViewController as UIViewController
        let dst = sb.instantiateViewControllerWithIdentifier("homeViewController") as UIViewController
//        src.navigationController?.setViewControllers([dst], animated:true)
        src.presentViewController(dst, animated: true, completion: nil)
    }
}
