//
//  NewVerseViewController.swift
//  PoeticJusticeApp
//
//  Created by Mat Mathews on 1/28/15.
//  Copyright (c) 2015 Miga Col.Labs. All rights reserved.
//

import UIKit
import AVFoundation

class NewVerseViewController: UIViewController {
    
    
    @IBOutlet weak var verseTitle: UITextField!
    @IBOutlet weak var friendsOnly: UISwitch!
    @IBOutlet weak var topicButton: UIButton!
    
    // TODO: if the verse it set, update the view
    // to show the parameters for that verse
    var verseId : Int?
    
    var maxNumPlayers : Int = 2
    
    var topic: Topic?{
        didSet{
            self.configureView()
        }
    }
    
    @IBAction func setNumberPlayers(sender: AnyObject) {
        let sc = (sender as UISegmentedControl)
        switch sc.selectedSegmentIndex
        {
        case 0:
            maxNumPlayers = 2
        case 1:
            maxNumPlayers = 3
        case 2:
            maxNumPlayers = 4
        case 3:
            maxNumPlayers = 5
        default:
            break;
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureView()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureView(){
        if let t_btn = self.topicButton{
            if let t = self.topic{
                t_btn.setImage(UIImage(named: t.main_icon_name as String), forState: .Normal)
            }
        }
    
    }
    
    @IBAction func onStart(sender: AnyObject) {
        
        var params = Dictionary<String,AnyObject>()
        params["title"] = self.verseTitle.text
        params["max_participants"] = self.maxNumPlayers
        params["friends_only"] = self.friendsOnly.on
        params["owner_id"] = NetOpers.sharedInstance.userId!
        params["next_user_id"] = NetOpers.sharedInstance.userId!
        params["user_ids"] = String(NetOpers.sharedInstance.userId!) + ";"
        params["verse_category_topic_id"] = self.topic?.id
        
        NetOpers.sharedInstance.post(
            NetOpers.sharedInstance.appserver_hostname! + "/m/edit/Verse",
            params: params, {(data:NSData?, response:NSURLResponse?, error:NSError?) -> Void in
                
                // if the server is down, it will die here
                // how to catch/fix without exceptions?
                
                let httpResponse = response as NSHTTPURLResponse
                if httpResponse.statusCode == 200 {
                    if data != nil {
                        
                        let jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(
                            data!, options: NSJSONReadingOptions.MutableContainers,
                            error: nil) as NSDictionary
                        
                        if let model_name = jsonResult["model"] as? String{
                            println(model_name)
                            if model_name == "<class 'poeticjustice.models.Verse'>"{
                                if let results = jsonResult["results"] as? NSArray{
                                    var d = results[0] as? NSDictionary
                                    if d != nil{
                                        dispatch_async(dispatch_get_main_queue(),{
                                            self.start_accepted(d!["id"] as Int)
                                        })
                                    
                                    }

                                }
                            }
                        }
                        

                    }
                }
                
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            })
    }
    
    var audioPlayer : AVAudioPlayer?
    
    func playButtonSound(){
        var error:NSError?
        
        // TODO: needs to subtle if anything
        if let path = NSBundle.mainBundle().pathForResource("SoundFX1", ofType: "wav") {
            audioPlayer = AVAudioPlayer(contentsOfURL: NSURL(fileURLWithPath: path), fileTypeHint: "wav", error: &error)
            
            if let sound = audioPlayer {
                
                sound.prepareToPlay()
                
                sound.play()
                println("play sound")
            }
        }
        println(error)
    }
    
    func start_accepted(verseId:Int){
        // playButtonSound()
        
        let vc = WriteLineViewController(nibName: "WriteLineViewController", bundle:nil)
        vc.verseId = verseId
        vc.topic = topic
        navigationController?.pushViewController(vc, animated: false)
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
