
//
//  ViewController.swift
//  PoeticJusticeApp
//
//  Created by Mat Mathews on 1/16/15.
//  Copyright (c) 2015 Miga Collabs. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var user_name: UITextField!
    @IBOutlet weak var email_address: UITextField!
    @IBOutlet var userLabel: UILabel!
    @IBOutlet var goButton: UIButton!
    
    private var loginTimerCount : Int = 0
    private var is_busy : Bool = false
    private var timer : NSTimer?
    private var audioPlayer : AVAudioPlayer?
    
    var progressContainer: UIView = UIView()
    var progressLoadingView: UIView = UIView()
    var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()

    let tapRec = UITapGestureRecognizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.userLabel.text = "Sign In"
        
        tapRec.addTarget(self, action: "tappedView")
        self.view.addGestureRecognizer(tapRec)
        
        if let s : String = NSUserDefaults.standardUserDefaults().objectForKey("emailAddress") as? String {
            email_address.text = s
        }
        
        if let s : String = NSUserDefaults.standardUserDefaults().objectForKey("userName") as? String {
            user_name.text = s
        }
        
        NetOpers.sharedInstance.loginHandler = self
        NetOpers.sharedInstance.alertHandler = self
        
        updateUserLabel()
    }
    
    override func viewWillAppear(animated: Bool) {
        self.goButton.titleLabel?.text = "Go!"
        updateUserLabel()
        is_busy = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        self.view.endEditing(true);
        return false;
    }
    
    func showActivityIndicator(uiView: UIView) {
        
        goButton.setTitle("", forState: UIControlState.Normal)
        
        progressContainer.frame = uiView.frame
        progressContainer.center = uiView.center
        progressContainer.backgroundColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.00)
        
        progressLoadingView.frame = CGRectMake(0, 0, 80, 80)
        progressLoadingView.center = uiView.center
        progressLoadingView.backgroundColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.00)
        progressLoadingView.clipsToBounds = true
        progressLoadingView.layer.cornerRadius = 10
        
        activityIndicator.frame = CGRectMake(0.0, 0.0, 40, 40);
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
        activityIndicator.center = CGPointMake(progressLoadingView.frame.size.width / 2, progressLoadingView.frame.size.height / 2);
        
        progressLoadingView.addSubview(activityIndicator)
        progressContainer.addSubview(progressLoadingView)
        uiView.addSubview(progressContainer)
        activityIndicator.startAnimating()
    }
    
    func hideActivityIndicator() {
        goButton.setTitle("Go!", forState: UIControlState.Normal)
        
        activityIndicator.stopAnimating()
        progressContainer.removeFromSuperview()
    }
    
    func updateUserLabel() {
        
        var user = NetOpers.sharedInstance.user
        if (user.is_logged_in()) {
            self.userLabel.text = "You are signed in as:"
            
            title = user.user_name
            self.navigationController?.navigationBar.topItem?.title = ""
        } else {
            self.userLabel.text = "Sign In"
            
            title = "Home"
            self.navigationController?.navigationBar.topItem?.title = ""
        }
    }
    
    @IBAction func loadLeaderboard(sender: AnyObject) {
        let vc = LeaderboardViewController(nibName: "LeaderboardViewController", bundle:nil)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func isValidEmail(testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
        let range = testStr.rangeOfString(emailRegEx, options:.RegularExpressionSearch)
        let result = range != nil ? true : false
        return result
    }
    
    func on_finished_login() {
        // TODO: possible error handling or clean up post netopers stuff?
        println("finished netopers login")
        
        timer = NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: Selector("verifyLogin"), userInfo: nil, repeats: true)
        loginTimerCount = 0
    }
    
    func verifyLogin() {
        println("verifying login on timer")
        if let t = timer {
            if (NetOpers.sharedInstance.user.is_logged_in()) {
                println("login verified, stopping timer")
                t.invalidate()
            } else {
                if loginTimerCount>8 {
                    println("server was probably down, unlocking the go button to try again")
                    is_busy = false
                    
                    t.invalidate()
                    
                    self.show_alert("Oops", message: "Looks like there was a network issue.  Please try again!", controller_title: "Ok")
                    
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    self.hideActivityIndicator()
                }
            }
        }
        loginTimerCount += 1
    }
    
    
    @IBAction func on_go(sender: AnyObject) {
        
        if (!is_busy) {
            is_busy = true
            
            self.showActivityIndicator(self.view)
            
            println("attempting login...")
            
            var myDict: NSDictionary?
            
            // use a optional let assignment thing to check for the existence of
            // the Config plist file.
            if let path = NSBundle.mainBundle().pathForResource("Config", ofType: "plist") {
                myDict = NSDictionary(contentsOfFile: path)
            }
            
            // i'm pretty sure this sets 'dict' to a pointer to
            // myDict if myDict isn't nil. This is supposed to work
            // because myDict is an optional
            if let dict = myDict {
                if let ah = dict["appserver_hostname"] as String?{
                    
                    // the println is better than NSLog
                    // the cool \(var) formatting handle almost everything
                    println("Connecting to \(ah)")
                    
                    var login_url = ah + "/login"
                    
                    var params = Dictionary<String,AnyObject>()
                    params["form.submitted"] = true
                    params["country_code"] = "USA"
                    params["device_token"] = UIDevice.currentDevice().identifierForVendor.UUIDString
                    params["device_type"] = UIDevice.currentDevice().modelName
                    
                    // verify email address
                    if let em = self.email_address.text{
                        params["login"] = em
                        
                        if (!isValidEmail(em)) {
                            self.show_alert("Invalid email address", message: "Please enter a valid email address", controller_title: "Ok")
                            
                            self.hideActivityIndicator()
                            self.updateUserLabel()
                            
                            is_busy = false
                            
                            return
                        }
                        
                        NSUserDefaults.standardUserDefaults().setObject(em, forKey: "emailAddress")
                    }
                    
                    // verify user name
                    if let un = self.user_name.text{
                        params["user_name"] = un
                        
                        var unl = countElements(un)
                        
                        if (unl>15 || unl==0) {
                            self.show_alert("Invalid user name", message: "User name must be between 1 and 15 characters long", controller_title: "Ok")
                            
                            self.hideActivityIndicator()
                            self.updateUserLabel()
                            
                            is_busy = false
                            
                            return
                        }
                        
                        NSUserDefaults.standardUserDefaults().setObject(un, forKey: "userName")
                    }
                    
                    NSUserDefaults.standardUserDefaults().synchronize()
                    
                    if let login_em = params["login"] as? String{
                        
                        println("Connecting as \(login_em)")
                        
                        NetOpers.sharedInstance.login(params, url: login_url, {() -> (Void) in
                            
                            // we are logged in
                            // this won't be called if we set the on_login as a callback
                            self.show_alert("Login", message: "Successfully logged in", controller_title: "Thanks!")
                            
                        })
                        
                    }else{
                        self.show_alert("Login", message: "Sorry, that email was not found.", controller_title: "Ok") // do no user email address msg
                    }
                }else{
                    () // do no app server error msg
                }
                
            }
            
        }
        
    }
    
    func on_email_notification() {
        is_busy = false
    }
    
    func on_login(){
        
        println("on_login called")
        // TODO: open up a clickable topics view
        NetOpers.sharedInstance.get_player_game_state( { (data:NSData?, response:NSURLResponse?, error:NSError?) -> Void in
            
            if let httpResponse = response as? NSHTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    
                    if data != nil {
                        
                        var e : NSError?
                        
                        if let jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(
                        data!, options: NSJSONReadingOptions.MutableContainers,
                        error: &e) as? NSDictionary{
                            
                            NetOpers.sharedInstance.game_state = GameState(gameData: jsonResult)
                                
                            dispatch_async(dispatch_get_main_queue(), {
                                self.on_start()
                            })
                        } else {
                            println("Unable to parse game-state data")
                            println(e)
                        }
                        
                    }
                    
                } else {
                    self.hideActivityIndicator()
                    self.show_alert("\(httpResponse.statusCode) Oops", message: "There was a problem loading the game.  Please try again.", controller_title:"Ok")
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                }
            }

        })
        
        println("on_login finished")
    }
    
    func playButtonSound(){
        var error:NSError?
        
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
    
    func on_start(){
        println("on_start called")
        
        self.hideActivityIndicator()
        
        //self.goButton.enabled = true
        //self.goButton.highlighted = false
        
        playButtonSound()
        
        // this should probably be the indicator the app is good to go
        tabBarController?.selectedIndex = 1
        
        self.updateUserLabel()
        
        is_busy = false
    }
    
    func show_alert(title:String, message:String, controller_title:String){
        dispatch_async(dispatch_get_main_queue()) {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: controller_title, style: UIAlertActionStyle.Default,handler: nil))
            
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    // MARK - present Version History storyboard
    
    @IBAction func show_version_history(){
        var sb = UIStoryboard(name: "VerseHistoryStoryboard", bundle: nil)
        var controller = sb.instantiateViewControllerWithIdentifier("VerseHistoryMasterViewController") as UIViewController
        //self.navigationController?.pushViewController(controller, animated: true)
        self.presentViewController(controller, animated: true, completion: nil)
    }

    @IBAction func onShowAvatars(sender: AnyObject) {
        var sb = UIStoryboard(name: "Main", bundle: nil)
        var controller = sb.instantiateViewControllerWithIdentifier("AvatarPicCollectionViewController") as UIViewController
        self.navigationController?.pushViewController(controller, animated: true)
    }

    @IBAction func onShowTestResultScreen(sender: AnyObject) {
        var sb = UIStoryboard(name: "VerseResultsScreenStoryboard", bundle: nil)
        var controller = sb.instantiateViewControllerWithIdentifier("VerseResultsScreenViewController") as VerseResultsScreenViewController
        controller.verseId = 6 // this is just for testing
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    
    // MARK: - gestures
    
    func tappedView(){
        self.user_name.resignFirstResponder()
        self.email_address.resignFirstResponder()
    }
    
}












