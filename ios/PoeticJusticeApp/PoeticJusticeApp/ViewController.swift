//
//  ViewController.swift
//  PoeticJusticeApp
//
//  Created by Mat Mathews on 1/16/15.
//  Copyright (c) 2015 Miga Collabs. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    @IBAction func openHelp(sender: AnyObject) {
        let vc = HelpViewController(nibName: "HelpViewController", bundle: nil)
        navigationController?.pushViewController(vc, animated: true)
        
    }
    @IBAction func onStart(sender: AnyObject) {
        
    }
}

