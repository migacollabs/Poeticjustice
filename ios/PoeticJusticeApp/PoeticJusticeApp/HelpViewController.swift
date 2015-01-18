//
//  HelpViewController.swift
//  PoeticJusticeApp
//
//  Created by Mat Mathews on 1/16/15.
//  Copyright (c) 2015 Miga Collabs. All rights reserved.
//

import UIKit
import AVFoundation

class HelpViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func goSomewhereElse(sender: AnyObject) {
        
//        // here we could open up a xib with its controller by pushing it onto
//        // the navCntl stack... which handles the pop off for us
//        let vc = TopicsViewController(nibName: "TopicsViewController", bundle: nil)
//        navigationController?.pushViewController(vc, animated: true)
        
        
        // but we can also grab a view controller from a different storyboard doing this
        // and still pushing onto the same nav.. maybe we really can split up the use case 'domains'
        // by storyboard.. dunno
        var gameplayStoryboard: UIStoryboard = UIStoryboard(name:"GamePlayStoryboard", bundle:nil)
        var controller:AnyObject? = gameplayStoryboard.instantiateViewControllerWithIdentifier("GamePlayViewController")
        if controller != nil{
            println("we have the controller")
            self.navigationController?.pushViewController(controller! as UIViewController, animated: true)
        }else{
            println("the controller is nil")
        }
        
    }
    
    let buttonSound = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("audio/Button Press", ofType: "wav")!)
    
    func playButtonSound(){
        let beepPlayer = AVAudioPlayer(contentsOfURL: buttonSound, error: nil)
        beepPlayer.prepareToPlay()
        beepPlayer.play()
    }
    
    @IBAction func handleButtonPress(sender: AnyObject) {
        playButtonSound()
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
