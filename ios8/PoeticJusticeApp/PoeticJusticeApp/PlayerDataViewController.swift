//
//  PlayerDataViewController.swift
//  PoeticJusticeApp
//
//  Created by Mat Mathews on 2/26/15.
//  Copyright (c) 2015 Miga Col.Labs. All rights reserved.
//

import UIKit

protocol PlayerDataViewDelegate : class {
    func dismissModal()
}

class PlayerDataViewController: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var avatarImage: UIImageView!
    @IBOutlet weak var leafIconImageView: UIImageView!
    @IBOutlet weak var pointsLabel: UILabel!
    @IBOutlet weak var levelImageView: UIImageView!
    @IBOutlet weak var flagImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    
    var viewLoaded = false
    
    var parentView: PlayerDataViewDelegate?
    
    var dataRecord: VerseResultScreenPlayerRec? {
        didSet{
            println("data record \(self.dataRecord)")
            
            if let dr = self.dataRecord{
                if let ai = self.avatarImage{
                    ai.image = UIImage(named:dr.avatar_name)
                }
                if let li = self.leafIconImageView{
                    li.image = UIImage(named: "tea-plant-leaf-icon.png")
                }
                if let pl = self.pointsLabel{
                    pl.text = String(format: "x%03d", dr.user_score)
                }
                if let lvi = self.levelImageView{
                    lvi.image = UIImage(named: "lvl_" + String(dr.level) + ".png")
                }
                if let fvi = self.flagImageView{
                    var flag_img_name = dr.flag_icon.lowercaseString
                    println("FLAG NAME \(flag_img_name)")
                    fvi.image = UIImage(named:"\(flag_img_name).png")
                }
                if let usr = self.userNameLabel{
                    println("USER NAME \(dr.user_name)")
                    usr.text = dr.user_name
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.viewLoaded = true

        // Do any additional setup after loading the view.
        
        let tap1 = UITapGestureRecognizer(target: self, action:Selector("onGo:"))
        tap1.delegate = self
        self.view.addGestureRecognizer(tap1)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onGo(sender: AnyObject) {
        //self.dismissViewControllerAnimated(true , completion: nil)
        self.parentView?.dismissModal()
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
