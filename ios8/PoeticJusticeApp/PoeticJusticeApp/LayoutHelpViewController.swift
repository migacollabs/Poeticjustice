//
//  LayoutHelpViewController.swift
//  PoeticJusticeApp
//
//  Created by Larry Johnson on 1/21/15.
//  Copyright (c) 2015 Miga Col.Labs. All rights reserved.
//

import UIKit

class LayoutHelpViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // doing this means we can exclude this layout view controller once initialized
        // this way, if a tab is pressed it'll always go back to this view
        let vc = HelpViewController(nibName: "HelpViewController", bundle: nil)
        self.navigationController!.setViewControllers([vc], animated : false)
        println("loading HelpViewController")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

