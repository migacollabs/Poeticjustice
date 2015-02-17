//
//  NewVerseViewController.swift
//  PoeticJusticeApp
//
//  Created by Mat Mathews on 1/28/15.
//  Copyright (c) 2015 Miga Col.Labs. All rights reserved.
//

import UIKit
import iAd
import AVFoundation

class NewVerseViewController: UIViewController {
    
    @IBOutlet weak var verseTitle: UITextField!
    @IBOutlet weak var friendsOnly: UISwitch!
    @IBOutlet weak var topicButton: UIButton!
    @IBOutlet var startButton: UIButton!
    
    var verseId : Int?
    var isBusy : Bool = false
    var maxNumPlayers : Int = 2
    var audioPlayer : AVAudioPlayer?
    
    var iAdBanner: ADBannerView?
    
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
    
    override func viewWillAppear(animated: Bool) {
        
        var screen_height = UIScreen.mainScreen().bounds.height
        self.iAdBanner = self.appdelegate().iAdBanner
        //self.iAdBanner?.delegate = self
        self.iAdBanner?.frame = CGRectMake(0,screen_height-98, 0, 0)
        if let adb = self.iAdBanner{
            println("adding ad banner subview ")
            self.view.addSubview(adb)
        }
        
        isBusy = false
    }
    
    override func viewWillDisappear(animated: Bool){
//        self.iAdBanner?.delegate = nil
//        self.iAdBanner?.removeFromSuperview()
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
    
    func showAlert(title:String, message:String, controller_title:String){
        // TODO: this shows a warning "Presenting view controllers on detached view controllers is discouraged"
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: controller_title, style: UIAlertActionStyle.Default,handler: nil))
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    
    @IBAction func onStart(sender: AnyObject) {
        
        if let vt = self.verseTitle.text{
            var vtl = countElements(vt)
            if (vtl==0) {
                self.showAlert("Missing title", message: "Please enter a title for the verse", controller_title: "Ok")
                return
            }
        }
        
        if (!isBusy) {
            isBusy = true
         
            var params = Dictionary<String,AnyObject>()
            params["title"] = self.verseTitle.text
            params["max_participants"] = self.maxNumPlayers
            
            if self.friendsOnly.on {
                params["friends_only"] = "true"
            } else {
                params["friends_only"] = "false"
            }
            
            params["owner_id"] = NetOpers.sharedInstance.user.id
            params["next_index_user_ids"] = 0
            params["max_lines"]=self.maxNumPlayers * 4
            params["next_index_user_ids"]=0
            params["participant_count"]=1
            
            // need to make sure we allocate all user_ids slots
            var user_ids : String = String(NetOpers.sharedInstance.user.id)
            for i in 1...(self.maxNumPlayers-1) {
                user_ids = user_ids + ";-1"
            }
            
            params["user_ids"] = user_ids
            params["verse_category_topic_id"] = self.topic?.id
            
            println(params)
            
            NetOpers.sharedInstance.post(
                NetOpers.sharedInstance.appserver_hostname! + "/m/edit/Verse",
                params: params, {(data:NSData?, response:NSURLResponse?, error:NSError?) -> Void in
                    
                    if let httpResponse = response as? NSHTTPURLResponse {
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
                        } else {
                            self.isBusy = false
                        }
                        
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    }
                    
                    if (error != nil) {
                        if let e = error?.localizedDescription {
                            self.show_alert("Unable to start new verse", message: e, controller_title:"Ok")
                        } else {
                            self.show_alert("Network error", message: "Unable to start new verse", controller_title:"Ok")
                        }
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    }
                    
            })
            
        }
    
    }
    
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
        self.navigationController!.setViewControllers([self.navigationController!.viewControllers[0], vc], animated: true)
        
        isBusy = false
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    func appdelegate () -> AppDelegate{
        return UIApplication.sharedApplication().delegate as AppDelegate
    }
    
    func show_alert(title:String, message:String, controller_title:String){
        dispatch_async(dispatch_get_main_queue()) {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: controller_title, style: UIAlertActionStyle.Default,handler: nil))
            
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
}
